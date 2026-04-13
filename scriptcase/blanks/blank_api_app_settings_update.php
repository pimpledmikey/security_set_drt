<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();

$allowedSettings = [
    'package_email_enabled',
    'package_whatsapp_enabled',
    'collection_email_enabled',
    'collection_whatsapp_enabled',
    'visit_email_enabled',
    'visit_whatsapp_enabled',
];

$updates = [];
foreach ($allowedSettings as $settingKey) {
    if (!array_key_exists($settingKey, $input)) {
        continue;
    }

    $value = $input[$settingKey];
    $normalized = (
        $value === true ||
        $value === 1 ||
        $value === '1' ||
        strtolower(trim((string) $value)) === 'true'
    ) ? 'true' : 'false';

    $updates[$settingKey] = $normalized;
}

if (empty($updates)) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se enviaron ajustes validos.',
    ], 422);
}

sc_begin_trans();

try {
    foreach ($updates as $settingKey => $settingValue) {
        sc_exec_sql(
            "INSERT INTO ra_app_settings (setting_key, setting_value, created_at, updated_at)
             VALUES (
                '" . ra_escape($settingKey) . "',
                '" . ra_escape($settingValue) . "',
                '" . ra_now() . "',
                '" . ra_now() . "'
             )
             ON DUPLICATE KEY UPDATE
                setting_value = VALUES(setting_value),
                updated_at = VALUES(updated_at)"
        );
    }

    sc_commit_trans();
} catch (Exception $e) {
    sc_rollback_trans();
    ra_json_response([
        'ok' => false,
        'message' => $e->getMessage(),
    ], 500);
}

ra_json_response([
    'ok' => true,
    'data' => $updates,
]);
