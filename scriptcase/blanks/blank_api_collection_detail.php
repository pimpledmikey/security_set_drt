<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');
$collectionId = (int) ($_GET['collection_id'] ?? 0);

if ($collectionId <= 0) {
    ra_json_response([
        'ok' => false,
        'message' => 'Debes indicar collection_id.',
    ], 422);
}

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_collection_detail_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_collection_detail_secret} !== false && !empty({rs_collection_detail_secret})) {
    $documentSecret = (string) {rs_collection_detail_secret[0][0]};
}

$sqlDetail = "SELECT
                c.id,
                COALESCE(c.requester_name_snapshot, '') AS requester_name,
                COALESCE(c.requester_email_snapshot, '') AS requester_email,
                COALESCE(c.requester_phone_snapshot, '') AS requester_phone,
                COALESCE(h.full_name, c.requester_name_snapshot) AS host_name,
                COALESCE(g.full_name, '') AS guard_handover_name,
                COALESCE(c.tracking_number, '') AS tracking_number,
                COALESCE(c.carrier_company, '') AS carrier_company,
                COALESCE(c.notes, '') AS notes,
                c.status,
                c.registered_at,
                COALESCE(c.delivered_at, '') AS delivered_at,
                COALESCE((
                    SELECT cn.delivery_status
                    FROM ra_collection_notifications cn
                    WHERE cn.collection_id = c.id
                    ORDER BY cn.id DESC
                    LIMIT 1
                ), '') AS notification_status,
                COALESCE((
                    SELECT cn.error_message
                    FROM ra_collection_notifications cn
                    WHERE cn.collection_id = c.id
                    ORDER BY cn.id DESC
                    LIMIT 1
                ), '') AS notification_message,
                COALESCE((
                    SELECT cn.sent_at
                    FROM ra_collection_notifications cn
                    WHERE cn.collection_id = c.id
                    ORDER BY cn.id DESC
                    LIMIT 1
                ), '') AS notification_sent_at
              FROM ra_collections c
              LEFT JOIN ra_hosts h ON h.id = c.host_id
              LEFT JOIN ra_guards g ON g.id = c.guard_handover_id
              WHERE c.id = " . $collectionId . "
              LIMIT 1";
sc_lookup(rs_collection_detail, $sqlDetail);

if ({rs_collection_detail} === false || empty({rs_collection_detail})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro la recoleccion.',
    ], 404);
}

$photos = [];
$sqlPhotos = "SELECT id, encrypted_blob, is_primary, sort_order
              FROM ra_collection_evidence
              WHERE collection_id = " . $collectionId . "
              ORDER BY sort_order ASC, id ASC";
sc_select(rs_collection_detail_photos, $sqlPhotos);
if ({rs_collection_detail_photos} !== false) {
    while (!{rs_collection_detail_photos}->EOF) {
        $photos[] = [
            'id' => (int) {rs_collection_detail_photos}->fields[0],
            'image_base64' => (string) ra_decrypt_document_image_reference(
                {rs_collection_detail_photos}->fields[1],
                $documentSecret
            ),
            'is_primary' => (int) {rs_collection_detail_photos}->fields[2] === 1,
            'sort_order' => (int) {rs_collection_detail_photos}->fields[3],
        ];
        {rs_collection_detail_photos}->MoveNext();
    }
    {rs_collection_detail_photos}->Close();
}

$delivery = null;
$deliveryMimeSelect = ra_table_has_column('ra_collection_delivery', 'mime_type')
    ? "COALESCE(mime_type, 'image/png')"
    : "'image/png'";
$deliveryNotesSelect = ra_table_has_column('ra_collection_delivery', 'delivery_notes')
    ? "COALESCE(delivery_notes, '')"
    : "''";
$sqlDelivery = "SELECT delivered_to_name, signature_encrypted_blob, " . $deliveryMimeSelect . " AS mime_type, "
                . $deliveryNotesSelect . " AS delivery_notes, delivered_at
                FROM ra_collection_delivery
                WHERE collection_id = " . $collectionId . "
                LIMIT 1";
sc_lookup(rs_collection_delivery, $sqlDelivery);
if ({rs_collection_delivery} !== false && !empty({rs_collection_delivery})) {
    $delivery = [
        'delivered_to_name' => (string) {rs_collection_delivery[0][0]},
        'signature_base64' => (string) ra_decrypt_document_image_reference(
            {rs_collection_delivery[0][1]},
            $documentSecret
        ),
        'mime_type' => (string) {rs_collection_delivery[0][2]},
        'delivery_notes' => (string) {rs_collection_delivery[0][3]},
        'delivered_at' => (string) {rs_collection_delivery[0][4]},
    ];
}

ra_json_response([
    'ok' => true,
    'data' => [
        'id' => (int) {rs_collection_detail[0][0]},
        'requester_name' => (string) {rs_collection_detail[0][1]},
        'requester_email' => (string) {rs_collection_detail[0][2]},
        'requester_phone' => (string) {rs_collection_detail[0][3]},
        'host_name' => (string) {rs_collection_detail[0][4]},
        'guard_handover_name' => (string) {rs_collection_detail[0][5]},
        'tracking_number' => (string) {rs_collection_detail[0][6]},
        'carrier_company' => (string) {rs_collection_detail[0][7]},
        'notes' => (string) {rs_collection_detail[0][8]},
        'status' => (string) {rs_collection_detail[0][9]},
        'registered_at' => (string) {rs_collection_detail[0][10]},
        'delivered_at' => (string) {rs_collection_detail[0][11]},
        'photos' => $photos,
        'delivery' => $delivery,
        'notification_status' => (string) {rs_collection_detail[0][12]},
        'notification_message' => (string) {rs_collection_detail[0][13]},
        'notification_sent_at' => (string) {rs_collection_detail[0][14]},
    ],
]);
