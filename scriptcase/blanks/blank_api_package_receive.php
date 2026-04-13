<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();

$hostId = (int) ($input['host_id'] ?? 0);
$guardReceivedId = (int) ($input['guard_received_id'] ?? 0);
$recipientNameManual = trim((string) ($input['recipient_name_manual'] ?? ''));
$recipientEmailOverride = trim((string) ($input['recipient_email_override'] ?? ''));
$recipientPhoneOverride = trim((string) ($input['recipient_phone_override'] ?? ''));
$trackingNumber = trim((string) ($input['tracking_number'] ?? ''));
$carrierCompany = trim((string) ($input['carrier_company'] ?? ''));
$carrierNameManual = trim((string) ($input['carrier_name_manual'] ?? ''));
$packageCount = (int) ($input['package_count'] ?? 1);
$notes = trim((string) ($input['notes'] ?? ''));
$photosInput = $input['photos'] ?? [];

$photos = [];
if (is_array($photosInput)) {
    foreach ($photosInput as $photoInput) {
        if (is_array($photoInput)) {
            $value = trim((string) ($photoInput['image_base64'] ?? ''));
        } else {
            $value = trim((string) $photoInput);
        }
        if ($value !== '') {
            $photos[] = $value;
        }
    }
}

if ($packageCount <= 0) {
    $packageCount = 1;
}

$resolvedCarrierCompany = $carrierNameManual !== '' ? $carrierNameManual : $carrierCompany;

if (
    $guardReceivedId <= 0 ||
    $trackingNumber === '' ||
    ($hostId <= 0 && $recipientNameManual === '') ||
    empty($photos)
) {
    ra_json_response([
        'ok' => false,
        'message' => 'Destinatario, vigilante, numero de guia y al menos una foto son obligatorios.',
    ], 422);
}

sc_lookup(rs_receive_has_packages_table, "SHOW TABLES LIKE 'ra_packages'");
sc_lookup(rs_receive_has_package_evidence_table, "SHOW TABLES LIKE 'ra_package_evidence'");
sc_lookup(rs_receive_has_package_notifications_table, "SHOW TABLES LIKE 'ra_package_notifications'");
sc_lookup(rs_receive_has_tracking_number_column, "SHOW COLUMNS FROM ra_packages LIKE 'tracking_number'");
sc_lookup(rs_receive_has_recipient_phone_column, "SHOW COLUMNS FROM ra_packages LIKE 'recipient_phone_snapshot'");

if (
    {rs_receive_has_packages_table} === false ||
    empty({rs_receive_has_packages_table}) ||
    {rs_receive_has_package_evidence_table} === false ||
    empty({rs_receive_has_package_evidence_table}) ||
    {rs_receive_has_package_notifications_table} === false ||
    empty({rs_receive_has_package_notifications_table}) ||
    {rs_receive_has_tracking_number_column} === false ||
    empty({rs_receive_has_tracking_number_column}) ||
    {rs_receive_has_recipient_phone_column} === false ||
    empty({rs_receive_has_recipient_phone_column})
) {
    ra_json_response([
        'ok' => false,
        'message' => 'Falta crear o actualizar las tablas de paqueteria. Ejecuta runway_access_alter_v7.sql.',
    ], 500);
}

$recipientName = '';
$recipientEmail = '';
$recipientPhone = '';

if ($hostId > 0) {
    $sqlHost = "SELECT full_name, COALESCE(email, '') AS email, COALESCE(phone_number, '') AS phone_number
                FROM ra_hosts
                WHERE id = " . $hostId . "
                LIMIT 1";
    sc_lookup(rs_package_host, $sqlHost);

    if ({rs_package_host} === false || empty({rs_package_host})) {
        ra_json_response([
            'ok' => false,
            'message' => 'No se encontro el destinatario seleccionado.',
        ], 422);
    }

    $recipientName = trim((string) {rs_package_host[0][0]});
    $recipientEmail = trim((string) {rs_package_host[0][1]});
    $recipientPhone = trim((string) {rs_package_host[0][2]});
}

if ($recipientName === '') {
    $recipientName = $recipientNameManual;
}
if ($recipientEmailOverride !== '') {
    $recipientEmail = $recipientEmailOverride;
}
if ($recipientPhoneOverride !== '') {
    $recipientPhone = $recipientPhoneOverride;
}

if ($recipientName === '') {
    ra_json_response([
        'ok' => false,
        'message' => 'Debes indicar para quien es el paquete.',
    ], 422);
}

$sqlGuard = "SELECT full_name
             FROM ra_guards
             WHERE id = " . $guardReceivedId . "
               AND status = 'ACTIVE'
             LIMIT 1";
sc_lookup(rs_package_guard, $sqlGuard);

if ({rs_package_guard} === false || empty({rs_package_guard})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro el vigilante seleccionado.',
    ], 422);
}

$guardReceivedName = trim((string) {rs_package_guard[0][0]});

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_package_receive_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_package_receive_secret} !== false && !empty({rs_package_receive_secret})) {
    $documentSecret = (string) {rs_package_receive_secret[0][0]};
}

sc_begin_trans();

try {
    $insertPackage = "INSERT INTO ra_packages
        (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at)
        VALUES
        (
            " . ($hostId > 0 ? $hostId : "NULL") . ",
            " . $guardReceivedId . ",
            NULL,
            '" . ra_escape($recipientName) . "',
            " . ($recipientEmail !== '' ? "'" . ra_escape($recipientEmail) . "'" : "NULL") . ",
            " . ($recipientPhone !== '' ? "'" . ra_escape($recipientPhone) . "'" : "NULL") . ",
            NULL,
            '" . ra_escape($trackingNumber) . "',
            " . ($resolvedCarrierCompany !== '' ? "'" . ra_escape($resolvedCarrierCompany) . "'" : "NULL") . ",
            " . $packageCount . ",
            " . ($notes !== '' ? "'" . ra_escape($notes) . "'" : "NULL") . ",
            'RECEIVED',
            '" . ra_now() . "',
            NULL,
            NULL,
            '" . ra_now() . "',
            '" . ra_now() . "'
        )";
    sc_exec_sql($insertPackage);

    $sqlLastPackage = "SELECT id
                       FROM ra_packages
                       WHERE recipient_name_snapshot = '" . ra_escape($recipientName) . "'
                       ORDER BY id DESC
                       LIMIT 1";
    sc_lookup(rs_last_package, $sqlLastPackage);
    $packageId = (int) ({rs_last_package[0][0]} ?? 0);

    if ($packageId <= 0) {
        throw new Exception('No se pudo crear la recepcion del paquete.');
    }

    foreach ($photos as $index => $photoBase64) {
        $insertEvidence = "INSERT INTO ra_package_evidence
            (package_id, encrypted_blob, mime_type, key_version, is_primary, sort_order, captured_at, created_at)
            VALUES
            (
                " . $packageId . ",
                '" . ra_escape(ra_encrypt_document_image($photoBase64, $documentSecret)) . "',
                'image/jpeg',
                'v1',
                " . ($index === 0 ? 1 : 0) . ",
                " . $index . ",
                '" . ra_now() . "',
                '" . ra_now() . "'
            )";
        sc_exec_sql($insertEvidence);
    }

    sc_commit_trans();
} catch (Exception $e) {
    sc_rollback_trans();
    ra_audit_log('PACKAGE_RECEIVE_ERROR', $e->getMessage());
    ra_json_response([
        'ok' => false,
        'message' => $e->getMessage(),
    ], 500);
}

// --- Enviar respuesta al cliente ANTES de notificaciones ---
ra_json_response_then_continue([
    'ok' => true,
    'data' => [
        'package' => [
            'id' => $packageId,
            'recipient_name' => $recipientName,
            'recipient_email' => $recipientEmail,
            'recipient_phone' => $recipientPhone,
            'host_name' => $recipientName,
            'guard_received_name' => $guardReceivedName,
            'tracking_number' => $trackingNumber,
            'carrier_company' => $resolvedCarrierCompany,
            'package_count' => $packageCount,
            'notes' => $notes,
            'status' => 'RECEIVED',
            'received_at' => ra_now(),
            'notified_at' => '',
            'delivered_at' => '',
            'photo_count' => count($photos),
        ],
        'notification' => [
            'attempted' => false,
            'sent' => false,
            'message' => 'Paquete registrado. Notificacion en proceso.',
        ],
    ],
]);

// --- Notificaciones (el cliente ya recibio la respuesta) ---
$notificationAttempted = false;
$notificationSent = false;
$notificationMessages = [];
$primaryPhotoBase64 = !empty($photos) ? (string) $photos[0] : '';

try {
    $companyName = 'Control Entradas DRT';
    $smtpServer = '';
    $smtpUser = '';
    $smtpPass = '';
    $smtpFrom = '';
    $smtpPort = '587';
    $smtpSecurity = 'T';
    $packageEmailEnabled = false;
    $packageWhatsappEnabled = false;
    $wasenderApiUrl = '';
    $wasenderApiKey = '';
    sc_lookup(
        rs_package_receive_settings,
        "SELECT setting_key, setting_value
         FROM ra_app_settings
         WHERE setting_key IN ('company_name', 'smtp_server', 'smtp_user', 'smtp_pass', 'smtp_from', 'smtp_port', 'smtp_security', 'package_email_enabled', 'package_whatsapp_enabled', 'wasender_api_url', 'wasender_api_key')"
    );
    if ({rs_package_receive_settings} !== false && !empty({rs_package_receive_settings})) {
        foreach ({rs_package_receive_settings} as $row) {
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
            } elseif ($settingKey === 'package_email_enabled') {
                $packageEmailEnabled = in_array(strtolower(trim($settingValue)), ['1', 'true', 'yes', 'si', 'sí', 'on'], true);
            } elseif ($settingKey === 'package_whatsapp_enabled') {
                $packageWhatsappEnabled = in_array(strtolower(trim($settingValue)), ['1', 'true', 'yes', 'si', 'sí', 'on'], true);
            } elseif ($settingKey === 'wasender_api_url') {
                $wasenderApiUrl = $settingValue;
            } elseif ($settingKey === 'wasender_api_key') {
                $wasenderApiKey = $settingValue;
            }
        }
    }

    $whatsappImageUrl = ra_build_signed_media_public_url('package', $packageId, $documentSecret);
    $subject = ra_build_package_email_subject($companyName);
    $canWriteNotificationLog = ra_notification_table_has_columns(
        'ra_package_notifications',
        ['package_id', 'recipient_email', 'subject_line', 'delivery_status', 'error_message', 'sent_at', 'created_at']
    );

    if ($packageWhatsappEnabled && $recipientPhone !== '') {
        $notificationAttempted = true;
        $whatsappMessage = ra_build_package_whatsapp_message(
            $companyName,
            $recipientName,
            $trackingNumber,
            $resolvedCarrierCompany,
            $guardReceivedName,
            ra_now(),
            $notes
        );
        $whatsappResult = $whatsappImageUrl !== ''
            ? ra_send_whatsapp_image_url(
                $recipientPhone,
                $whatsappMessage,
                $whatsappImageUrl,
                $wasenderApiUrl,
                $wasenderApiKey
            )
            : ra_send_whatsapp_text(
                $recipientPhone,
                $whatsappMessage,
                $wasenderApiUrl,
                $wasenderApiKey
            );

        if (empty($whatsappResult['ok']) && $whatsappImageUrl !== '') {
            $fallbackWhatsappResult = ra_send_whatsapp_text(
                $recipientPhone,
                $whatsappMessage,
                $wasenderApiUrl,
                $wasenderApiKey
            );
            if (!empty($fallbackWhatsappResult['ok'])) {
                $whatsappResult = $fallbackWhatsappResult;
                $notificationMessages[] = 'WhatsApp enviado sin imagen.';
            }
        }

        if (!empty($whatsappResult['ok'])) {
            $notificationSent = true;
            if (!in_array('WhatsApp enviado sin imagen.', $notificationMessages, true)) {
                $notificationMessages[] = 'WhatsApp enviado.';
            }
        } else {
            $notificationMessages[] = 'WhatsApp: ' . (string) ($whatsappResult['message'] ?? 'No se pudo enviar.');
        }
    }

    if (
        !$notificationSent &&
        $packageEmailEnabled &&
        ra_looks_like_email($recipientEmail) &&
        trim($smtpServer) !== '' &&
        trim($smtpUser) !== '' &&
        trim($smtpPass) !== '' &&
        trim($smtpFrom) !== ''
    ) {
        $notificationAttempted = true;
        $emailHtml = ra_build_package_email_html(
            $companyName,
            $recipientName,
            $trackingNumber,
            $guardReceivedName,
            ra_now(),
            $notes,
            $primaryPhotoBase64
        );

        sc_mail_send(
            $smtpServer,
            $smtpUser,
            $smtpPass,
            $smtpFrom,
            $recipientEmail,
            $subject,
            $emailHtml,
            'H',
            '',
            '',
            $smtpPort,
            $smtpSecurity
        );

        if ({sc_mail_ok}) {
            $notificationSent = true;
            $notificationMessages[] = 'Correo enviado.';
        } else {
            $notificationMessages[] = trim((string) {sc_mail_erro}) !== ''
                ? 'Correo: ' . (string) {sc_mail_erro}
                : 'Correo: no se pudo enviar.';
        }
    }

    if ($notificationSent) {
        sc_exec_sql(
            "UPDATE ra_packages
             SET status = 'NOTIFIED',
                 notified_at = '" . ra_now() . "',
                 updated_at = '" . ra_now() . "'
             WHERE id = " . $packageId
        );
    }

    if ($notificationAttempted) {
        if ($canWriteNotificationLog) {
            sc_exec_sql(
                "INSERT INTO ra_package_notifications
                 (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at)
                 VALUES
                 (
                    " . $packageId . ",
                    '" . ra_escape($recipientEmail !== '' ? $recipientEmail : $recipientPhone) . "',
                    '" . ra_escape($subject) . "',
                    '" . ($notificationSent ? 'SENT' : 'FAILED') . "',
                    " . (!$notificationSent && !empty($notificationMessages)
                        ? "'" . ra_escape(implode(' ', $notificationMessages)) . "'"
                        : "NULL") . ",
                    " . ($notificationSent ? "'" . ra_now() . "'" : "NULL") . ",
                    '" . ra_now() . "'
                 )"
            );
        } else {
            ra_audit_log(
                'PACKAGE_NOTIFICATION_LOG_SKIPPED',
                'La tabla ra_package_notifications no tiene todas las columnas requeridas.'
            );
        }
    }
} catch (Exception $e) {
    ra_audit_log('PACKAGE_POST_SAVE_NOTIFICATION_ERROR', $e->getMessage());
    $notificationMessages[] = 'El paquete se guardo correctamente, pero la notificacion automatica fallo.';
}

$notificationMessage = 'Paquete registrado correctamente.';
if ($notificationAttempted && !empty($notificationMessages)) {
    $notificationMessage = implode(' ', $notificationMessages);
} elseif (!$notificationAttempted) {
    $notificationMessage = 'Paquete registrado sin notificacion automatica.';
}

exit;
