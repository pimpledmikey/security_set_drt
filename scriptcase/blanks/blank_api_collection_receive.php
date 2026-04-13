<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();

$hostId = (int) ($input['host_id'] ?? 0);
$guardHandoverId = (int) ($input['guard_handover_id'] ?? 0);
$requesterNameManual = trim((string) ($input['requester_name_manual'] ?? ''));
$requesterEmailOverride = trim((string) ($input['requester_email_override'] ?? ''));
$requesterPhoneOverride = trim((string) ($input['requester_phone_override'] ?? ''));
$trackingNumber = trim((string) ($input['tracking_number'] ?? ''));
$carrierCompany = trim((string) ($input['carrier_company'] ?? ''));
$carrierNameManual = trim((string) ($input['carrier_name_manual'] ?? ''));
$notes = trim((string) ($input['notes'] ?? ''));
$photosInput = $input['photos'] ?? [];

$photos = [];
if (is_array($photosInput)) {
    foreach ($photosInput as $photoInput) {
        if (is_array($photoInput)) {
            $value = trim((string) ($photoInput['image_base64'] ?? ''));
        } else {
            $value = trim((string) $photoInput);
        }
        if ($value !== '') {
            $photos[] = $value;
        }
    }
}

$resolvedCarrierCompany = $carrierNameManual !== '' ? $carrierNameManual : $carrierCompany;

if (
    $guardHandoverId <= 0 ||
    $trackingNumber === '' ||
    ($hostId <= 0 && $requesterNameManual === '') ||
    empty($photos)
) {
    ra_json_response([
        'ok' => false,
        'message' => 'Solicitante, vigilante, numero de guia y al menos una foto son obligatorios.',
    ], 422);
}

sc_lookup(rs_has_collections_table, "SHOW TABLES LIKE 'ra_collections'");
sc_lookup(rs_has_collection_evidence_table, "SHOW TABLES LIKE 'ra_collection_evidence'");

if (
    {rs_has_collections_table} === false ||
    empty({rs_has_collections_table}) ||
    {rs_has_collection_evidence_table} === false ||
    empty({rs_has_collection_evidence_table})
) {
    ra_json_response([
        'ok' => false,
        'message' => 'Falta crear o actualizar las tablas de recoleccion. Ejecuta runway_access_alter_v7.sql.',
    ], 500);
}

$requesterName = '';
$requesterEmail = '';
$requesterPhone = '';

if ($hostId > 0) {
    $sqlHost = "SELECT full_name, COALESCE(email, '') AS email, COALESCE(phone_number, '') AS phone_number
                FROM ra_hosts
                WHERE id = " . $hostId . "
                LIMIT 1";
    sc_lookup(rs_collection_host, $sqlHost);

    if ({rs_collection_host} === false || empty({rs_collection_host})) {
        ra_json_response([
            'ok' => false,
            'message' => 'No se encontro el solicitante seleccionado.',
        ], 422);
    }

    $requesterName = trim((string) {rs_collection_host[0][0]});
    $requesterEmail = trim((string) {rs_collection_host[0][1]});
    $requesterPhone = trim((string) {rs_collection_host[0][2]});
}

if ($requesterName === '') {
    $requesterName = $requesterNameManual;
}
if ($requesterEmailOverride !== '') {
    $requesterEmail = $requesterEmailOverride;
}
if ($requesterPhoneOverride !== '') {
    $requesterPhone = $requesterPhoneOverride;
}

if ($requesterName === '') {
    ra_json_response([
        'ok' => false,
        'message' => 'Debes indicar quien solicita la recoleccion.',
    ], 422);
}

$sqlGuard = "SELECT full_name
             FROM ra_guards
             WHERE id = " . $guardHandoverId . "
               AND status = 'ACTIVE'
             LIMIT 1";
sc_lookup(rs_collection_guard, $sqlGuard);
if ({rs_collection_guard} === false || empty({rs_collection_guard})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro el vigilante seleccionado.',
    ], 422);
}

$guardHandoverName = trim((string) {rs_collection_guard[0][0]});

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_collection_receive_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_collection_receive_secret} !== false && !empty({rs_collection_receive_secret})) {
    $documentSecret = (string) {rs_collection_receive_secret[0][0]};
}

sc_begin_trans();

try {
    $insertCollection = "INSERT INTO ra_collections
        (host_id, guard_handover_id, requester_name_snapshot, requester_email_snapshot, requester_phone_snapshot, tracking_number, carrier_company, notes, status, registered_at, delivered_at, created_at, updated_at)
        VALUES
        (
            " . ($hostId > 0 ? $hostId : "NULL") . ",
            " . $guardHandoverId . ",
            '" . ra_escape($requesterName) . "',
            " . ($requesterEmail !== '' ? "'" . ra_escape($requesterEmail) . "'" : "NULL") . ",
            " . ($requesterPhone !== '' ? "'" . ra_escape($requesterPhone) . "'" : "NULL") . ",
            '" . ra_escape($trackingNumber) . "',
            " . ($resolvedCarrierCompany !== '' ? "'" . ra_escape($resolvedCarrierCompany) . "'" : "NULL") . ",
            " . ($notes !== '' ? "'" . ra_escape($notes) . "'" : "NULL") . ",
            'REGISTERED',
            '" . ra_now() . "',
            NULL,
            '" . ra_now() . "',
            '" . ra_now() . "'
        )";
    sc_exec_sql($insertCollection);

    $sqlLastCollection = "SELECT id
                          FROM ra_collections
                          WHERE requester_name_snapshot = '" . ra_escape($requesterName) . "'
                          ORDER BY id DESC
                          LIMIT 1";
    sc_lookup(rs_last_collection, $sqlLastCollection);
    $collectionId = (int) ({rs_last_collection[0][0]} ?? 0);

    if ($collectionId <= 0) {
        throw new Exception('No se pudo crear el registro de recoleccion.');
    }

    foreach ($photos as $index => $photoBase64) {
        $insertEvidence = "INSERT INTO ra_collection_evidence
            (collection_id, encrypted_blob, mime_type, key_version, is_primary, sort_order, captured_at, created_at)
            VALUES
            (
                " . $collectionId . ",
                '" . ra_escape(ra_encrypt_document_image($photoBase64, $documentSecret)) . "',
                'image/jpeg',
                'v1',
                " . ($index === 0 ? 1 : 0) . ",
                " . $index . ",
                '" . ra_now() . "',
                '" . ra_now() . "'
            )";
        sc_exec_sql($insertEvidence);
    }

    sc_commit_trans();
} catch (Exception $e) {
    sc_rollback_trans();
    ra_audit_log('COLLECTION_RECEIVE_ERROR', $e->getMessage());
    ra_json_response([
        'ok' => false,
        'message' => $e->getMessage(),
    ], 500);
}

ra_json_response([
    'ok' => true,
    'data' => [
        'collection' => [
            'id' => $collectionId,
            'requester_name' => $requesterName,
            'requester_email' => $requesterEmail,
            'requester_phone' => $requesterPhone,
            'host_name' => $requesterName,
            'guard_handover_name' => $guardHandoverName,
            'tracking_number' => $trackingNumber,
            'carrier_company' => $resolvedCarrierCompany,
            'notes' => $notes,
            'status' => 'REGISTERED',
            'registered_at' => ra_now(),
            'delivered_at' => '',
            'photo_count' => count($photos),
        ],
    ],
]);
