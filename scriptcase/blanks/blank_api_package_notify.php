<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();
$packageId = (int) ($input['package_id'] ?? 0);

if ($packageId <= 0) {
    ra_json_response([
        'ok' => false,
        'message' => 'Debes indicar package_id.',
    ], 422);
}

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_package_notify_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_package_notify_secret} !== false && !empty({rs_package_notify_secret})) {
    $documentSecret = (string) {rs_package_notify_secret[0][0]};
}

$sqlPackage = "SELECT
                  p.id,
                  p.recipient_name_snapshot,
                  COALESCE(p.recipient_email_snapshot, '') AS recipient_email_snapshot,
                  COALESCE(p.recipient_phone_snapshot, '') AS recipient_phone_snapshot,
                  COALESCE(g.full_name, '') AS guard_received_name,
                  COALESCE(p.tracking_number, '') AS tracking_number,
                  COALESCE(p.carrier_company, '') AS carrier_company,
                  COALESCE(p.notes, '') AS notes,
                  p.received_at
               FROM ra_packages p
               LEFT JOIN ra_guards g ON g.id = p.guard_received_id
               WHERE p.id = " . $packageId . "
               LIMIT 1";
sc_lookup(rs_package_notify, $sqlPackage);
if ({rs_package_notify} === false || empty({rs_package_notify})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro el paquete.',
    ], 404);
}

$recipientName = (string) {rs_package_notify[0][1]};
$recipientEmail = (string) {rs_package_notify[0][2]};
$recipientPhone = (string) {rs_package_notify[0][3]};
$guardReceivedName = (string) {rs_package_notify[0][4]};
$trackingNumber = (string) {rs_package_notify[0][5]};
$carrierCompany = (string) {rs_package_notify[0][6]};
$notes = (string) {rs_package_notify[0][7]};
$receivedAt = (string) {rs_package_notify[0][8]};

$primaryPhotoBase64 = '';
$whatsappImageUrl = ra_build_signed_media_public_url('package', $packageId, $documentSecret);
$sqlPhoto = "SELECT encrypted_blob
             FROM ra_package_evidence
             WHERE package_id = " . $packageId . "
             ORDER BY is_primary DESC, sort_order ASC, id ASC
             LIMIT 1";
sc_lookup(rs_package_notify_photo, $sqlPhoto);
if ({rs_package_notify_photo} !== false && !empty({rs_package_notify_photo})) {
    $primaryPhotoBase64 = (string) ra_decrypt_document_image_reference(
        {rs_package_notify_photo[0][0]},
        $documentSecret
    );
}

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
    rs_package_notify_settings,
    "SELECT setting_key, setting_value
     FROM ra_app_settings
     WHERE setting_key IN ('company_name', 'smtp_server', 'smtp_user', 'smtp_pass', 'smtp_from', 'smtp_port', 'smtp_security', 'package_email_enabled', 'package_whatsapp_enabled', 'wasender_api_url', 'wasender_api_key')"
);
if ({rs_package_notify_settings} !== false && !empty({rs_package_notify_settings})) {
    foreach ({rs_package_notify_settings} as $row) {
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

$attempted = false;
$sent = false;
$messages = [];
$canWriteNotificationLog = ra_notification_table_has_columns(
    'ra_package_notifications',
    ['package_id', 'recipient_email', 'subject_line', 'delivery_status', 'error_message', 'sent_at', 'created_at']
);

if ($packageWhatsappEnabled && $recipientPhone !== '') {
    $attempted = true;
    $whatsappMessage = ra_build_package_whatsapp_message(
        $companyName,
        $recipientName,
        $trackingNumber,
        $carrierCompany,
        $guardReceivedName,
        $receivedAt,
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
        }
    }

    if (!empty($whatsappResult['ok'])) {
        $sent = true;
        $messages[] = 'WhatsApp enviado.';
    } else {
        $messages[] = 'WhatsApp: ' . (string) ($whatsappResult['message'] ?? 'No se pudo enviar.');
    }
}

if (
    !$sent &&
    $packageEmailEnabled &&
    ra_looks_like_email($recipientEmail) &&
    trim($smtpServer) !== '' &&
    trim($smtpUser) !== '' &&
    trim($smtpPass) !== '' &&
    trim($smtpFrom) !== ''
) {
    $attempted = true;
    $subject = ra_build_package_email_subject($companyName);
    $emailHtml = ra_build_package_email_html(
        $companyName,
        $recipientName,
        $trackingNumber,
        $guardReceivedName,
        $receivedAt,
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
        $sent = true;
        $messages[] = 'Correo enviado.';
    } else {
        $messages[] = trim((string) {sc_mail_erro}) !== ''
            ? 'Correo: ' . (string) {sc_mail_erro}
            : 'Correo: no se pudo enviar.';
    }
}

if (!$attempted) {
    ra_json_response([
        'ok' => false,
        'message' => 'No hay un canal de notificacion activo o faltan datos de contacto.',
    ], 422);
}

$subject = ra_build_package_email_subject($companyName);
if ($sent) {
    sc_exec_sql(
        "UPDATE ra_packages
         SET status = 'NOTIFIED',
             notified_at = '" . ra_now() . "',
             updated_at = '" . ra_now() . "'
         WHERE id = " . $packageId
    );
    if ($canWriteNotificationLog) {
        sc_exec_sql(
            "INSERT INTO ra_package_notifications
             (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at)
             VALUES
             (
                " . $packageId . ",
                '" . ra_escape($recipientEmail !== '' ? $recipientEmail : $recipientPhone) . "',
                '" . ra_escape($subject) . "',
                'SENT',
                NULL,
                '" . ra_now() . "',
                '" . ra_now() . "'
             )"
        );
    } else {
        ra_audit_log(
            'PACKAGE_NOTIFICATION_LOG_SKIPPED',
            'La tabla ra_package_notifications no tiene todas las columnas requeridas.'
        );
    }
    ra_json_response([
        'ok' => true,
        'message' => implode(' ', $messages),
    ]);
}

$errorMessage = !empty($messages)
    ? implode(' ', $messages)
    : 'No se pudo enviar la notificacion.';
if ($canWriteNotificationLog) {
    sc_exec_sql(
        "INSERT INTO ra_package_notifications
         (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at)
         VALUES
         (
            " . $packageId . ",
            '" . ra_escape($recipientEmail !== '' ? $recipientEmail : $recipientPhone) . "',
            '" . ra_escape($subject) . "',
            'FAILED',
            '" . ra_escape($errorMessage) . "',
            NULL,
            '" . ra_now() . "'
         )"
    );
} else {
    ra_audit_log(
        'PACKAGE_NOTIFICATION_LOG_SKIPPED',
        'La tabla ra_package_notifications no tiene todas las columnas requeridas.'
    );
}

ra_json_response([
    'ok' => false,
    'message' => $errorMessage,
], 500);
