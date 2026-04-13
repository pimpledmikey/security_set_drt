<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$items = [];

sc_lookup(rs_has_package_carriers_table, "SHOW TABLES LIKE 'ra_package_carriers'");
if ({rs_has_package_carriers_table} === false || empty({rs_has_package_carriers_table})) {
    ra_json_response([
        'ok' => true,
        'data' => [],
    ]);
}

$sql = "SELECT id, carrier_name
        FROM ra_package_carriers
        WHERE status = 'ACTIVE'
        ORDER BY sort_order ASC, carrier_name ASC";
sc_select(rs_package_carriers, $sql);

if ({rs_package_carriers} !== false) {
    while (!{rs_package_carriers}->EOF) {
        $items[] = [
            'id' => (int) {rs_package_carriers}->fields[0],
            'carrier_name' => (string) {rs_package_carriers}->fields[1],
        ];
        {rs_package_carriers}->MoveNext();
    }
    {rs_package_carriers}->Close();
}

ra_json_response([
    'ok' => true,
    'data' => $items,
]);
