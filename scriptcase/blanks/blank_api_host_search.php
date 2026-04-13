<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$query = ra_escape($_GET['q'] ?? '');
$sql = "SELECT id, full_name, area_name, COALESCE(email, '') AS email, COALESCE(phone_number, '') AS phone_number
        FROM ra_hosts
        WHERE status = 'ACTIVE'";

if ($query !== '') {
    $sql .= " AND (
                full_name LIKE '%" . $query . "%'
             OR area_name LIKE '%" . $query . "%'
             OR email LIKE '%" . $query . "%'
             OR search_alias LIKE '%" . $query . "%'
             OR COALESCE(phone_number, '') LIKE '%" . $query . "%'
            )";
}

$sql .= " ORDER BY
            CASE WHEN COALESCE(email, '') <> '' THEN 0 ELSE 1 END ASC,
            full_name ASC
          LIMIT 80";
sc_select(rs_hosts, $sql);

$items = [];
if ({rs_hosts} !== false) {
    while (!{rs_hosts}->EOF) {
        $items[] = [
            'id' => (int) {rs_hosts}->fields[0],
            'full_name' => (string) {rs_hosts}->fields[1],
            'area_name' => (string) {rs_hosts}->fields[2],
            'email' => (string) {rs_hosts}->fields[3],
            'phone_number' => (string) {rs_hosts}->fields[4],
        ];
        {rs_hosts}->MoveNext();
    }
    {rs_hosts}->Close();
}

ra_json_response([
    'ok' => true,
    'data' => $items,
]);
