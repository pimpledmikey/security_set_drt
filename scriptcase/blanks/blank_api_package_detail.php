<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$packageId = (int) ($_GET['package_id'] ?? 0);
if ($packageId <= 0) {
    ra_json_response([
        'ok' => false,
        'message' => 'Debes indicar package_id.',
    ], 422);
}

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_package_detail_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_package_detail_secret} !== false && !empty({rs_package_detail_secret})) {
    $documentSecret = (string) {rs_package_detail_secret[0][0]};
}

$sql = "SELECT
            p.id,
            p.recipient_name_snapshot,
            COALESCE(p.recipient_email_snapshot, '') AS recipient_email_snapshot,
            COALESCE(p.recipient_phone_snapshot, '') AS recipient_phone_snapshot,
            COALESCE(h.full_name, p.recipient_name_snapshot) AS host_name,
            COALESCE(g.full_name, '') AS guard_received_name,
            COALESCE(p.tracking_number, '') AS tracking_number,
            COALESCE(p.carrier_company, '') AS carrier_company,
            COALESCE(p.package_count, 1) AS package_count,
            COALESCE(p.notes, '') AS notes,
            p.status,
            p.received_at,
            p.notified_at,
            p.delivered_at
        FROM ra_packages p
        LEFT JOIN ra_hosts h ON h.id = p.host_id
        LEFT JOIN ra_guards g ON g.id = p.guard_received_id
        WHERE p.id = " . $packageId . "
        LIMIT 1";
sc_lookup(rs_package_detail, $sql);

if ({rs_package_detail} === false || empty({rs_package_detail})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro el paquete.',
    ], 404);
}

$photos = [];
$sqlPhotos = "SELECT id, encrypted_blob, is_primary, sort_order
              FROM ra_package_evidence
              WHERE package_id = " . $packageId . "
              ORDER BY sort_order ASC, id ASC";
sc_select(rs_package_photos, $sqlPhotos);
if ({rs_package_photos} !== false) {
    while (!{rs_package_photos}->EOF) {
        $photos[] = [
            'id' => (int) {rs_package_photos}->fields[0],
            'image_base64' => (string) ra_decrypt_document_image_reference(
                {rs_package_photos}->fields[1],
                $documentSecret
            ),
            'is_primary' => (int) {rs_package_photos}->fields[2] === 1,
            'sort_order' => (int) {rs_package_photos}->fields[3],
        ];
        {rs_package_photos}->MoveNext();
    }
    {rs_package_photos}->Close();
}

$delivery = null;
$deliveryMimeSelect = ra_table_has_column('ra_package_delivery', 'mime_type')
    ? "COALESCE(mime_type, 'image/png')"
    : "'image/png'";
$deliveryNotesSelect = ra_table_has_column('ra_package_delivery', 'delivery_notes')
    ? "COALESCE(delivery_notes, '')"
    : "''";
$sqlDelivery = "SELECT received_by_name, signature_encrypted_blob, " . $deliveryMimeSelect . " AS mime_type, "
                . $deliveryNotesSelect . " AS delivery_notes, delivered_at
                FROM ra_package_delivery
                WHERE package_id = " . $packageId . "
                LIMIT 1";
sc_lookup(rs_package_delivery_detail, $sqlDelivery);
if ({rs_package_delivery_detail} !== false && !empty({rs_package_delivery_detail})) {
    $delivery = [
        'received_by_name' => (string) {rs_package_delivery_detail[0][0]},
        'signature_base64' => (string) ra_decrypt_document_image_reference(
            {rs_package_delivery_detail[0][1]},
            $documentSecret
        ),
        'mime_type' => (string) {rs_package_delivery_detail[0][2]},
        'delivery_notes' => (string) {rs_package_delivery_detail[0][3]},
        'delivered_at' => (string) {rs_package_delivery_detail[0][4]},
    ];
}

$notificationStatus = '';
$notificationMessage = '';
$notificationSentAt = '';
$sqlNotification = "SELECT delivery_status, COALESCE(error_message, '') AS error_message, COALESCE(sent_at, '') AS sent_at
                    FROM ra_package_notifications
                    WHERE package_id = " . $packageId . "
                    ORDER BY id DESC
                    LIMIT 1";
sc_lookup(rs_package_notification_detail, $sqlNotification);
if ({rs_package_notification_detail} !== false && !empty({rs_package_notification_detail})) {
    $notificationStatus = (string) {rs_package_notification_detail[0][0]};
    $notificationMessage = (string) {rs_package_notification_detail[0][1]};
    $notificationSentAt = (string) {rs_package_notification_detail[0][2]};
}

ra_json_response([
    'ok' => true,
    'data' => [
        'id' => (int) {rs_package_detail[0][0]},
        'recipient_name' => (string) {rs_package_detail[0][1]},
        'recipient_email' => (string) {rs_package_detail[0][2]},
        'recipient_phone' => (string) {rs_package_detail[0][3]},
        'host_name' => (string) {rs_package_detail[0][4]},
        'guard_received_name' => (string) {rs_package_detail[0][5]},
        'tracking_number' => (string) {rs_package_detail[0][6]},
        'carrier_company' => (string) {rs_package_detail[0][7]},
        'package_count' => (int) {rs_package_detail[0][8]},
        'notes' => (string) {rs_package_detail[0][9]},
        'status' => (string) {rs_package_detail[0][10]},
        'received_at' => (string) {rs_package_detail[0][11]},
        'notified_at' => (string) {rs_package_detail[0][12]},
        'delivered_at' => (string) {rs_package_detail[0][13]},
        'photos' => $photos,
        'delivery' => $delivery,
        'notification_status' => $notificationStatus,
        'notification_message' => $notificationMessage,
        'notification_sent_at' => $notificationSentAt,
    ],
]);
