<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();
$visitor = $input['visitor'] ?? [];
$hostId = (int) ($input['host_id'] ?? 0);
$hostNameManual = trim((string) ($input['host_name_manual'] ?? ''));
$hostPhoneManual = trim((string) ($input['host_phone_manual'] ?? ''));
$hostEmailManual = trim((string) ($input['host_email_manual'] ?? ''));
$purposeInput = trim((string) ($input['purpose'] ?? ''));
$hasAppointmentProvided = array_key_exists('has_appointment', $input) && $input['has_appointment'] !== null;

$guard = null;
$token = ra_get_bearer_token();
if ($token !== '') {
    $sqlGuard = "SELECT id, full_name, role_name
                 FROM ra_guards
                 WHERE status = 'ACTIVE'
                   AND SHA2(CONCAT(username, ':', password_hash), 256) = '" . ra_escape($token) . "'
                 LIMIT 1";
    sc_lookup(rs_checkin_guard, $sqlGuard);
    if ({rs_checkin_guard} !== false && !empty({rs_checkin_guard})) {
        $guard = [
            'id' => (int) {rs_checkin_guard[0][0]},
            'full_name' => (string) {rs_checkin_guard[0][1]},
            'role_name' => (string) {rs_checkin_guard[0][2]},
        ];
    }
}

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_checkin_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_checkin_secret} !== false && !empty({rs_checkin_secret})) {
    $documentSecret = (string) {rs_checkin_secret[0][0]};
}

if (
    empty($visitor['full_name']) ||
    ($hostId <= 0 && $hostNameManual === '') ||
    $purposeInput === '' ||
    !$hasAppointmentProvided
) {
    ra_json_response([
        'ok' => false,
        'message' => 'Nombre, anfitrion, motivo y cita son obligatorios.',
    ], 422);
}

$hostName = '';
$hostPhone = '';
$hostEmail = '';
if ($hostId > 0) {
    $sqlHost = "SELECT full_name, COALESCE(phone_number, '') AS phone_number, COALESCE(email, '') AS email
                FROM ra_hosts
                WHERE id = " . $hostId . "
                LIMIT 1";
    sc_lookup(rs_checkin_host, $sqlHost);
    if ({rs_checkin_host} === false || empty({rs_checkin_host})) {
        ra_json_response([
            'ok' => false,
            'message' => 'No se encontro el anfitrion seleccionado.',
        ], 422);
    }
    $hostName = trim((string) {rs_checkin_host[0][0]});
    $hostPhone = trim((string) {rs_checkin_host[0][1]});
    $hostEmail = trim((string) {rs_checkin_host[0][2]});
}

if ($hostName === '') {
    $hostName = $hostNameManual;
}
if ($hostPhone === '') {
    $hostPhone = $hostPhoneManual;
}
if ($hostEmail === '') {
    $hostEmail = $hostEmailManual;
}

sc_begin_trans();

try {
    $visitorData = [
        'full_name' => trim((string) ($visitor['full_name'] ?? '')),
        'identifier_type' => trim((string) ($visitor['identifier_type'] ?? ra_slug_identifier_type($visitor['identifier_value'] ?? ''))),
        'identifier_value' => trim((string) ($visitor['identifier_value'] ?? '')),
        'birth_date' => trim((string) ($visitor['birth_date'] ?? '')),
        'document_label' => trim((string) ($visitor['document_label'] ?? 'Documento')),
        'issuer' => trim((string) ($visitor['issuer'] ?? '')),
    ];

    $visitorId = 0;
    $sqlExistingVisitor = "SELECT id
                           FROM ra_visitors
                           WHERE full_name = '" . ra_escape($visitorData['full_name']) . "'
                             AND " . (
                                $visitorData['identifier_value'] !== ''
                                    ? "identifier_value = '" . ra_escape($visitorData['identifier_value']) . "'"
                                    : "(identifier_value = '' OR identifier_value IS NULL)"
                             ) . "
                           LIMIT 1";
    sc_lookup(rs_existing_visitor_checkin, $sqlExistingVisitor);

    if ({rs_existing_visitor_checkin} !== false && !empty({rs_existing_visitor_checkin})) {
        $visitorId = (int) {rs_existing_visitor_checkin[0][0]};
    } else {
        $insertVisitor = "INSERT INTO ra_visitors
            (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at)
            VALUES
            (
                '" . ra_escape($visitorData['full_name']) . "',
                '" . ra_escape($visitorData['identifier_type']) . "',
                '" . ra_escape($visitorData['identifier_value']) . "',
                " . ($visitorData['birth_date'] !== '' ? "'" . ra_escape($visitorData['birth_date']) . "'" : "NULL") . ",
                '" . ra_escape($visitorData['document_label']) . "',
                '" . ra_escape($visitorData['issuer']) . "',
                '" . ra_now() . "',
                '" . ra_now() . "',
                '" . ra_now() . "'
            )";
        sc_exec_sql($insertVisitor);

        $sqlLastVisitor = "SELECT id
                           FROM ra_visitors
                           WHERE full_name = '" . ra_escape($visitorData['full_name']) . "'
                             AND " . (
                                $visitorData['identifier_value'] !== ''
                                    ? "identifier_value = '" . ra_escape($visitorData['identifier_value']) . "'"
                                    : "(identifier_value = '' OR identifier_value IS NULL)"
                             ) . "
                           ORDER BY id DESC
                           LIMIT 1";
        sc_lookup(rs_last_visitor_checkin, $sqlLastVisitor);
        if ({rs_last_visitor_checkin} !== false && !empty({rs_last_visitor_checkin})) {
            $visitorId = (int) {rs_last_visitor_checkin[0][0]};
        }
    }

    if ($visitorId <= 0) {
        throw new Exception('No se pudo crear el visitante.');
    }
    $purpose = ra_escape($purposeInput);
    $observations = trim((string) ($input['observations'] ?? ''));
    $groupSize = (int) ($input['group_size'] ?? 1);
    if ($groupSize <= 0) {
        $groupSize = 1;
    }
    $hasAppointmentInput = $input['has_appointment'] ?? false;
    $hasAppointment = (
        $hasAppointmentInput === true ||
        $hasAppointmentInput === 1 ||
        $hasAppointmentInput === '1' ||
        strtolower((string) $hasAppointmentInput) === 'true' ||
        strtolower((string) $hasAppointmentInput) === 'si' ||
        strtolower((string) $hasAppointmentInput) === 'sí'
    ) ? 1 : 0;

    $insertVisit = "INSERT INTO ra_visit_events
        (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at)
        VALUES
        (
            " . $visitorId . ",
            " . ($hostId > 0 ? $hostId : "NULL") . ",
            '" . ra_escape($hostName) . "',
            " . ($hostPhone !== '' ? "'" . ra_escape($hostPhone) . "'" : "NULL") . ",
            " . ($guard !== null ? (int) $guard['id'] : "NULL") . ",
            '" . $purpose . "',
            " . ($observations !== '' ? "'" . ra_escape($observations) . "'" : "NULL") . ",
            " . $hasAppointment . ",
            " . $groupSize . ",
            '" . ra_now() . "',
            NULL,
            'INSIDE',
            'FLUTTER',
            '" . ra_now() . "',
            '" . ra_now() . "'
        )";
    sc_exec_sql($insertVisit);

    $sqlVisit = "SELECT id
                 FROM ra_visit_events
                 WHERE visitor_id = " . $visitorId . "
                 ORDER BY id DESC
                 LIMIT 1";
    sc_lookup(rs_last_visit, $sqlVisit);
    $visitEventId = (int) {rs_last_visit[0][0]};

    $documentImage = trim((string) ($input['document_image_ref'] ?? ''));
    $documentImageMimeType = trim((string) ($input['document_image_mime_type'] ?? 'image/jpeg'));
    if ($documentImage !== '') {
        $insertDocument = "INSERT INTO ra_visitor_documents
            (visitor_id, visit_event_id, encrypted_blob, mime_type, key_version, captured_at, created_at)
            VALUES
            (
                " . $visitorId . ",
                " . $visitEventId . ",
                '" . ra_escape(ra_encrypt_document_image($documentImage, $documentSecret)) . "',
                '" . ra_escape($documentImageMimeType !== '' ? $documentImageMimeType : 'image/jpeg') . "',
                'v1',
                '" . ra_now() . "',
                '" . ra_now() . "'
            )";
        sc_exec_sql($insertDocument);
    }

    $insertAlert = "INSERT INTO ra_internal_alerts
        (visit_event_id, alert_type, title, body_text, is_read, created_at)
        VALUES
        (
            " . $visitEventId . ",
            'NEW_CHECKIN',
            'Nuevo ingreso',
            '" . ra_escape($visitor['full_name'] . " ingreso al corporativo.") . "',
            0,
            '" . ra_now() . "'
        )";
    sc_exec_sql($insertAlert);

    sc_commit_trans();

    // --- Enviar respuesta al cliente ANTES de notificaciones ---
    ra_json_response_then_continue([
        'ok' => true,
        'data' => [
            'id' => $visitEventId,
            'full_name' => $visitor['full_name'],
            'host_name' => $hostName,
            'purpose' => $purposeInput,
            'has_appointment' => $hasAppointment === 1,
            'group_size' => $groupSize,
            'observations' => $observations,
            'entered_at' => ra_now(),
            'identifier_label' => $visitor['document_label'] ?? 'Documento',
        ],
    ]);

    // --- Notificaciones (el cliente ya recibio la respuesta) ---
    $companyName = 'Control Entradas DRT';
    $smtpServer = '';
    $smtpUser = '';
    $smtpPass = '';
    $smtpFrom = '';
    $smtpPort = '587';
    $smtpSecurity = 'T';
    $visitEmailEnabled = false;
    $visitWhatsappEnabled = false;
    $wasenderApiUrl = '';
    $wasenderApiKey = '';
    sc_lookup(
        rs_visit_checkin_settings,
        "SELECT setting_key, setting_value
         FROM ra_app_settings
         WHERE setting_key IN ('company_name', 'smtp_server', 'smtp_user', 'smtp_pass', 'smtp_from', 'smtp_port', 'smtp_security', 'visit_email_enabled', 'visit_whatsapp_enabled', 'wasender_api_url', 'wasender_api_key')"
    );
    if ({rs_visit_checkin_settings} !== false && !empty({rs_visit_checkin_settings})) {
        foreach ({rs_visit_checkin_settings} as $row) {
            $settingKey = (string) $row[0];
            $settingValue = (string) $row[1];
            if ($settingKey === 'company_name') {
                $companyName = $settingValue;
            } elseif ($settingKey === 'smtp_server') {
                $smtpServer = $settingValue;
            } elseif ($settingKey === 'smtp_user') {
                $smtpUser = $settingValue;
            } elseif ($settingKey === 'smtp_pass') {
                $smtpPass = $settingValue;
            } elseif ($settingKey === 'smtp_from') {
                $smtpFrom = $settingValue;
            } elseif ($settingKey === 'smtp_port') {
                $smtpPort = $settingValue;
            } elseif ($settingKey === 'smtp_security') {
                $smtpSecurity = $settingValue;
            } elseif ($settingKey === 'visit_email_enabled') {
                $visitEmailEnabled = in_array(strtolower(trim($settingValue)), ['1', 'true', 'yes', 'si', 'sí', 'on'], true);
            } elseif ($settingKey === 'visit_whatsapp_enabled') {
                $visitWhatsappEnabled = in_array(strtolower(trim($settingValue)), ['1', 'true', 'yes', 'si', 'sí', 'on'], true);
            } elseif ($settingKey === 'wasender_api_url') {
                $wasenderApiUrl = $settingValue;
            } elseif ($settingKey === 'wasender_api_key') {
                $wasenderApiKey = $settingValue;
            }
        }
    }

    $visitNotificationSent = false;
    if ($visitWhatsappEnabled && $hostPhone !== '') {
        $visitWhatsapp = ra_send_whatsapp_text(
            $hostPhone,
            ra_build_visit_whatsapp_message(
                $companyName,
                $hostName,
                (string) $visitor['full_name'],
                $purposeInput,
                $hasAppointment === 1,
                ra_now()
            ),
            $wasenderApiUrl,
            $wasenderApiKey
        );
        if (!empty($visitWhatsapp['ok'])) {
            $visitNotificationSent = true;
        } else {
            ra_audit_log('VISIT_WHATSAPP_ERROR', (string) ($visitWhatsapp['message'] ?? 'No se pudo enviar el WhatsApp de visita.'));
        }
    }

    if (
        !$visitNotificationSent &&
        $visitEmailEnabled &&
        ra_looks_like_email($hostEmail) &&
        trim($smtpServer) !== '' &&
        trim($smtpUser) !== '' &&
        trim($smtpPass) !== '' &&
        trim($smtpFrom) !== ''
    ) {
        $visitSubject = ra_build_visit_email_subject($companyName);
        $visitHtml = ra_build_visit_email_html(
            $companyName,
            $hostName,
            (string) $visitor['full_name'],
            $purposeInput,
            $hasAppointment === 1,
            ra_now()
        );

        sc_mail_send(
            $smtpServer,
            $smtpUser,
            $smtpPass,
            $smtpFrom,
            $hostEmail,
            $visitSubject,
            $visitHtml,
            'H',
            '',
            '',
            $smtpPort,
            $smtpSecurity
        );

        if (!{sc_mail_ok}) {
            ra_audit_log(
                'VISIT_EMAIL_ERROR',
                trim((string) {sc_mail_erro}) !== ''
                    ? (string) {sc_mail_erro}
                    : 'No se pudo enviar el correo de visita.'
            );
        }
    }

    exit;
} catch (Exception $e) {
    sc_rollback_trans();
    ra_audit_log('CHECKIN_ERROR', $e->getMessage());
    ra_json_response([
        'ok' => false,
        'message' => $e->getMessage(),
    ], 500);
}
