<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$pendingItems = [];
$deliveredItems = [];

sc_lookup(rs_has_collections_table, "SHOW TABLES LIKE 'ra_collections'");
sc_lookup(rs_has_collection_evidence_table, "SHOW TABLES LIKE 'ra_collection_evidence'");

if (
    {rs_has_collections_table} === false ||
    empty({rs_has_collections_table}) ||
    {rs_has_collection_evidence_table} === false ||
    empty({rs_has_collection_evidence_table})
) {
    ra_json_response([
        'ok' => true,
        'data' => [
            'pending_items' => [],
            'delivered_today_items' => [],
            'counts' => [
                'pending_receipts' => 0,
                'delivered_receipts' => 0,
            ],
            'message' => 'Falta crear o actualizar las tablas de recoleccion. Ejecuta runway_access_alter_v7.sql.',
        ],
    ]);
}

$sqlPending = "SELECT
                  c.id,
                  c.requester_name_snapshot,
                  COALESCE(c.requester_email_snapshot, '') AS requester_email_snapshot,
                  COALESCE(c.requester_phone_snapshot, '') AS requester_phone_snapshot,
                  COALESCE(h.full_name, c.requester_name_snapshot) AS host_name,
                  COALESCE(g.full_name, '') AS guard_handover_name,
                  COALESCE(c.tracking_number, '') AS tracking_number,
                  COALESCE(c.carrier_company, '') AS carrier_company,
                  COALESCE(c.notes, '') AS notes,
                  c.status,
                  c.registered_at,
                  c.delivered_at,
                  (SELECT COUNT(*) FROM ra_collection_evidence ce WHERE ce.collection_id = c.id) AS photo_count
              FROM ra_collections c
              LEFT JOIN ra_hosts h ON h.id = c.host_id
              LEFT JOIN ra_guards g ON g.id = c.guard_handover_id
              WHERE c.status <> 'DELIVERED'
              ORDER BY c.registered_at ASC";
sc_select(rs_pending_collections, $sqlPending);
if ({rs_pending_collections} !== false) {
    while (!{rs_pending_collections}->EOF) {
        $pendingItems[] = [
            'id' => (int) {rs_pending_collections}->fields[0],
            'requester_name' => (string) {rs_pending_collections}->fields[1],
            'requester_email' => (string) {rs_pending_collections}->fields[2],
            'requester_phone' => (string) {rs_pending_collections}->fields[3],
            'host_name' => (string) {rs_pending_collections}->fields[4],
            'guard_handover_name' => (string) {rs_pending_collections}->fields[5],
            'tracking_number' => (string) {rs_pending_collections}->fields[6],
            'carrier_company' => (string) {rs_pending_collections}->fields[7],
            'notes' => (string) {rs_pending_collections}->fields[8],
            'status' => (string) {rs_pending_collections}->fields[9],
            'registered_at' => (string) {rs_pending_collections}->fields[10],
            'delivered_at' => (string) {rs_pending_collections}->fields[11],
            'photo_count' => (int) {rs_pending_collections}->fields[12],
        ];
        {rs_pending_collections}->MoveNext();
    }
    {rs_pending_collections}->Close();
}

$sqlDelivered = "SELECT
                    c.id,
                    c.requester_name_snapshot,
                    COALESCE(c.requester_email_snapshot, '') AS requester_email_snapshot,
                    COALESCE(c.requester_phone_snapshot, '') AS requester_phone_snapshot,
                    COALESCE(h.full_name, c.requester_name_snapshot) AS host_name,
                    COALESCE(g.full_name, '') AS guard_handover_name,
                    COALESCE(c.tracking_number, '') AS tracking_number,
                    COALESCE(c.carrier_company, '') AS carrier_company,
                    COALESCE(c.notes, '') AS notes,
                    c.status,
                    c.registered_at,
                    c.delivered_at,
                    (SELECT COUNT(*) FROM ra_collection_evidence ce WHERE ce.collection_id = c.id) AS photo_count
                FROM ra_collections c
                LEFT JOIN ra_hosts h ON h.id = c.host_id
                LEFT JOIN ra_guards g ON g.id = c.guard_handover_id
                WHERE c.status = 'DELIVERED'
                  AND DATE(c.delivered_at) = CURDATE()
                ORDER BY c.delivered_at DESC";
sc_select(rs_delivered_collections, $sqlDelivered);
if ({rs_delivered_collections} !== false) {
    while (!{rs_delivered_collections}->EOF) {
        $deliveredItems[] = [
            'id' => (int) {rs_delivered_collections}->fields[0],
            'requester_name' => (string) {rs_delivered_collections}->fields[1],
            'requester_email' => (string) {rs_delivered_collections}->fields[2],
            'requester_phone' => (string) {rs_delivered_collections}->fields[3],
            'host_name' => (string) {rs_delivered_collections}->fields[4],
            'guard_handover_name' => (string) {rs_delivered_collections}->fields[5],
            'tracking_number' => (string) {rs_delivered_collections}->fields[6],
            'carrier_company' => (string) {rs_delivered_collections}->fields[7],
            'notes' => (string) {rs_delivered_collections}->fields[8],
            'status' => (string) {rs_delivered_collections}->fields[9],
            'registered_at' => (string) {rs_delivered_collections}->fields[10],
            'delivered_at' => (string) {rs_delivered_collections}->fields[11],
            'photo_count' => (int) {rs_delivered_collections}->fields[12],
        ];
        {rs_delivered_collections}->MoveNext();
    }
    {rs_delivered_collections}->Close();
}

sc_lookup(rs_pending_counts, "SELECT COUNT(*) FROM ra_collections WHERE status <> 'DELIVERED'");
sc_lookup(rs_delivered_counts, "SELECT COUNT(*) FROM ra_collections WHERE status = 'DELIVERED' AND DATE(delivered_at) = CURDATE()");

ra_json_response([
    'ok' => true,
    'data' => [
        'pending_items' => $pendingItems,
        'delivered_today_items' => $deliveredItems,
        'counts' => [
            'pending_receipts' => (int) ({rs_pending_counts[0][0]} ?? 0),
            'delivered_receipts' => (int) ({rs_delivered_counts[0][0]} ?? 0),
        ],
    ],
]);
