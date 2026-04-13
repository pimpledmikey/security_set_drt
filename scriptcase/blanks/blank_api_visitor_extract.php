<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();

$ocrText = trim((string) ($input['ocr_text'] ?? ''));
$imageBase64 = trim((string) ($input['image_base64'] ?? ''));
$mimeType = trim((string) ($input['mime_type'] ?? 'image/jpeg'));

if ($ocrText === '' && $imageBase64 === '') {
    ra_json_response([
        'ok' => false,
        'message' => 'Debes enviar OCR o imagen.',
    ], 422);
}

$settings = [
    'openai_api_key' => getenv('OPENAI_API_KEY') !== false ? getenv('OPENAI_API_KEY') : '',
    'openai_model_text' => 'gpt-5-mini',
    'openai_model_vision' => 'gpt-4o-mini',
];

$sqlSettings = "SELECT setting_key, setting_value
                FROM ra_app_settings
                WHERE setting_key IN ('openai_api_key', 'openai_model_text', 'openai_model_vision')";
sc_lookup(rs_extract_settings, $sqlSettings);
if ({rs_extract_settings} !== false && !empty({rs_extract_settings})) {
    foreach ({rs_extract_settings} as $row) {
        $settings[(string) $row[0]] = (string) $row[1];
    }
}

$result = ['ok' => false];
$textPayload = null;
if ($ocrText !== '') {
    $result = ra_openai_extract_from_text(
        $ocrText,
        (string) $settings['openai_api_key'],
        (string) $settings['openai_model_text']
    );
    if (!empty($result['ok']) && !empty($result['data'])) {
        $textPayload = ra_sanitize_extraction_payload($result['data'], $ocrText);
    }
}

if (
    $imageBase64 !== '' &&
    (
        (!$result['ok']) ||
        $textPayload === null ||
        empty($textPayload['full_name']) ||
        !ra_looks_like_person_name($textPayload['full_name'] ?? '') ||
        ((float) ($textPayload['confidence'] ?? 0) > 0 && (float) ($textPayload['confidence'] ?? 0) < 0.5)
    )
) {
    if ($imageBase64 !== '') {
        $result = ra_openai_extract_from_image(
            $imageBase64,
            $mimeType,
            (string) $settings['openai_api_key'],
            (string) $settings['openai_model_vision'],
            $ocrText
        );
    }
}

if (!$result['ok']) {
    ra_json_response([
        'ok' => false,
        'message' => $result['message'] ?? 'No se pudo interpretar el documento.',
    ], 502);
}

$payload = ra_sanitize_extraction_payload($result['data'], $ocrText);
if (
    $textPayload !== null &&
    !empty($textPayload['full_name']) &&
    ra_looks_like_person_name($textPayload['full_name']) &&
    (
        empty($payload['full_name']) ||
        !ra_looks_like_person_name($payload['full_name'])
    )
) {
    $payload = array_merge($payload, $textPayload);
}
$payload['host_candidates'] = [];

$fullNameQuery = trim((string) ($payload['full_name'] ?? ''));
if ($fullNameQuery !== '') {
    $sqlHosts = "SELECT id
                 FROM ra_hosts
                 WHERE status = 'ACTIVE'
                   AND (
                        full_name LIKE '%" . ra_escape($fullNameQuery) . "%'
                     OR search_alias LIKE '%" . ra_escape($fullNameQuery) . "%'
                   )
                 ORDER BY full_name ASC
                 LIMIT 5";
    sc_lookup(rs_extract_hosts, $sqlHosts);
    if ({rs_extract_hosts} !== false && !empty({rs_extract_hosts})) {
        foreach ({rs_extract_hosts} as $row) {
            $payload['host_candidates'][] = (int) $row[0];
        }
    }
}

$payload['raw_ocr_text'] = $ocrText;
$payload['document_image_mime_type'] = $mimeType;

ra_json_response([
    'ok' => true,
    'data' => $payload,
]);
