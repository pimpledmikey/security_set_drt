<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();

$username = ra_escape($input['username'] ?? '');
$password = (string) ($input['password'] ?? '');

if ($username === '' || $password === '') {
    ra_json_response([
        'ok' => false,
        'message' => 'Usuario y contrasena son obligatorios.',
    ], 422);
}

$sql = "SELECT id, username, password_hash, full_name, role_name
        FROM ra_guards
        WHERE username = '" . $username . "'
          AND status = 'ACTIVE'
        LIMIT 1";
sc_lookup(rs_guard_login, $sql);

if ({rs_guard_login} === false || empty({rs_guard_login})) {
    ra_json_response([
        'ok' => false,
        'message' => 'Credenciales invalidas.',
    ], 401);
}

$guardId = (int) {rs_guard_login[0][0]};
$guardUsername = (string) {rs_guard_login[0][1]};
$passwordHash = (string) {rs_guard_login[0][2]};
$guardName = (string) {rs_guard_login[0][3]};
$roleName = (string) {rs_guard_login[0][4]};

if (!password_verify($password, $passwordHash)) {
    ra_json_response([
        'ok' => false,
        'message' => 'Credenciales invalidas.',
    ], 401);
}

$token = ra_build_guard_token($guardUsername, $passwordHash);
$update = "UPDATE ra_guards
           SET last_login_at = '" . ra_now() . "'
           WHERE id = " . $guardId;
sc_exec_sql($update);

$defaultTheme = 'midnight';
sc_lookup(
    rs_guard_theme,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'default_theme'
     LIMIT 1"
);
if ({rs_guard_theme} !== false && !empty({rs_guard_theme})) {
    $defaultTheme = (string) {rs_guard_theme[0][0]};
}

ra_json_response([
    'ok' => true,
    'data' => [
        'token' => $token,
        'guard_name' => $guardName,
        'role' => $roleName,
        'theme_default' => $defaultTheme,
    ],
]);
