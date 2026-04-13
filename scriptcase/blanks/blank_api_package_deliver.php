<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();

$packageId = (int) ($input['package_id'] ?? 0);
$receivedByName = trim((string) ($input['received_by_name'] ?? ''));
$signatureBase64 = trim((string) ($input['signature_base64'] ?? ''));
$deliveryNotes = trim((string) ($input['delivery_notes'] ?? ''));

if ($packageId <= 0 || $receivedByName === '' || $signatureBase64 === '') {
    ra_json_response([
        'ok' => false,
        'message' => 'Paquete, nombre de quien recoge y firma son obligatorios.',
    ], 422);
}

if (!ra_notification_table_has_columns(
    'ra_package_delivery',
    ['package_id', 'received_by_name', 'signature_encrypted_blob', 'delivered_at']
)) {
    $missingColumns = ra_get_missing_table_columns(
        'ra_package_delivery',
        ['package_id', 'received_by_name', 'signature_encrypted_blob', 'delivered_at']
    );
    ra_json_response([
        'ok' => false,
        'message' => 'La tabla ra_package_delivery no tiene la estructura minima requerida. Faltan: '
            . implode(', ', $missingColumns) . '. Ejecuta runway_access_alter_v7.sql.',
    ], 500);
}

$deliveryHasMimeType = ra_table_has_column('ra_package_delivery', 'mime_type');
$deliveryHasNotes = ra_table_has_column('ra_package_delivery', 'delivery_notes');
$deliveryHasCreatedAt = ra_table_has_column('ra_package_delivery', 'created_at');

$sqlExisting = "SELECT status, COALESCE(delivered_at, '')
                FROM ra_packages
                WHERE id = " . $packageId . "
                LIMIT 1";
sc_lookup(rs_package_deliver_existing, $sqlExisting);
if ({rs_package_deliver_existing} === false || empty({rs_package_deliver_existing})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro el paquete.',
    ], 404);
}

if ((string) {rs_package_deliver_existing[0][0]} === 'DELIVERED') {
    ra_json_response([
        'ok' => true,
        'message' => 'Este paquete ya estaba entregado.',
        'data' => [
            'package_id' => $packageId,
            'delivered_at' => (string) {rs_package_deliver_existing[0][1]},
        ],
    ]);
}

$sqlExistingDelivery = "SELECT delivered_at
                        FROM ra_package_delivery
                        WHERE package_id = " . $packageId . "
                        LIMIT 1";
sc_lookup(rs_package_deliver_row, $sqlExistingDelivery);
if ({rs_package_deliver_row} !== false && !empty({rs_package_deliver_row})) {
    sc_exec_sql(
        "UPDATE ra_packages
         SET status = 'DELIVERED',
             delivered_at = COALESCE(delivered_at, '" . ra_escape((string) {rs_package_deliver_row[0][0]}) . "'),
             updated_at = '" . ra_now() . "'
         WHERE id = " . $packageId
    );

    ra_json_response([
        'ok' => true,
        'message' => 'Este paquete ya estaba entregado.',
        'data' => [
            'package_id' => $packageId,
            'delivered_at' => (string) {rs_package_deliver_row[0][0]},
        ],
    ]);
}

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_package_deliver_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_package_deliver_secret} !== false && !empty({rs_package_deliver_secret})) {
    $documentSecret = (string) {rs_package_deliver_secret[0][0]};
}

sc_begin_trans();

try {
    $deliveredAtNow = ra_now();
    $insertColumns = [
        'package_id',
        'received_by_name',
        'signature_encrypted_blob',
    ];
    $insertValues = [
        (string) $packageId,
        "'" . ra_escape($receivedByName) . "'",
        "'" . ra_escape(ra_encrypt_document_image($signatureBase64, $documentSecret)) . "'",
    ];

    if ($deliveryHasMimeType) {
        $insertColumns[] = 'mime_type';
        $insertValues[] = "'image/png'";
    }
    if ($deliveryHasNotes) {
        $insertColumns[] = 'delivery_notes';
        $insertValues[] = $deliveryNotes !== '' ? "'" . ra_escape($deliveryNotes) . "'" : "NULL";
    }

    $insertColumns[] = 'delivered_at';
    $insertValues[] = "'" . $deliveredAtNow . "'";

    if ($deliveryHasCreatedAt) {
        $insertColumns[] = 'created_at';
        $insertValues[] = "'" . $deliveredAtNow . "'";
    }

    $insertDelivery = "INSERT INTO ra_package_delivery
        (" . implode(', ', $insertColumns) . ")
        VALUES
        (" . implode(",\n            ", $insertValues) . ")";
    sc_exec_sql($insertDelivery);

    $updatePackage = "UPDATE ra_packages
                      SET status = 'DELIVERED',
                          delivered_at = '" . $deliveredAtNow . "',
                          updated_at = '" . ra_now() . "'
                      WHERE id = " . $packageId;
    sc_exec_sql($updatePackage);

    sc_commit_trans();
} catch (Exception $e) {
    sc_rollback_trans();
    ra_audit_log('PACKAGE_DELIVER_ERROR', $e->getMessage());
    ra_json_response([
        'ok' => false,
        'message' => $e->getMessage(),
    ], 500);
}

ra_json_response([
    'ok' => true,
    'message' => 'Paquete entregado correctamente.',
    'data' => [
        'package_id' => $packageId,
        'delivered_at' => isset($deliveredAtNow) ? $deliveredAtNow : ra_now(),
    ],
]);
