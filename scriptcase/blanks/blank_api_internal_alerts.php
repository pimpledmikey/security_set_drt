<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$sql = "SELECT id, alert_type, title, body_text, is_read, created_at
        FROM ra_internal_alerts
        ORDER BY created_at DESC
        LIMIT 50";
sc_select(rs_alerts, $sql);

$items = [];
if ({rs_alerts} !== false) {
    while (!{rs_alerts}->EOF) {
        $items[] = [
            'id' => (int) {rs_alerts}->fields[0],
            'alert_type' => (string) {rs_alerts}->fields[1],
            'title' => (string) {rs_alerts}->fields[2],
            'body_text' => (string) {rs_alerts}->fields[3],
            'is_read' => (int) {rs_alerts}->fields[4] === 1,
            'created_at' => (string) {rs_alerts}->fields[5],
        ];
        {rs_alerts}->MoveNext();
    }
    {rs_alerts}->Close();
}

ra_json_response([
    'ok' => true,
    'data' => $items,
]);
