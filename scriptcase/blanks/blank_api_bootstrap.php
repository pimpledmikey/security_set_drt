<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('GET');

$settings = [
    'company_name' => 'Control Entradas DRT',
    'appointments_enabled' => 'false',
    'default_theme' => 'midnight',
    'package_email_enabled' => 'true',
    'package_whatsapp_enabled' => 'true',
    'collection_email_enabled' => 'true',
    'collection_whatsapp_enabled' => 'true',
    'visit_email_enabled' => 'true',
    'visit_whatsapp_enabled' => 'true',
];

$sql = "SELECT setting_key, setting_value
        FROM ra_app_settings
        WHERE setting_key IN ('company_name', 'appointments_enabled', 'default_theme', 'package_email_enabled', 'package_whatsapp_enabled', 'collection_email_enabled', 'collection_whatsapp_enabled', 'visit_email_enabled', 'visit_whatsapp_enabled')";
sc_lookup(rs_bootstrap_settings, $sql);

if ({rs_bootstrap_settings} !== false && !empty({rs_bootstrap_settings})) {
    foreach ({rs_bootstrap_settings} as $row) {
        $settings[(string) $row[0]] = (string) $row[1];
    }
}

ra_json_response([
    'ok' => true,
    'data' => [
        'company_name' => (string) $settings['company_name'],
        'appointments_enabled' => (string) $settings['appointments_enabled'] === 'true',
        'quick_purposes' => [
            'Visita general',
            'Entrega',
            'Reunion',
            'Servicio tecnico',
        ],
        'theme_default' => (string) $settings['default_theme'],
        'package_email_enabled' => (string) $settings['package_email_enabled'] === 'true',
        'package_whatsapp_enabled' => (string) $settings['package_whatsapp_enabled'] === 'true',
        'collection_email_enabled' => (string) $settings['collection_email_enabled'] === 'true',
        'collection_whatsapp_enabled' => (string) $settings['collection_whatsapp_enabled'] === 'true',
        'visit_email_enabled' => (string) $settings['visit_email_enabled'] === 'true',
        'visit_whatsapp_enabled' => (string) $settings['visit_whatsapp_enabled'] === 'true',
    ],
]);
