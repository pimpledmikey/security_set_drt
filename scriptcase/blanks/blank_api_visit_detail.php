<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$visitId = (int) ($_GET['visit_id'] ?? 0);
if ($visitId <= 0) {
    ra_json_response([
        'ok' => false,
        'message' => 'Debes indicar visit_id.',
    ], 422);
}

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_detail_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_detail_secret} !== false && !empty({rs_detail_secret})) {
    $documentSecret = (string) {rs_detail_secret[0][0]};
}

$sql = "SELECT
            e.id,
            v.full_name,
            COALESCE(e.host_name_snapshot, h.full_name, 'Sin anfitrion') AS host_name,
            COALESCE(e.purpose, 'Visita general') AS purpose,
            e.has_appointment,
            COALESCE(e.group_size, 1) AS group_size,
            COALESCE(e.observations, '') AS observations,
            e.entered_at,
            COALESCE(v.document_label, 'Documento') AS identifier_label,
            COALESCE(v.identifier_value, '') AS identifier_value,
            COALESCE(DATE_FORMAT(v.birth_date, '%Y-%m-%d'), '') AS birth_date,
            COALESCE(v.issuer, '') AS issuer
        FROM ra_visit_events e
        INNER JOIN ra_visitors v ON v.id = e.visitor_id
        LEFT JOIN ra_hosts h ON h.id = e.host_id
        WHERE e.id = " . $visitId . "
        LIMIT 1";

sc_lookup(rs_visit_detail, $sql);

if ({rs_visit_detail} === false || empty({rs_visit_detail})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro la visita.',
    ], 404);
}

$documentImageBase64 = '';
$sqlDocument = "SELECT encrypted_blob
                FROM ra_visitor_documents
                WHERE visit_event_id = " . $visitId . "
                ORDER BY id DESC
                LIMIT 1";
sc_lookup(rs_visit_document, $sqlDocument);

if ({rs_visit_document} !== false && !empty({rs_visit_document})) {
    $documentImageBase64 = (string) ra_decrypt_document_image_reference(
        {rs_visit_document[0][0]},
        $documentSecret
    );
}

ra_json_response([
    'ok' => true,
    'data' => [
        'id' => (int) {rs_visit_detail[0][0]},
        'full_name' => (string) {rs_visit_detail[0][1]},
        'host_name' => (string) {rs_visit_detail[0][2]},
        'purpose' => (string) {rs_visit_detail[0][3]},
        'has_appointment' => (int) {rs_visit_detail[0][4]} === 1,
        'group_size' => (int) {rs_visit_detail[0][5]},
        'observations' => (string) {rs_visit_detail[0][6]},
        'entered_at' => (string) {rs_visit_detail[0][7]},
        'identifier_label' => (string) {rs_visit_detail[0][8]},
        'identifier_value' => (string) {rs_visit_detail[0][9]},
        'birth_date' => (string) {rs_visit_detail[0][10]},
        'issuer' => (string) {rs_visit_detail[0][11]},
        'document_image_base64' => $documentImageBase64,
    ],
]);
