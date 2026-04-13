<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$pendingItems = [];
$deliveredItems = [];
$schemaMessage = '';

sc_lookup(rs_has_packages_table, "SHOW TABLES LIKE 'ra_packages'");
sc_lookup(rs_has_package_evidence_table, "SHOW TABLES LIKE 'ra_package_evidence'");

if (
    {rs_has_packages_table} === false ||
    empty({rs_has_packages_table}) ||
    {rs_has_package_evidence_table} === false ||
    empty({rs_has_package_evidence_table})
) {
    ra_json_response([
        'ok' => true,
        'data' => [
            'pending_items' => [],
            'delivered_today_items' => [],
            'counts' => [
                'pending_receipts' => 0,
                'pending_pieces' => 0,
                'delivered_receipts' => 0,
                'delivered_pieces' => 0,
            ],
            'message' => 'Falta crear o actualizar las tablas de paqueteria. Ejecuta runway_access_alter_v7.sql.',
        ],
    ]);
}

sc_lookup(rs_has_package_count_column, "SHOW COLUMNS FROM ra_packages LIKE 'package_count'");
sc_lookup(rs_has_guard_received_column, "SHOW COLUMNS FROM ra_packages LIKE 'guard_received_id'");
sc_lookup(rs_has_tracking_number_column, "SHOW COLUMNS FROM ra_packages LIKE 'tracking_number'");
sc_lookup(rs_has_recipient_phone_column, "SHOW COLUMNS FROM ra_packages LIKE 'recipient_phone_snapshot'");

if (
    {rs_has_package_count_column} === false ||
    empty({rs_has_package_count_column}) ||
    {rs_has_guard_received_column} === false ||
    empty({rs_has_guard_received_column}) ||
    {rs_has_tracking_number_column} === false ||
    empty({rs_has_tracking_number_column}) ||
    {rs_has_recipient_phone_column} === false ||
    empty({rs_has_recipient_phone_column})
) {
    ra_json_response([
        'ok' => true,
        'data' => [
            'pending_items' => [],
            'delivered_today_items' => [],
            'counts' => [
                'pending_receipts' => 0,
                'pending_pieces' => 0,
                'delivered_receipts' => 0,
                'delivered_pieces' => 0,
            ],
            'message' => 'La tabla ra_packages esta desactualizada. Ejecuta runway_access_alter_v7.sql y actualiza columnas de paquetes.',
        ],
    ]);
}

$sqlPending = "SELECT
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
                  p.delivered_at,
                  (SELECT COUNT(*) FROM ra_package_evidence pe WHERE pe.package_id = p.id) AS photo_count
              FROM ra_packages p
              LEFT JOIN ra_hosts h ON h.id = p.host_id
              LEFT JOIN ra_guards g ON g.id = p.guard_received_id
              WHERE p.status <> 'DELIVERED'
              ORDER BY p.received_at DESC";
sc_select(rs_pending_packages, $sqlPending);
if ({rs_pending_packages} !== false) {
    while (!{rs_pending_packages}->EOF) {
        $pendingItems[] = [
            'id' => (int) {rs_pending_packages}->fields[0],
            'recipient_name' => (string) {rs_pending_packages}->fields[1],
            'recipient_email' => (string) {rs_pending_packages}->fields[2],
            'recipient_phone' => (string) {rs_pending_packages}->fields[3],
            'host_name' => (string) {rs_pending_packages}->fields[4],
            'guard_received_name' => (string) {rs_pending_packages}->fields[5],
            'tracking_number' => (string) {rs_pending_packages}->fields[6],
            'carrier_company' => (string) {rs_pending_packages}->fields[7],
            'package_count' => (int) {rs_pending_packages}->fields[8],
            'notes' => (string) {rs_pending_packages}->fields[9],
            'status' => (string) {rs_pending_packages}->fields[10],
            'received_at' => (string) {rs_pending_packages}->fields[11],
            'notified_at' => (string) {rs_pending_packages}->fields[12],
            'delivered_at' => (string) {rs_pending_packages}->fields[13],
            'photo_count' => (int) {rs_pending_packages}->fields[14],
        ];
        {rs_pending_packages}->MoveNext();
    }
    {rs_pending_packages}->Close();
}

$sqlDelivered = "SELECT
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
                    p.delivered_at,
                    (SELECT COUNT(*) FROM ra_package_evidence pe WHERE pe.package_id = p.id) AS photo_count
                FROM ra_packages p
                LEFT JOIN ra_hosts h ON h.id = p.host_id
                LEFT JOIN ra_guards g ON g.id = p.guard_received_id
                WHERE p.status = 'DELIVERED'
                  AND DATE(p.delivered_at) = CURDATE()
                ORDER BY p.delivered_at DESC";
sc_select(rs_delivered_packages, $sqlDelivered);
if ({rs_delivered_packages} !== false) {
    while (!{rs_delivered_packages}->EOF) {
        $deliveredItems[] = [
            'id' => (int) {rs_delivered_packages}->fields[0],
            'recipient_name' => (string) {rs_delivered_packages}->fields[1],
            'recipient_email' => (string) {rs_delivered_packages}->fields[2],
            'recipient_phone' => (string) {rs_delivered_packages}->fields[3],
            'host_name' => (string) {rs_delivered_packages}->fields[4],
            'guard_received_name' => (string) {rs_delivered_packages}->fields[5],
            'tracking_number' => (string) {rs_delivered_packages}->fields[6],
            'carrier_company' => (string) {rs_delivered_packages}->fields[7],
            'package_count' => (int) {rs_delivered_packages}->fields[8],
            'notes' => (string) {rs_delivered_packages}->fields[9],
            'status' => (string) {rs_delivered_packages}->fields[10],
            'received_at' => (string) {rs_delivered_packages}->fields[11],
            'notified_at' => (string) {rs_delivered_packages}->fields[12],
            'delivered_at' => (string) {rs_delivered_packages}->fields[13],
            'photo_count' => (int) {rs_delivered_packages}->fields[14],
        ];
        {rs_delivered_packages}->MoveNext();
    }
    {rs_delivered_packages}->Close();
}

sc_lookup(rs_pending_counts, "SELECT COUNT(*), COALESCE(SUM(package_count), 0) FROM ra_packages WHERE status <> 'DELIVERED'");
sc_lookup(rs_delivered_counts, "SELECT COUNT(*), COALESCE(SUM(package_count), 0) FROM ra_packages WHERE status = 'DELIVERED' AND DATE(delivered_at) = CURDATE()");

ra_json_response([
    'ok' => true,
    'data' => [
        'pending_items' => $pendingItems,
        'delivered_today_items' => $deliveredItems,
        'counts' => [
            'pending_receipts' => (int) ({rs_pending_counts[0][0]} ?? 0),
            'pending_pieces' => (int) ({rs_pending_counts[0][1]} ?? 0),
            'delivered_receipts' => (int) ({rs_delivered_counts[0][0]} ?? 0),
            'delivered_pieces' => (int) ({rs_delivered_counts[0][1]} ?? 0),
        ],
    ],
]);
