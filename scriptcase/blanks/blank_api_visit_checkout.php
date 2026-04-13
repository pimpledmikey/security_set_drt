<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();
$visitId = (int) ($input['visit_id'] ?? 0);

$guard = null;
$token = ra_get_bearer_token();
if ($token !== '') {
    $sqlGuard = "SELECT id, full_name, role_name
                 FROM ra_guards
                 WHERE status = 'ACTIVE'
                   AND SHA2(CONCAT(username, ':', password_hash), 256) = '" . ra_escape($token) . "'
                 LIMIT 1";
    sc_lookup(rs_checkout_guard, $sqlGuard);
    if ({rs_checkout_guard} !== false && !empty({rs_checkout_guard})) {
        $guard = [
            'id' => (int) {rs_checkout_guard[0][0]},
            'full_name' => (string) {rs_checkout_guard[0][1]},
            'role_name' => (string) {rs_checkout_guard[0][2]},
        ];
    }
}

if ($visitId <= 0) {
    ra_json_response([
        'ok' => false,
        'message' => 'visit_id es obligatorio.',
    ], 422);
}

$sql = "UPDATE ra_visit_events
        SET checked_out_at = '" . ra_now() . "',
            status = 'CHECKED_OUT',
            updated_at = '" . ra_now() . "'
        WHERE id = " . $visitId . "
          AND checked_out_at IS NULL";
sc_exec_sql($sql);

$alertSql = "INSERT INTO ra_internal_alerts
    (visit_event_id, alert_type, title, body_text, is_read, created_at)
    VALUES
    (
        " . $visitId . ",
        'CHECKOUT',
        'Salida registrada',
        'La salida fue registrada por " . ra_escape($guard !== null ? $guard['full_name'] : 'Guardia') . ".',
        0,
        '" . ra_now() . "'
    )";
sc_exec_sql($alertSql);

ra_json_response([
    'ok' => true,
    'data' => [
        'visit_id' => $visitId,
        'checked_out_at' => ra_now(),
    ],
]);
