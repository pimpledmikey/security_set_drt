<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$items = [];
$query = ra_escape($_GET['q'] ?? '');
$sql = "SELECT id, full_name, username
        FROM ra_guards
        WHERE status = 'ACTIVE'";

if ($query !== '') {
    $sql .= " AND (
                full_name LIKE '%" . $query . "%'
             OR username LIKE '%" . $query . "%'
            )";
}

$sql .= " ORDER BY full_name ASC LIMIT 80";
sc_select(rs_guards_active, $sql);

if ({rs_guards_active} !== false) {
    while (!{rs_guards_active}->EOF) {
        $items[] = [
            'id' => (int) {rs_guards_active}->fields[0],
            'full_name' => (string) {rs_guards_active}->fields[1],
            'username' => (string) {rs_guards_active}->fields[2],
        ];
        {rs_guards_active}->MoveNext();
    }
    {rs_guards_active}->Close();
}

ra_json_response([
    'ok' => true,
    'data' => $items,
]);
