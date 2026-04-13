<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

sc_lookup(rs_inside, "SELECT COUNT(*) FROM ra_visit_events WHERE checked_out_at IS NULL");
sc_lookup(rs_today, "SELECT COUNT(*) FROM ra_visit_events WHERE DATE(entered_at) = CURDATE()");
sc_lookup(rs_pending, "SELECT COUNT(*) FROM ra_internal_alerts WHERE is_read = 0");
sc_lookup(rs_last, "SELECT MAX(entered_at) FROM ra_visit_events");

ra_json_response([
    'ok' => true,
    'data' => [
        'inside_count' => (int) ({rs_inside[0][0]} ?? 0),
        'entries_today' => (int) ({rs_today[0][0]} ?? 0),
        'pending_alerts' => (int) ({rs_pending[0][0]} ?? 0),
        'last_entry_at' => (string) ({rs_last[0][0]} ?? ''),
    ],
]);
