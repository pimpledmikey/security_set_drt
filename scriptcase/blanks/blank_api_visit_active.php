<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$sql = "SELECT
            e.id,
            v.full_name,
            COALESCE(e.host_name_snapshot, h.full_name, 'Sin anfitrion') AS host_name,
            COALESCE(e.purpose, 'Visita general') AS purpose,
            e.has_appointment,
            COALESCE(e.group_size, 1) AS group_size,
            COALESCE(e.observations, '') AS observations,
            e.entered_at,
            COALESCE(v.document_label, 'Documento') AS identifier_label
        FROM ra_visit_events e
        INNER JOIN ra_visitors v ON v.id = e.visitor_id
        LEFT JOIN ra_hosts h ON h.id = e.host_id
        WHERE e.checked_out_at IS NULL
        ORDER BY e.entered_at DESC";

sc_select(rs_active_visits, $sql);
$items = [];
if ({rs_active_visits} !== false) {
    while (!{rs_active_visits}->EOF) {
        $items[] = [
            'id' => (int) {rs_active_visits}->fields[0],
            'full_name' => (string) {rs_active_visits}->fields[1],
            'host_name' => (string) {rs_active_visits}->fields[2],
            'purpose' => (string) {rs_active_visits}->fields[3],
            'has_appointment' => (int) {rs_active_visits}->fields[4] === 1,
            'group_size' => (int) {rs_active_visits}->fields[5],
            'observations' => (string) {rs_active_visits}->fields[6],
            'entered_at' => (string) {rs_active_visits}->fields[7],
            'identifier_label' => (string) {rs_active_visits}->fields[8],
        ];
        {rs_active_visits}->MoveNext();
    }
    {rs_active_visits}->Close();
}

ra_json_response([
    'ok' => true,
    'data' => $items,
]);
