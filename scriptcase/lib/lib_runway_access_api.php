<?php

function ra_read_json_request()
{
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function ra_json_response($payload, $status = 200)
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function ra_json_response_then_continue($payload, $status = 200)
{
    if (function_exists('session_write_close')) {
        @session_write_close();
    }

    $json = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $length = strlen($json);

    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Content-Length: ' . $length);
    header('Connection: close');

    while (ob_get_level() > 0) {
        @ob_end_flush();
    }

    echo $json;
    flush();

    if (function_exists('fastcgi_finish_request')) {
        fastcgi_finish_request();
    }

    if (function_exists('set_time_limit')) {
        @set_time_limit(30);
    }
}

function ra_require_method($method)
{
    if (strtoupper($_SERVER['REQUEST_METHOD']) !== strtoupper($method)) {
        ra_json_response([
            'ok' => false,
            'message' => 'Metodo no permitido.',
        ], 405);
    }
}

function ra_now()
{
    return date('Y-m-d H:i:s');
}

function ra_escape($value)
{
    return str_replace("'", "''", trim((string) $value));
}

function ra_setting($key, $default = '')
{
    $value = null;

    if (!empty($GLOBALS['ra_settings']) && is_array($GLOBALS['ra_settings']) && array_key_exists($key, $GLOBALS['ra_settings'])) {
        $value = $GLOBALS['ra_settings'][$key];
    } elseif (getenv($key) !== false) {
        $value = getenv($key);
    } elseif (getenv(strtoupper($key)) !== false) {
        $value = getenv(strtoupper($key));
    }

    if ($value === null || $value === '') {
        return $default;
    }

    return (string) $value;
}

function ra_setting_enabled($key, $default = false)
{
    $fallback = $default ? 'true' : 'false';
    $value = strtolower(trim(ra_setting($key, $fallback)));
    return in_array($value, ['1', 'true', 'yes', 'si', 'sí', 'on'], true);
}

function ra_get_bearer_token()
{
    $header = '';
    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $header = $_SERVER['HTTP_AUTHORIZATION'];
    } elseif (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $header = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }

    if (stripos($header, 'Bearer ') === 0) {
        return trim(substr($header, 7));
    }

    return '';
}

function ra_require_auth_token($guard = null)
{
    $guard = ra_optional_auth_token($guard);
    if ($guard !== null) {
        return $guard;
    }

    ra_json_response([
        'ok' => false,
        'message' => 'Sesion invalida.',
    ], 401);
}

function ra_optional_auth_token($guard = null)
{
    return is_array($guard) ? $guard : null;
}

function ra_build_guard_token($username, $passwordHash)
{
    return hash('sha256', (string) $username . ':' . (string) $passwordHash);
}

function ra_validate_identity_minimum($fullName, $identifierValue)
{
    return trim((string) $fullName) !== '';
}

function ra_normalize_spaces($value)
{
    return trim((string) preg_replace('/\s+/', ' ', (string) $value));
}

function ra_blocked_name_tokens()
{
    return [
        'ESTADOS',
        'UNIDOS',
        'MEXICANOS',
        'MEXICANA',
        'REPUBLICA',
        'NACIONAL',
        'GOBIERNO',
        'INSTITUTO',
        'SECRETARIA',
        'LICENCIA',
        'PASAPORTE',
        'PASSPORT',
        'DRIVER',
        'LICENSE',
        'CREDENCIAL',
        'CORPORATIVA',
        'GAFETE',
        'BADGE',
        'EMPLEADO',
        'EMPLOYEE',
        'DOMICILIO',
        'ADDRESS',
        'CURP',
        'RFC',
        'CLAVE',
        'VOTAR',
        'ELECTOR',
        'DOC',
        'DOCUMENTO',
        'IDCARD',
    ];
}

function ra_looks_like_email($value)
{
    $value = trim((string) $value);
    return $value !== '' && filter_var($value, FILTER_VALIDATE_EMAIL) !== false;
}

function ra_normalize_phone_for_whatsapp($value)
{
    $digits = preg_replace('/\D+/', '', (string) $value);
    $digits = ltrim((string) $digits);

    if ($digits === '') {
        return '';
    }

    if (strpos($digits, '00') === 0) {
        $digits = substr($digits, 2);
    }

    if (strpos($digits, '52') === 0 && strlen($digits) === 12) {
        return '+' . $digits;
    }

    if (strlen($digits) === 10) {
        return '+52' . $digits;
    }

    if (strlen($digits) >= 11 && strlen($digits) <= 15) {
        return '+' . $digits;
    }

    return '';
}

function ra_default_wasender_api_url()
{
    return 'https://www.wasenderapi.com/api/send-message';
}

function ra_notification_http_timeout_seconds()
{
    $timeout = (int) ra_setting('notification_http_timeout_seconds', '6');
    if ($timeout < 3) {
        return 3;
    }
    if ($timeout > 20) {
        return 20;
    }

    return $timeout;
}

function ra_current_origin()
{
    $isHttps = (
        (!empty($_SERVER['HTTPS']) && strtolower((string) $_SERVER['HTTPS']) !== 'off')
        || (string) ($_SERVER['SERVER_PORT'] ?? '') === '443'
    );

    $host = trim((string) ($_SERVER['HTTP_HOST'] ?? ''));
    if ($host === '') {
        return '';
    }

    return ($isHttps ? 'https://' : 'http://') . $host;
}

function ra_current_project_base_path()
{
    $scriptName = (string) ($_SERVER['SCRIPT_NAME'] ?? '');
    if (
        $scriptName !== ''
        && preg_match('#^(.*?/scriptcase/app/[^/]+)/[^/]+/[^/]+(?:\.php|\.htm)$#', $scriptName, $matches)
    ) {
        return (string) $matches[1];
    }

    return '';
}

function ra_build_blank_public_url($blankName, $params = [])
{
    $origin = ra_current_origin();
    $basePath = ra_current_project_base_path();
    $blankName = trim((string) $blankName);

    if ($origin === '' || $basePath === '' || $blankName === '') {
        return '';
    }

    $url = $origin . $basePath . '/' . $blankName . '/' . $blankName . '.php';
    $query = http_build_query((array) $params);
    if ($query !== '') {
        $url .= '?' . $query;
    }

    return $url;
}

function ra_build_media_signature($kind, $recordId, $expiresAt, $secret = '')
{
    $secret = $secret !== '' ? (string) $secret : ra_setting('document_encryption_key', 'CHANGE_THIS_TO_A_REAL_SECRET');
    $payload = trim((string) $kind) . '|' . (int) $recordId . '|' . (int) $expiresAt;
    return hash_hmac('sha256', $payload, $secret);
}

function ra_is_valid_media_signature($kind, $recordId, $expiresAt, $signature, $secret = '')
{
    $signature = trim((string) $signature);
    if ($signature === '' || (int) $expiresAt <= 0 || time() > (int) $expiresAt) {
        return false;
    }

    $expected = ra_build_media_signature($kind, $recordId, $expiresAt, $secret);
    return hash_equals($expected, $signature);
}

function ra_build_signed_media_public_url($kind, $recordId, $secret = '', $expiresAt = 0)
{
    $recordId = (int) $recordId;
    if ($recordId <= 0) {
        return '';
    }

    $expiresAt = (int) $expiresAt;
    if ($expiresAt <= 0) {
        $expiresAt = time() + 7200;
    }

    $signature = ra_build_media_signature($kind, $recordId, $expiresAt, $secret);
    return ra_build_blank_public_url('blank_api_media_public', [
        'kind' => (string) $kind,
        'id' => $recordId,
        'exp' => $expiresAt,
        'sig' => $signature,
    ]);
}

function ra_send_whatsapp_text($phoneNumber, $messageText, $apiUrl = '', $apiKey = '')
{
    $to = ra_normalize_phone_for_whatsapp($phoneNumber);
    $messageText = trim((string) $messageText);
    $apiUrl = trim((string) ($apiUrl !== '' ? $apiUrl : ra_setting('wasender_api_url', ra_default_wasender_api_url())));
    $apiKey = trim((string) ($apiKey !== '' ? $apiKey : ra_setting('wasender_api_key', '')));

    if ($to === '') {
        return [
            'ok' => false,
            'message' => 'No hay numero valido para WhatsApp.',
        ];
    }

    if ($apiUrl === '' || $apiKey === '') {
        return [
            'ok' => false,
            'message' => 'Falta configurar Wasender API.',
        ];
    }

    if ($messageText === '') {
        return [
            'ok' => false,
            'message' => 'El mensaje de WhatsApp esta vacio.',
        ];
    }

    $payload = json_encode([
        'to' => $to,
        'text' => $messageText,
    ]);

    $ch = curl_init($apiUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $apiKey,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
    curl_setopt($ch, CURLOPT_TIMEOUT, ra_notification_http_timeout_seconds());
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($response === false || $httpCode >= 400) {
        return [
            'ok' => false,
            'message' => $error !== '' ? $error : 'No se pudo enviar el WhatsApp.',
            'http_code' => $httpCode,
            'raw' => $response,
        ];
    }

    return [
        'ok' => true,
        'message' => 'WhatsApp enviado correctamente.',
        'http_code' => $httpCode,
        'raw' => $response,
    ];
}

function ra_send_whatsapp_image_url($phoneNumber, $messageText, $imageUrl, $apiUrl = '', $apiKey = '')
{
    $to = ra_normalize_phone_for_whatsapp($phoneNumber);
    $messageText = trim((string) $messageText);
    $imageUrl = trim((string) $imageUrl);
    $apiUrl = trim((string) ($apiUrl !== '' ? $apiUrl : ra_setting('wasender_api_url', ra_default_wasender_api_url())));
    $apiKey = trim((string) ($apiKey !== '' ? $apiKey : ra_setting('wasender_api_key', '')));

    if ($to === '') {
        return [
            'ok' => false,
            'message' => 'No hay numero valido para WhatsApp.',
        ];
    }

    if ($apiUrl === '' || $apiKey === '') {
        return [
            'ok' => false,
            'message' => 'Falta configurar Wasender API.',
        ];
    }

    if ($imageUrl === '') {
        return [
            'ok' => false,
            'message' => 'La URL publica de imagen para WhatsApp esta vacia.',
        ];
    }

    $payload = [
        'to' => $to,
        'imageUrl' => $imageUrl,
    ];
    if ($messageText !== '') {
        $payload['text'] = $messageText;
    }

    $ch = curl_init($apiUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $apiKey,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
    curl_setopt($ch, CURLOPT_TIMEOUT, ra_notification_http_timeout_seconds());
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($response === false || $httpCode >= 400) {
        return [
            'ok' => false,
            'message' => $error !== '' ? $error : 'No se pudo enviar el WhatsApp con imagen.',
            'http_code' => $httpCode,
            'raw' => $response,
        ];
    }

    return [
        'ok' => true,
        'message' => 'WhatsApp con imagen enviado correctamente.',
        'http_code' => $httpCode,
        'raw' => $response,
    ];
}

function ra_notification_table_has_columns($tableName, $columns)
{
    return empty(ra_get_missing_table_columns($tableName, $columns));
}

function ra_table_has_column($tableName, $columnName)
{
    $columnName = trim((string) $columnName);
    if ($columnName === '') {
        return false;
    }

    return empty(ra_get_missing_table_columns($tableName, [$columnName]));
}

function ra_get_missing_table_columns($tableName, $columns)
{
    $tableName = trim((string) $tableName);
    if ($tableName === '' || empty($columns)) {
        return (array) $columns;
    }

    sc_lookup(
        rs_notification_table_exists,
        "SHOW TABLES LIKE '" . ra_escape($tableName) . "'"
    );
    if ({rs_notification_table_exists} === false || empty({rs_notification_table_exists})) {
        return (array) $columns;
    }

    $missingColumns = [];
    foreach ((array) $columns as $columnName) {
        $columnName = trim((string) $columnName);
        if ($columnName === '') {
            continue;
        }

        sc_lookup(
            rs_notification_column_exists,
            "SHOW COLUMNS FROM " . $tableName . " LIKE '" . ra_escape($columnName) . "'"
        );
        if ({rs_notification_column_exists} === false || empty({rs_notification_column_exists})) {
            $missingColumns[] = $columnName;
        }
    }

    return $missingColumns;
}

function ra_resolve_wasender_upload_url($apiUrl = '')
{
    $apiUrl = trim((string) ($apiUrl !== '' ? $apiUrl : ra_setting('wasender_api_url', ra_default_wasender_api_url())));
    if ($apiUrl === '') {
        return 'https://www.wasenderapi.com/api/upload';
    }

    if (substr($apiUrl, -13) === '/send-message') {
        return substr($apiUrl, 0, -13) . '/upload';
    }

    return 'https://www.wasenderapi.com/api/upload';
}

function ra_upload_whatsapp_media($base64Image, $mimeType = 'image/jpeg', $apiUrl = '', $apiKey = '')
{
    $apiKey = trim((string) ($apiKey !== '' ? $apiKey : ra_setting('wasender_api_key', '')));
    $uploadUrl = ra_resolve_wasender_upload_url($apiUrl);
    $base64Image = trim((string) $base64Image);
    $mimeType = trim((string) $mimeType) !== '' ? trim((string) $mimeType) : 'image/jpeg';

    if ($apiKey === '') {
        return [
            'ok' => false,
            'message' => 'Falta configurar Wasender API.',
        ];
    }

    if ($base64Image === '') {
        return [
            'ok' => false,
            'message' => 'La imagen de WhatsApp esta vacia.',
        ];
    }

    $payload = json_encode([
        'file' => 'data:' . $mimeType . ';base64,' . $base64Image,
    ]);

    $ch = curl_init($uploadUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $apiKey,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($response === false || $httpCode >= 400) {
        return [
            'ok' => false,
            'message' => $error !== '' ? $error : 'No se pudo subir la imagen a Wasender.',
            'http_code' => $httpCode,
            'raw' => $response,
        ];
    }

    $decoded = json_decode((string) $response, true);
    $publicUrl = '';

    if (is_array($decoded)) {
        $publicUrl = trim((string) ($decoded['url'] ?? ''));
        if ($publicUrl === '' && !empty($decoded['data']) && is_array($decoded['data'])) {
            $publicUrl = trim((string) ($decoded['data']['url'] ?? ''));
            if ($publicUrl === '') {
                $publicUrl = trim((string) ($decoded['data']['publicUrl'] ?? ''));
            }
        }
        if ($publicUrl === '') {
            $publicUrl = trim((string) ($decoded['publicUrl'] ?? ''));
        }
    }

    if ($publicUrl === '') {
        return [
            'ok' => false,
            'message' => 'Wasender no devolvio una URL publica de imagen.',
            'http_code' => $httpCode,
            'raw' => $response,
        ];
    }

    return [
        'ok' => true,
        'message' => 'Imagen subida correctamente.',
        'public_url' => $publicUrl,
        'http_code' => $httpCode,
        'raw' => $response,
    ];
}

function ra_send_whatsapp_image($phoneNumber, $messageText, $base64Image, $mimeType = 'image/jpeg', $apiUrl = '', $apiKey = '')
{
    $to = ra_normalize_phone_for_whatsapp($phoneNumber);
    $messageText = trim((string) $messageText);
    $apiUrl = trim((string) ($apiUrl !== '' ? $apiUrl : ra_setting('wasender_api_url', ra_default_wasender_api_url())));
    $apiKey = trim((string) ($apiKey !== '' ? $apiKey : ra_setting('wasender_api_key', '')));

    if ($to === '') {
        return [
            'ok' => false,
            'message' => 'No hay numero valido para WhatsApp.',
        ];
    }

    if ($apiUrl === '' || $apiKey === '') {
        return [
            'ok' => false,
            'message' => 'Falta configurar Wasender API.',
        ];
    }

    $uploadResult = ra_upload_whatsapp_media($base64Image, $mimeType, $apiUrl, $apiKey);
    if (empty($uploadResult['ok'])) {
        return $uploadResult;
    }

    $sendResult = ra_send_whatsapp_image_url(
        $to,
        $messageText,
        (string) $uploadResult['public_url'],
        $apiUrl,
        $apiKey
    );
    $sendResult['upload'] = $uploadResult;

    return $sendResult;
}

function ra_is_institutional_name($value)
{
    $upper = strtoupper(ra_normalize_spaces($value));
    if ($upper === '') {
        return true;
    }

    $blockedPhrases = [
        'ESTADOS UNIDOS MEXICANOS',
        'REPUBLICA MEXICANA',
        'REPUBLICA DE MEXICO',
        'INSTITUTO NACIONAL',
        'SECRETARIA DE',
        'GOBIERNO DE',
        'DRIVER LICENSE',
        'UNITED STATES OF AMERICA',
        'PASSPORT CARD',
        'CREDENCIAL PARA VOTAR',
    ];

    foreach ($blockedPhrases as $phrase) {
        if (strpos($upper, $phrase) !== false) {
            return true;
        }
    }

    foreach (ra_blocked_name_tokens() as $token) {
        if (strpos($upper, $token) !== false) {
            return true;
        }
    }

    return false;
}

function ra_clean_name_candidate($value)
{
    $value = ra_normalize_spaces((string) $value);
    $value = preg_replace('/^(NOMBRE|NAME|APELLIDOS?|SURNAMES?)\s*:?\s*/iu', '', $value);
    $value = preg_replace('/[^[:alpha:][:space:]ÁÉÍÓÚÜÑáéíóúüñ]/u', ' ', (string) $value);
    return ra_normalize_spaces((string) $value);
}

function ra_looks_like_person_name($value)
{
    $value = ra_clean_name_candidate($value);
    if ($value === '' || preg_match('/\d/', $value)) {
        return false;
    }

    if (ra_is_institutional_name($value)) {
        return false;
    }

    $words = array_values(array_filter(preg_split('/\s+/', $value)));
    return count($words) >= 2 && count($words) <= 5;
}

function ra_looks_like_name_piece($value)
{
    $value = ra_clean_name_candidate($value);
    if ($value === '' || preg_match('/\d/', $value) || ra_is_institutional_name($value)) {
        return false;
    }

    $words = array_values(array_filter(preg_split('/\s+/', $value)));
    if (empty($words) || count($words) > 2) {
        return false;
    }

    foreach ($words as $word) {
        if (strlen($word) < 2 || strlen($word) > 18) {
            return false;
        }
    }

    return true;
}

function ra_compose_name_from_pieces($pieces)
{
    $pieces = array_values(array_filter(array_map('ra_clean_name_candidate', (array) $pieces)));
    if (count($pieces) === 3) {
        $firstWords = array_values(array_filter(preg_split('/\s+/', $pieces[0])));
        $secondWords = array_values(array_filter(preg_split('/\s+/', $pieces[1])));
        $thirdWords = array_values(array_filter(preg_split('/\s+/', $pieces[2])));

        if (count($firstWords) === 1 && count($secondWords) === 1 && count($thirdWords) >= 1) {
            return ra_clean_name_candidate($pieces[2] . ' ' . $pieces[0] . ' ' . $pieces[1]);
        }
    }

    return ra_clean_name_candidate(implode(' ', $pieces));
}

function ra_guess_full_name_from_ocr($ocrText)
{
    $lines = preg_split('/\r\n|\r|\n/', (string) $ocrText);
    $lines = array_values(array_filter(array_map('ra_normalize_spaces', $lines)));

    for ($i = 0; $i < count($lines); $i++) {
        $line = $lines[$i];
        if (preg_match('/^(NOMBRE|NAME|APELLIDOS?|SURNAMES?)\s*:?\s*(.*)$/iu', $line, $matches)) {
            $candidate = ra_clean_name_candidate($matches[2]);
            if ($candidate === '' && isset($lines[$i + 1])) {
                $candidate = ra_clean_name_candidate($lines[$i + 1]);
            }
            if ($candidate !== '' && isset($lines[$i + 1]) && ra_looks_like_person_name($candidate . ' ' . $lines[$i + 1])) {
                $candidate = ra_clean_name_candidate($candidate . ' ' . $lines[$i + 1]);
            }
            if (ra_looks_like_person_name($candidate)) {
                return $candidate;
            }
        }
    }

    $stackedBest = '';
    $stackedScore = -1;
    for ($i = 0; $i < count($lines); $i++) {
        $pieces = [];
        for ($j = $i; $j < count($lines) && $j < ($i + 4); $j++) {
            $piece = ra_clean_name_candidate($lines[$j]);
            if (!ra_looks_like_name_piece($piece)) {
                break;
            }

            $pieces[] = $piece;
            if (count($pieces) < 2) {
                continue;
            }

            $candidate = ra_compose_name_from_pieces($pieces);
            if (!ra_looks_like_person_name($candidate)) {
                continue;
            }

            $score = 0;
            $words = array_values(array_filter(preg_split('/\s+/', $candidate)));
            if (count($words) >= 3 && count($words) <= 4) {
                $score += 4;
            }
            if (count($pieces) >= 2) {
                $score += 2;
            }
            if (!preg_match('/\d/', $candidate)) {
                $score += 1;
            }

            if ($score > $stackedScore) {
                $stackedScore = $score;
                $stackedBest = $candidate;
            }
        }
    }

    if ($stackedBest !== '') {
        return $stackedBest;
    }

    $bestCandidate = '';
    $bestScore = -1;

    foreach ($lines as $rawLine) {
        $line = ra_clean_name_candidate($rawLine);
        if (!ra_looks_like_person_name($line)) {
            continue;
        }

        $score = 0;
        $words = array_values(array_filter(preg_split('/\s+/', $line)));
        if (count($words) >= 2 && count($words) <= 4) {
            $score += 3;
        }
        if (strlen($line) >= 10 && strlen($line) <= 42) {
            $score += 2;
        }
        if (preg_match('/\b(DE|DEL|LA|LAS|LOS)\b/u', $line)) {
            $score += 1;
        }
        if (!preg_match('/\d/', $line)) {
            $score += 1;
        }

        if ($score > $bestScore) {
            $bestScore = $score;
            $bestCandidate = $line;
        }
    }

    return $bestCandidate;
}

function ra_guess_identifier_from_ocr($ocrText)
{
    $keywordPatterns = [
        ['Licencia', '/(?:LICENCIA|LICENSE|DRIVER LICENSE|DL)[^A-Z0-9]{0,12}((?=[A-Z0-9-]*[0-9])[A-Z0-9-]{5,20})/u'],
        ['Credencial', '/(?:CREDENCIAL|CORPORATIVA|GAFETE|BADGE|EMPLEADO|EMPLOYEE)[^A-Z0-9]{0,12}((?=[A-Z0-9-]*[0-9])[A-Z0-9-]{4,20})/u'],
        ['Folio', '/(?:FOLIO|DOCUMENTO|DOC)[^A-Z0-9]{0,12}((?=[A-Z0-9-]*[0-9])[A-Z0-9-]{4,20})/u'],
    ];
    $patterns = [
        ['CURP', '/\b[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]\b/'],
        ['RFC', '/\b[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}\b/'],
        ['Pasaporte', '/\b(?=[A-Z0-9]*[0-9])[A-Z0-9]{6,12}\b/'],
        ['Folio', '/\b[0-9]{6,18}\b/'],
    ];

    $upperText = strtoupper((string) $ocrText);
    foreach ($keywordPatterns as $pattern) {
        if (preg_match($pattern[1], $upperText, $matches)) {
            return [
                'identifier_type' => $pattern[0],
                'identifier_value' => $matches[1],
            ];
        }
    }

    foreach ($patterns as $pattern) {
        if (preg_match($pattern[1], $upperText, $matches)) {
            return [
                'identifier_type' => $pattern[0],
                'identifier_value' => $matches[0],
            ];
        }
    }

    return [
        'identifier_type' => 'Otro',
        'identifier_value' => '',
    ];
}

function ra_guess_document_label_from_ocr($ocrText)
{
    $upperText = strtoupper((string) $ocrText);

    if (strpos($upperText, 'LICENCIA') !== false || strpos($upperText, 'DRIVER LICENSE') !== false) {
        return 'Licencia';
    }
    if (strpos($upperText, 'PASAPORTE') !== false || strpos($upperText, 'PASSPORT') !== false) {
        return 'Pasaporte';
    }
    if (
        strpos($upperText, 'CREDENCIAL') !== false ||
        strpos($upperText, 'CORPORATIVA') !== false ||
        strpos($upperText, 'GAFETE') !== false ||
        strpos($upperText, 'BADGE') !== false
    ) {
        return 'Credencial corporativa';
    }
    if (
        strpos($upperText, 'INE') !== false ||
        strpos($upperText, 'ELECTOR') !== false ||
        strpos($upperText, 'IDENTIFICACION') !== false
    ) {
        return 'Identificacion oficial';
    }

    return 'Identificacion capturada';
}

function ra_sanitize_extraction_payload($payload, $ocrText = '')
{
    $data = is_array($payload) ? $payload : [];
    $data = array_merge([
        'full_name' => '',
        'document_label' => 'Identificacion capturada',
        'identifier_type' => 'Otro',
        'identifier_value' => '',
        'birth_date' => '',
        'issuer' => '',
        'confidence' => 0,
        'requires_review' => true,
        'missing_fields' => [],
    ], $data);

    $data['full_name'] = ra_clean_name_candidate($data['full_name']);
    $data['document_label'] = ra_normalize_spaces($data['document_label']);
    $data['identifier_type'] = ra_normalize_spaces($data['identifier_type']);
    $data['identifier_value'] = ra_normalize_spaces($data['identifier_value']);
    $data['birth_date'] = ra_normalize_spaces($data['birth_date']);
    $data['issuer'] = ra_normalize_spaces($data['issuer']);
    $data['confidence'] = (float) $data['confidence'];

    if (($data['full_name'] === '' || !ra_looks_like_person_name($data['full_name'])) && trim((string) $ocrText) !== '') {
        $guessedName = ra_guess_full_name_from_ocr($ocrText);
        if ($guessedName !== '') {
            $data['full_name'] = $guessedName;
        }
    }

    if ($data['identifier_value'] === '' && trim((string) $ocrText) !== '') {
        $guessedIdentifier = ra_guess_identifier_from_ocr($ocrText);
        $data['identifier_value'] = $guessedIdentifier['identifier_value'];
        $data['identifier_type'] = $guessedIdentifier['identifier_type'];
    }

    if (
        trim((string) $ocrText) !== '' &&
        ($data['document_label'] === '' ||
            $data['document_label'] === 'Documento' ||
            $data['document_label'] === 'Documento capturado' ||
            $data['document_label'] === 'Identificacion')
    ) {
        $data['document_label'] = ra_guess_document_label_from_ocr($ocrText);
    }

    if ($data['identifier_value'] !== '' && ($data['identifier_type'] === '' || $data['identifier_type'] === 'Otro')) {
        $data['identifier_type'] = ra_slug_identifier_type($data['identifier_value']);
    }

    $missingFields = [];
    $hasValidName = $data['full_name'] !== '' && ra_looks_like_person_name($data['full_name']);
    if (!$hasValidName) {
        $missingFields[] = 'full_name';
        $data['full_name'] = '';
    }

    $data['missing_fields'] = $missingFields;
    $data['requires_review'] = !empty($missingFields) || ($hasValidName && $data['confidence'] > 0 && $data['confidence'] < 0.5);

    return $data;
}

function ra_slug_identifier_type($identifierValue)
{
    $value = strtoupper((string) $identifierValue);

    if (preg_match('/^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$/', $value)) {
        return 'CURP';
    }
    if (preg_match('/^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$/', $value)) {
        return 'RFC';
    }
    if (preg_match('/^[A-Z0-9]{6,12}$/', $value)) {
        return 'Folio';
    }
    return 'Otro';
}

function ra_encrypt_document_image($base64Image, $secret = '')
{
    $secret = $secret !== '' ? (string) $secret : ra_setting('document_encryption_key', 'CHANGE_THIS_TO_A_REAL_SECRET');
    $iv = random_bytes(16);
    $ciphertext = openssl_encrypt(
        $base64Image,
        'AES-256-CBC',
        hash('sha256', $secret, true),
        OPENSSL_RAW_DATA,
        $iv
    );

    return base64_encode(json_encode([
        'iv' => base64_encode($iv),
        'ciphertext' => base64_encode($ciphertext),
    ]));
}

function ra_decrypt_document_image_reference($encryptedBlob, $secret = '')
{
    $secret = $secret !== '' ? (string) $secret : ra_setting('document_encryption_key', 'CHANGE_THIS_TO_A_REAL_SECRET');
    $payload = json_decode(base64_decode($encryptedBlob), true);
    if (!is_array($payload) || empty($payload['iv']) || empty($payload['ciphertext'])) {
        return '';
    }

    return (string) openssl_decrypt(
        base64_decode($payload['ciphertext']),
        'AES-256-CBC',
        hash('sha256', $secret, true),
        OPENSSL_RAW_DATA,
        base64_decode($payload['iv'])
    );
}

function ra_build_host_candidates($fullName)
{
    return [];
}

function ra_openai_request($input, $apiKey = '', $model = '')
{
    $apiKey = $apiKey !== '' ? (string) $apiKey : ra_setting('openai_api_key', getenv('OPENAI_API_KEY'));
    $model = $model !== '' ? (string) $model : ra_setting('openai_model_text', 'gpt-5-mini');
    $url = 'https://api.openai.com/v1/responses';

    if (empty($apiKey)) {
        return [
            'ok' => false,
            'message' => 'No se configuro openai_api_key.',
        ];
    }

    $payload = [
        'model' => $model,
        'input' => $input,
        'text' => [
            'format' => [
                'type' => 'json_schema',
                'name' => 'visitor_extraction_result',
                'schema' => [
                    'type' => 'object',
                    'additionalProperties' => false,
                    'properties' => [
                        'full_name' => ['type' => 'string'],
                        'document_label' => ['type' => 'string'],
                        'identifier_type' => ['type' => 'string'],
                        'identifier_value' => ['type' => 'string'],
                        'birth_date' => ['type' => 'string'],
                        'issuer' => ['type' => 'string'],
                        'confidence' => ['type' => 'number'],
                        'requires_review' => ['type' => 'boolean'],
                        'missing_fields' => [
                            'type' => 'array',
                            'items' => ['type' => 'string'],
                        ],
                    ],
                    'required' => [
                        'full_name',
                        'document_label',
                        'identifier_type',
                        'identifier_value',
                        'birth_date',
                        'issuer',
                        'confidence',
                        'requires_review',
                        'missing_fields',
                    ],
                ],
            ],
        ],
    ];

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $apiKey,
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($response === false || $httpCode >= 400) {
        return [
            'ok' => false,
            'message' => $error !== '' ? $error : 'Fallo OpenAI.',
            'debug_http_code' => $httpCode,
        ];
    }

    $decoded = json_decode($response, true);
    $outputText = '';

    if (!empty($decoded['output']) && is_array($decoded['output'])) {
        foreach ($decoded['output'] as $outputItem) {
            if (($outputItem['type'] ?? '') !== 'message') {
                continue;
            }
            if (empty($outputItem['content']) || !is_array($outputItem['content'])) {
                continue;
            }

            foreach ($outputItem['content'] as $contentBlock) {
                if (($contentBlock['type'] ?? '') === 'output_text') {
                    $outputText .= (string) ($contentBlock['text'] ?? '');
                }
            }
        }
    }

    if ($outputText === '' && !empty($decoded['output_text']) && is_string($decoded['output_text'])) {
        $outputText = $decoded['output_text'];
    }

    $structured = json_decode($outputText, true);
    if (!is_array($structured)) {
        return [
            'ok' => false,
            'message' => 'La respuesta de OpenAI no regreso JSON valido.',
            'raw' => $decoded,
        ];
    }

    return [
        'ok' => true,
        'data' => $structured,
    ];
}

function ra_openai_extract_from_text($ocrText, $apiKey = '', $model = '')
{
    $prompt = "Extrae SOLO los datos del portador del documento para control de acceso.
Ignora paises, nombres de instituciones, encabezados, slogans, direcciones y texto decorativo.
Nunca devuelvas frases como 'Estados Unidos Mexicanos', 'Republica Mexicana', 'Secretaria de' o 'Instituto Nacional' como full_name.
Acepta licencias, pasaportes, identificaciones oficiales, credenciales corporativas, gafetes u otros documentos con nombre visible del portador.
full_name debe contener el nombre y apellidos de una persona fisica.
Si aparecen varios nombres, elige el del portador, no el del emisor ni el del funcionario.
Prioriza lineas cercanas a etiquetas como NOMBRE, NAME, APELLIDOS o SURNAMES si existen.
Si el OCR parte el nombre en varias lineas consecutivas, recomponlo como un solo nombre humano.
identifier_value es opcional; si existe y es legible, devuelvelo.
No marques requires_review=true solo porque falten birth_date o issuer.
Marca requires_review=true solo si el nombre completo del portador no es claro, parece institucional o esta incompleto.";

    return ra_openai_request([
        [
            'role' => 'system',
            'content' => [
                [
                    'type' => 'input_text',
                    'text' => $prompt,
                ],
            ],
        ],
        [
            'role' => 'user',
            'content' => [
                [
                    'type' => 'input_text',
                    'text' => "Texto OCR:\n" . trim((string) $ocrText),
                ],
            ],
        ],
    ], $apiKey, $model);
}

function ra_openai_extract_from_image($base64Image, $mimeType, $apiKey = '', $model = '', $ocrText = '')
{
    $prompt = "Analiza el documento y devuelve SOLO los datos de la persona portadora.
Nunca regreses como full_name encabezados institucionales, paises o emisores como 'Estados Unidos Mexicanos', 'Republica Mexicana', 'Passport', 'Driver License' o nombres de instituciones.
Acepta licencias, credenciales corporativas, gafetes, identificaciones internas y otros documentos con foto o nombre visible.
Si el documento no es estandar, usa identifier_type='Otro' y document_label libre.
Prioriza el nombre completo del portador; identifier_value es opcional si aparece legible.
Si se proporciona OCR preliminar, usalo solo como pista y confirma con la imagen.
No marques requires_review=true solo porque falten birth_date o issuer.
Si no puedes confirmar el nombre completo de una persona fisica, deja full_name vacio y marca requires_review=true.";

    if ($model === '') {
        $model = ra_setting('openai_model_vision', 'gpt-4o-mini');
    }

    $detail = trim((string) $ocrText) !== '' ? 'low' : 'high';
    $userContent = [
        [
            'type' => 'input_text',
            'text' => $prompt,
        ],
    ];

    if (trim((string) $ocrText) !== '') {
        $userContent[] = [
            'type' => 'input_text',
            'text' => "OCR preliminar (puede contener errores):\n" . trim((string) $ocrText),
        ];
    }

    $userContent[] = [
        'type' => 'input_image',
        'image_url' => 'data:' . $mimeType . ';base64,' . $base64Image,
        'detail' => $detail,
    ];

    return ra_openai_request([
        [
            'role' => 'system',
            'content' => [
                [
                    'type' => 'input_text',
                    'text' => $prompt,
                ],
            ],
        ],
        [
            'role' => 'user',
            'content' => $userContent,
        ],
    ], $apiKey, $model);
}

function ra_build_package_email_subject($companyName)
{
    $companyName = ra_normalize_spaces($companyName);
    if ($companyName === '') {
        $companyName = 'Control Entradas DRT';
    }
    return 'Tienes un paquete en recepcion - ' . $companyName;
}

function ra_build_package_email_html($companyName, $recipientName, $trackingNumber, $guardReceivedName, $receivedAt, $notes, $primaryPhotoBase64)
{
    $companyName = htmlspecialchars($companyName !== '' ? $companyName : 'Control Entradas DRT', ENT_QUOTES, 'UTF-8');
    $recipientName = htmlspecialchars($recipientName, ENT_QUOTES, 'UTF-8');
    $trackingNumber = htmlspecialchars($trackingNumber !== '' ? $trackingNumber : 'SIN CAPTURAR', ENT_QUOTES, 'UTF-8');
    $guardReceivedName = htmlspecialchars($guardReceivedName !== '' ? $guardReceivedName : 'Vigilancia', ENT_QUOTES, 'UTF-8');
    $receivedAt = htmlspecialchars($receivedAt, ENT_QUOTES, 'UTF-8');
    $notes = htmlspecialchars($notes !== '' ? $notes : 'Sin observaciones.', ENT_QUOTES, 'UTF-8');
    $photoHtml = '';

    if (trim((string) $primaryPhotoBase64) !== '') {
        $photoHtml = '<div style="margin-top:20px;text-align:center;">'
            . '<img src="data:image/jpeg;base64,' . $primaryPhotoBase64 . '" alt="Foto del paquete" '
            . 'style="max-width:100%;width:320px;border-radius:18px;border:1px solid #D9E2F2;display:inline-block;" />'
            . '</div>';
    }

    return '<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Paquete en recepcion</title>
</head>
<body style="margin:0;padding:0;background:#EEF3FA;font-family:Arial,sans-serif;color:#0B1426;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EEF3FA;padding:28px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#FFFFFF;border-radius:24px;overflow:hidden;border:1px solid #DCE6F5;">
          <tr>
            <td style="background:#0B1426;padding:24px 28px;color:#FFFFFF;">
              <div style="font-size:13px;letter-spacing:0.08em;text-transform:uppercase;color:#8DB3FF;">' . $companyName . '</div>
              <div style="font-size:28px;font-weight:700;line-height:1.2;margin-top:10px;">Tienes un paquete en recepcion</div>
              <div style="font-size:15px;line-height:1.5;color:#C7D6F0;margin-top:10px;">Hola ' . $recipientName . ', ya registramos un paquete a tu nombre en recepcion.</div>
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:separate;border-spacing:0 10px;">
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Numero de guia</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $trackingNumber . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Vigilante</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $guardReceivedName . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Hora de recepcion</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $receivedAt . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Observaciones</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $notes . '</td>
                </tr>
              </table>'
              . $photoHtml .
              '<div style="margin-top:22px;padding:16px 18px;background:#F6F9FF;border:1px solid #DCE6F5;border-radius:18px;font-size:14px;line-height:1.6;color:#37507A;">
                Cuando pases con guardias, te pediran confirmar la entrega y firmar de recibido.
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 24px;color:#6A7D9F;font-size:12px;line-height:1.5;">
              Este correo fue generado automaticamente por ' . $companyName . '.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>';
}

function ra_build_package_whatsapp_message($companyName, $recipientName, $trackingNumber, $carrierCompany, $guardReceivedName, $receivedAt, $notes)
{
    $companyName = ra_normalize_spaces($companyName !== '' ? $companyName : 'Control Entradas DRT');
    $recipientName = ra_normalize_spaces($recipientName !== '' ? $recipientName : 'Destinatario');
    $trackingNumber = ra_normalize_spaces($trackingNumber !== '' ? $trackingNumber : 'Sin capturar');
    $carrierCompany = ra_normalize_spaces($carrierCompany !== '' ? $carrierCompany : 'Sin paqueteria');
    $guardReceivedName = ra_normalize_spaces($guardReceivedName !== '' ? $guardReceivedName : 'Vigilancia');
    $receivedAt = ra_normalize_spaces($receivedAt);
    $notes = ra_normalize_spaces($notes !== '' ? $notes : 'Sin observaciones');

    return $companyName . "\n\n"
        . "Paquete registrado\n\n"
        . "Hola " . $recipientName . ".\n"
        . "Ya registramos un paquete a tu nombre en recepción.\n\n"
        . "Guía: " . $trackingNumber . "\n"
        . "Paquetería: " . $carrierCompany . "\n"
        . "Recibió: " . $guardReceivedName . "\n"
        . "Hora: " . $receivedAt . "\n"
        . "Observaciones: " . $notes . "\n\n"
        . "Pasa a recepción cuando desees recogerlo.";
}

function ra_build_visit_whatsapp_message($companyName, $hostName, $visitorName, $purpose, $hasAppointment, $enteredAt)
{
    $companyName = ra_normalize_spaces($companyName !== '' ? $companyName : 'Control Entradas DRT');
    $hostName = ra_normalize_spaces($hostName !== '' ? $hostName : 'Anfitrion');
    $visitorName = ra_normalize_spaces($visitorName !== '' ? $visitorName : 'Visitante');
    $purpose = ra_normalize_spaces($purpose !== '' ? $purpose : 'Visita general');
    $appointmentText = $hasAppointment ? 'Si' : 'No';
    $enteredAt = ra_normalize_spaces($enteredAt);

    return $companyName . "\n\n"
        . "Visita registrada\n\n"
        . "Hola " . $hostName . ".\n"
        . "Tu visita ya fue registrada en recepción.\n\n"
        . "Visitante: " . $visitorName . "\n"
        . "Motivo: " . $purpose . "\n"
        . "Cita: " . $appointmentText . "\n"
        . "Hora: " . $enteredAt;
}

function ra_build_visit_email_subject($companyName)
{
    $companyName = ra_normalize_spaces($companyName);
    if ($companyName === '') {
        $companyName = 'Control Entradas DRT';
    }
    return 'Visita registrada - ' . $companyName;
}

function ra_build_visit_email_html($companyName, $hostName, $visitorName, $purpose, $hasAppointment, $enteredAt)
{
    $companyName = htmlspecialchars($companyName !== '' ? $companyName : 'Control Entradas DRT', ENT_QUOTES, 'UTF-8');
    $hostName = htmlspecialchars($hostName !== '' ? $hostName : 'Anfitrion', ENT_QUOTES, 'UTF-8');
    $visitorName = htmlspecialchars($visitorName !== '' ? $visitorName : 'Visitante', ENT_QUOTES, 'UTF-8');
    $purpose = htmlspecialchars($purpose !== '' ? $purpose : 'Visita general', ENT_QUOTES, 'UTF-8');
    $appointmentText = $hasAppointment ? 'Sí' : 'No';
    $enteredAt = htmlspecialchars($enteredAt, ENT_QUOTES, 'UTF-8');

    return '<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Visita registrada</title>
</head>
<body style="margin:0;padding:0;background:#EEF3FA;font-family:Arial,sans-serif;color:#0B1426;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EEF3FA;padding:28px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#FFFFFF;border-radius:24px;overflow:hidden;border:1px solid #DCE6F5;">
          <tr>
            <td style="background:#0B1426;padding:24px 28px;color:#FFFFFF;">
              <div style="font-size:13px;letter-spacing:0.08em;text-transform:uppercase;color:#8DB3FF;">' . $companyName . '</div>
              <div style="font-size:28px;font-weight:700;line-height:1.2;margin-top:10px;">Visita registrada</div>
              <div style="font-size:15px;line-height:1.5;color:#C7D6F0;margin-top:10px;">Hola ' . $hostName . ', ya registramos una visita en recepción para ti.</div>
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:separate;border-spacing:0 10px;">
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Visitante</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $visitorName . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Motivo</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $purpose . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">¿Tiene cita?</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $appointmentText . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Hora de registro</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $enteredAt . '</td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 24px;color:#6A7D9F;font-size:12px;line-height:1.5;">
              Este correo fue generado automaticamente por ' . $companyName . '.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>';
}

function ra_build_collection_email_subject($companyName)
{
    $companyName = ra_normalize_spaces($companyName);
    if ($companyName === '') {
        $companyName = 'Control Entradas DRT';
    }
    return 'Tu recoleccion fue entregada - ' . $companyName;
}

function ra_build_collection_email_html($companyName, $requesterName, $trackingNumber, $carrierCompany, $guardName, $deliveredAt, $notes, $primaryPhotoBase64)
{
    $companyName = htmlspecialchars($companyName !== '' ? $companyName : 'Control Entradas DRT', ENT_QUOTES, 'UTF-8');
    $requesterName = htmlspecialchars($requesterName, ENT_QUOTES, 'UTF-8');
    $trackingNumber = htmlspecialchars($trackingNumber !== '' ? $trackingNumber : 'SIN CAPTURAR', ENT_QUOTES, 'UTF-8');
    $carrierCompany = htmlspecialchars($carrierCompany !== '' ? $carrierCompany : 'SIN PAQUETERIA', ENT_QUOTES, 'UTF-8');
    $guardName = htmlspecialchars($guardName !== '' ? $guardName : 'VIGILANCIA', ENT_QUOTES, 'UTF-8');
    $deliveredAt = htmlspecialchars($deliveredAt, ENT_QUOTES, 'UTF-8');
    $notes = htmlspecialchars($notes !== '' ? $notes : 'Sin observaciones.', ENT_QUOTES, 'UTF-8');
    $photoHtml = '';

    if (trim((string) $primaryPhotoBase64) !== '') {
        $photoHtml = '<div style="margin-top:20px;text-align:center;">'
            . '<img src="data:image/jpeg;base64,' . $primaryPhotoBase64 . '" alt="Foto de la recoleccion" '
            . 'style="max-width:100%;width:320px;border-radius:18px;border:1px solid #D9E2F2;display:inline-block;" />'
            . '</div>';
    }

    return '<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Recoleccion entregada</title>
</head>
<body style="margin:0;padding:0;background:#EEF3FA;font-family:Arial,sans-serif;color:#0B1426;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EEF3FA;padding:28px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#FFFFFF;border-radius:24px;overflow:hidden;border:1px solid #DCE6F5;">
          <tr>
            <td style="background:#0B1426;padding:24px 28px;color:#FFFFFF;">
              <div style="font-size:13px;letter-spacing:0.08em;text-transform:uppercase;color:#8DB3FF;">' . $companyName . '</div>
              <div style="font-size:28px;font-weight:700;line-height:1.2;margin-top:10px;">Tu recoleccion fue entregada</div>
              <div style="font-size:15px;line-height:1.5;color:#C7D6F0;margin-top:10px;">Hola ' . $requesterName . ', el paquete o documento de tu solicitud de recoleccion ya se entrego a la paqueteria.</div>
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:separate;border-spacing:0 10px;">
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Numero de guia</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $trackingNumber . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Paqueteria</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $carrierCompany . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Entrego</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $guardName . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Hora de entrega</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $deliveredAt . '</td>
                </tr>
                <tr>
                  <td style="font-size:13px;color:#5A6C8F;">Observaciones</td>
                  <td style="font-size:15px;font-weight:700;color:#0B1426;" align="right">' . $notes . '</td>
                </tr>
              </table>'
              . $photoHtml .
            '</td>
          </tr>
          <tr>
            <td style="padding:0 28px 24px;color:#6A7D9F;font-size:12px;line-height:1.5;">
              Este correo fue generado automaticamente por ' . $companyName . '.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>';
}

function ra_build_collection_whatsapp_message($companyName, $requesterName, $trackingNumber, $carrierCompany, $guardName, $deliveredAt, $notes)
{
    $companyName = ra_normalize_spaces($companyName !== '' ? $companyName : 'Control Entradas DRT');
    $requesterName = ra_normalize_spaces($requesterName !== '' ? $requesterName : 'Solicitante');
    $trackingNumber = ra_normalize_spaces($trackingNumber !== '' ? $trackingNumber : 'Sin capturar');
    $carrierCompany = ra_normalize_spaces($carrierCompany !== '' ? $carrierCompany : 'Sin paqueteria');
    $guardName = ra_normalize_spaces($guardName !== '' ? $guardName : 'Vigilancia');
    $deliveredAt = ra_normalize_spaces($deliveredAt);
    $notes = ra_normalize_spaces($notes !== '' ? $notes : 'Sin observaciones');

    return $companyName . "\n\n"
        . "Recolección entregada\n\n"
        . "Hola " . $requesterName . ".\n"
        . "Tu solicitud ya fue entregada al recolector o paquetería.\n\n"
        . "Guía: " . $trackingNumber . "\n"
        . "Recolector: " . $carrierCompany . "\n"
        . "Entregó: " . $guardName . "\n"
        . "Hora: " . $deliveredAt . "\n"
        . "Observaciones: " . $notes;
}

function ra_find_or_create_visitor($visitor)
{
    throw new RuntimeException('La persistencia del visitante debe ejecutarse dentro del Blank de Scriptcase.');
}

function ra_audit_log($eventType, $message)
{
    error_log('[RUNWAY_ACCESS][' . $eventType . '] ' . $message);
}
