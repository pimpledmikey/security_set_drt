<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$kind = trim((string) ($_GET['kind'] ?? ''));
$recordId = (int) ($_GET['id'] ?? 0);
$expiresAt = (int) ($_GET['exp'] ?? 0);
$signature = trim((string) ($_GET['sig'] ?? ''));

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_media_public_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_media_public_secret} !== false && !empty({rs_media_public_secret})) {
    $documentSecret = (string) {rs_media_public_secret[0][0]};
}

if (
    $kind === ''
    || $recordId <= 0
    || $expiresAt <= 0
    || !ra_is_valid_media_signature($kind, $recordId, $expiresAt, $signature, $documentSecret)
) {
    http_response_code(403);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Acceso denegado.';
    exit;
}

$sqlMedia = '';
if ($kind === 'package') {
    $sqlMedia = "SELECT encrypted_blob, COALESCE(mime_type, 'image/jpeg')
                 FROM ra_package_evidence
                 WHERE package_id = " . $recordId . "
                 ORDER BY is_primary DESC, sort_order ASC, id ASC
                 LIMIT 1";
} elseif ($kind === 'collection') {
    $sqlMedia = "SELECT encrypted_blob, COALESCE(mime_type, 'image/jpeg')
                 FROM ra_collection_evidence
                 WHERE collection_id = " . $recordId . "
                 ORDER BY is_primary DESC, sort_order ASC, id ASC
                 LIMIT 1";
} else {
    http_response_code(422);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Tipo de evidencia no soportado.';
    exit;
}

sc_lookup(rs_media_public_file, $sqlMedia);
if ({rs_media_public_file} === false || empty({rs_media_public_file})) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'No se encontró la evidencia.';
    exit;
}

$mimeType = (string) {rs_media_public_file[0][1]};
$base64Image = (string) ra_decrypt_document_image_reference(
    {rs_media_public_file[0][0]},
    $documentSecret
);

if ($base64Image === '') {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'No se pudo leer la evidencia.';
    exit;
}

$binaryImage = base64_decode($base64Image, true);
if ($binaryImage === false) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'La evidencia no tiene un formato válido.';
    exit;
}

header('Content-Type: ' . ($mimeType !== '' ? $mimeType : 'image/jpeg'));
header('Content-Length: ' . strlen($binaryImage));
header('Cache-Control: public, max-age=300');
header('Content-Disposition: inline; filename="evidencia.jpg"');
echo $binaryImage;
exit;
