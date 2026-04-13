<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

ra_require_method('POST');
$input = ra_read_json_request();

$collectionId = (int) ($input['collection_id'] ?? 0);
$deliveredToName = trim((string) ($input['delivered_to_name'] ?? ''));
$signatureBase64 = trim((string) ($input['signature_base64'] ?? ''));
$deliveryNotes = trim((string) ($input['delivery_notes'] ?? ''));

if ($collectionId <= 0 || $deliveredToName === '' || $signatureBase64 === '') {
    ra_json_response([
        'ok' => false,
        'message' => 'Recoleccion, nombre de quien recibe y firma son obligatorios.',
    ], 422);
}

if (!ra_notification_table_has_columns(
    'ra_collection_delivery',
    ['collection_id', 'delivered_to_name', 'signature_encrypted_blob', 'delivered_at']
)) {
    $missingColumns = ra_get_missing_table_columns(
        'ra_collection_delivery',
        ['collection_id', 'delivered_to_name', 'signature_encrypted_blob', 'delivered_at']
    );
    ra_json_response([
        'ok' => false,
        'message' => 'La tabla ra_collection_delivery no tiene la estructura minima requerida. Faltan: '
            . implode(', ', $missingColumns) . '. Ejecuta runway_access_alter_v7.sql.',
    ], 500);
}

$deliveryHasMimeType = ra_table_has_column('ra_collection_delivery', 'mime_type');
$deliveryHasNotes = ra_table_has_column('ra_collection_delivery', 'delivery_notes');
$deliveryHasCreatedAt = ra_table_has_column('ra_collection_delivery', 'created_at');

$sqlExisting = "SELECT
                  c.status,
                  COALESCE(c.delivered_at, '') AS delivered_at,
                  COALESCE(c.requester_name_snapshot, '') AS requester_name,
                  COALESCE(c.requester_email_snapshot, '') AS requester_email,
                  COALESCE(c.requester_phone_snapshot, '') AS requester_phone,
                  COALESCE(c.tracking_number, '') AS tracking_number,
                  COALESCE(c.carrier_company, '') AS carrier_company,
                  COALESCE(c.notes, '') AS notes,
                  COALESCE(g.full_name, '') AS guard_handover_name
                FROM ra_collections c
                LEFT JOIN ra_guards g ON g.id = c.guard_handover_id
                WHERE c.id = " . $collectionId . "
                LIMIT 1";
sc_lookup(rs_collection_deliver_existing, $sqlExisting);
if ({rs_collection_deliver_existing} === false || empty({rs_collection_deliver_existing})) {
    ra_json_response([
        'ok' => false,
        'message' => 'No se encontro la recoleccion.',
    ], 404);
}

$alreadyDelivered = (string) {rs_collection_deliver_existing[0][0]} === 'DELIVERED';

$requesterName = trim((string) {rs_collection_deliver_existing[0][2]});
$requesterEmail = trim((string) {rs_collection_deliver_existing[0][3]});
$requesterPhone = trim((string) {rs_collection_deliver_existing[0][4]});
$trackingNumber = trim((string) {rs_collection_deliver_existing[0][5]});
$carrierCompany = trim((string) {rs_collection_deliver_existing[0][6]});
$notes = trim((string) {rs_collection_deliver_existing[0][7]});
$guardHandoverName = trim((string) {rs_collection_deliver_existing[0][8]});
$deliveredAt = '';

$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_collection_deliver_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_collection_deliver_secret} !== false && !empty({rs_collection_deliver_secret})) {
    $documentSecret = (string) {rs_collection_deliver_secret[0][0]};
}

$sqlExistingDelivery = "SELECT delivered_at
                        FROM ra_collection_delivery
                        WHERE collection_id = " . $collectionId . "
                        LIMIT 1";
sc_lookup(rs_collection_deliver_row, $sqlExistingDelivery);

if ({rs_collection_deliver_row} !== false && !empty({rs_collection_deliver_row})) {
    $deliveredAt = (string) {rs_collection_deliver_row[0][0]};
    sc_exec_sql(
        "UPDATE ra_collections
         SET status = 'DELIVERED',
             delivered_at = COALESCE(delivered_at, '" . ra_escape($deliveredAt) . "'),
             updated_at = '" . ra_now() . "'
         WHERE id = " . $collectionId
    );
} elseif ($alreadyDelivered) {
    ra_json_response([
        'ok' => true,
        'message' => 'Esta recoleccion ya estaba entregada.',
        'data' => [
            'collection_id' => $collectionId,
            'delivered_at' => (string) {rs_collection_deliver_existing[0][1]},
            'notification_attempted' => false,
            'notification_sent' => false,
            'notification_message' => 'Esta recoleccion ya estaba entregada.',
        ],
    ]);
} else {
    sc_begin_trans();

    try {
        $deliveredAt = ra_now();
        $insertColumns = [
            'collection_id',
            'delivered_to_name',
            'signature_encrypted_blob',
        ];
        $insertValues = [
            (string) $collectionId,
            "'" . ra_escape($deliveredToName) . "'",
            "'" . ra_escape(ra_encrypt_document_image($signatureBase64, $documentSecret)) . "'",
        ];

        if ($deliveryHasMimeType) {
            $insertColumns[] = 'mime_type';
            $insertValues[] = "'image/png'";
        }
        if ($deliveryHasNotes) {
            $insertColumns[] = 'delivery_notes';
            $insertValues[] = $deliveryNotes !== '' ? "'" . ra_escape($deliveryNotes) . "'" : "NULL";
        }

        $insertColumns[] = 'delivered_at';
        $insertValues[] = "'" . $deliveredAt . "'";

        if ($deliveryHasCreatedAt) {
            $insertColumns[] = 'created_at';
            $insertValues[] = "'" . $deliveredAt . "'";
        }

        $insertDelivery = "INSERT INTO ra_collection_delivery
            (" . implode(', ', $insertColumns) . ")
            VALUES
            (" . implode(",\n                ", $insertValues) . ")";
        sc_exec_sql($insertDelivery);

        sc_exec_sql(
            "UPDATE ra_collections
             SET status = 'DELIVERED',
                 delivered_at = '" . $deliveredAt . "',
                 updated_at = '" . ra_now() . "'
             WHERE id = " . $collectionId
        );

        sc_commit_trans();
    } catch (Exception $e) {
        sc_rollback_trans();
        ra_audit_log('COLLECTION_DELIVER_ERROR', $e->getMessage());
        ra_json_response([
            'ok' => false,
            'message' => $e->getMessage(),
        ], 500);
    }
}

// --- Enviar respuesta al cliente ANTES de notificaciones ---
ra_json_response_then_continue([
    'ok' => true,
    'message' => 'Recoleccion entregada. Notificacion en proceso.',
    'data' => [
        'collection_id' => $collectionId,
        'delivered_at' => $deliveredAt !== '' ? $deliveredAt : ra_now(),
        'notification_attempted' => false,
        'notification_sent' => false,
        'notification_message' => 'Recoleccion entregada. Notificacion en proceso.',
    ],
]);

// --- Notificaciones (el cliente ya recibio la respuesta) ---
$primaryPhotoBase64 = '';
$sqlPrimaryPhoto = "SELECT encrypted_blob
                    FROM ra_collection_evidence
                    WHERE collection_id = " . $collectionId . "
                    ORDER BY is_primary DESC, sort_order ASC, id ASC
                    LIMIT 1";
sc_lookup(rs_collection_primary_photo, $sqlPrimaryPhoto);
if ({rs_collection_primary_photo} !== false && !empty({rs_collection_primary_photo})) {
    $primaryPhotoBase64 = (string) ra_decrypt_document_image_reference(
        {rs_collection_primary_photo[0][0]},
        $documentSecret
    );
}

$notificationAttempted = false;
$notificationSent = false;
$messages = [];
try {
    $companyName = 'Control Entradas DRT';
    $smtpServer = '';
    $smtpUser = '';
    $smtpPass = '';
    $smtpFrom = '';
    $smtpPort = '587';
    $smtpSecurity = 'T';
    $collectionEmailEnabled = false;
    $collectionWhatsappEnabled = false;
    $wasenderApiUrl = '';
    $wasenderApiKey = '';
    sc_lookup(
        rs_collection_deliver_settings,
        "SELECT setting_key, setting_value
         FROM ra_app_settings
         WHERE setting_key IN ('company_name', 'smtp_server', 'smtp_user', 'smtp_pass', 'smtp_from', 'smtp_port', 'smtp_security', 'collection_email_enabled', 'collection_whatsapp_enabled', 'wasender_api_url', 'wasender_api_key')"
    );
    if ({rs_collection_deliver_settings} !== false && !empty({rs_collection_deliver_settings})) {
        foreach ({rs_collection_deliver_settings} as $row) {
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
            } elseif ($settingKey === 'collection_email_enabled') {
                $collectionEmailEnabled = in_array(strtolower(trim($settingValue)), ['1', 'true', 'yes', 'si', 'sí', 'on'], true);
            } elseif ($settingKey === 'collection_whatsapp_enabled') {
                $collectionWhatsappEnabled = in_array(strtolower(trim($settingValue)), ['1', 'true', 'yes', 'si', 'sí', 'on'], true);
            } elseif ($settingKey === 'wasender_api_url') {
                $wasenderApiUrl = $settingValue;
            } elseif ($settingKey === 'wasender_api_key') {
                $wasenderApiKey = $settingValue;
            }
        }
    }

    $whatsappImageUrl = ra_build_signed_media_public_url('collection', $collectionId, $documentSecret);
    $subject = ra_build_collection_email_subject($companyName);
    $canWriteNotificationLog = ra_notification_table_has_columns(
        'ra_collection_notifications',
        ['collection_id', 'recipient_contact', 'subject_line', 'delivery_status', 'error_message', 'sent_at', 'created_at']
    );

    if ($collectionWhatsappEnabled && $requesterPhone !== '') {
        $notificationAttempted = true;
        $whatsappMessage = ra_build_collection_whatsapp_message(
            $companyName,
            $requesterName,
            $trackingNumber,
            $carrierCompany,
            $guardHandoverName,
            $deliveredAt,
            $notes
        );
        $whatsappResult = $whatsappImageUrl !== ''
            ? ra_send_whatsapp_image_url(
                $requesterPhone,
                $whatsappMessage,
                $whatsappImageUrl,
                $wasenderApiUrl,
                $wasenderApiKey
            )
            : ra_send_whatsapp_text(
                $requesterPhone,
                $whatsappMessage,
                $wasenderApiUrl,
                $wasenderApiKey
            );

        if (empty($whatsappResult['ok']) && $whatsappImageUrl !== '') {
            $fallbackWhatsappResult = ra_send_whatsapp_text(
                $requesterPhone,
                $whatsappMessage,
                $wasenderApiUrl,
                $wasenderApiKey
            );
            if (!empty($fallbackWhatsappResult['ok'])) {
                $whatsappResult = $fallbackWhatsappResult;
                $messages[] = 'WhatsApp enviado sin imagen.';
            }
        }

        if (!empty($whatsappResult['ok'])) {
            $notificationSent = true;
            if (!in_array('WhatsApp enviado sin imagen.', $messages, true)) {
                $messages[] = 'WhatsApp enviado.';
            }
        } else {
            $messages[] = 'WhatsApp: ' . (string) ($whatsappResult['message'] ?? 'No se pudo enviar.');
        }
    }

    if (
        !$notificationSent &&
        $collectionEmailEnabled &&
        ra_looks_like_email($requesterEmail) &&
        trim($smtpServer) !== '' &&
        trim($smtpUser) !== '' &&
        trim($smtpPass) !== '' &&
        trim($smtpFrom) !== ''
    ) {
        $notificationAttempted = true;
        $emailHtml = ra_build_collection_email_html(
            $companyName,
            $requesterName,
            $trackingNumber,
            $carrierCompany,
            $guardHandoverName,
            $deliveredAt,
            $notes,
            $primaryPhotoBase64
        );

        sc_mail_send(
            $smtpServer,
            $smtpUser,
            $smtpPass,
            $smtpFrom,
            $requesterEmail,
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
            $messages[] = 'Correo enviado.';
        } else {
            $messages[] = trim((string) {sc_mail_erro}) !== ''
                ? 'Correo: ' . (string) {sc_mail_erro}
                : 'Correo: no se pudo enviar.';
        }
    }

    if ($notificationAttempted) {
        if ($canWriteNotificationLog) {
            sc_exec_sql(
                "INSERT INTO ra_collection_notifications
                 (collection_id, recipient_contact, subject_line, delivery_status, error_message, sent_at, created_at)
                 VALUES
                 (
                    " . $collectionId . ",
                    '" . ra_escape($requesterEmail !== '' ? $requesterEmail : $requesterPhone) . "',
                    '" . ra_escape($subject) . "',
                    '" . ($notificationSent ? 'SENT' : 'FAILED') . "',
                    " . (!$notificationSent && !empty($messages)
                        ? "'" . ra_escape(implode(' ', $messages)) . "'"
                        : "NULL") . ",
                    " . ($notificationSent ? "'" . ra_now() . "'" : "NULL") . ",
                    '" . ra_now() . "'
                 )"
            );
        } else {
            ra_audit_log(
                'COLLECTION_NOTIFICATION_LOG_SKIPPED',
                'La tabla ra_collection_notifications no tiene todas las columnas requeridas.'
            );
        }
    }
} catch (Exception $e) {
    ra_audit_log('COLLECTION_POST_DELIVERY_NOTIFICATION_ERROR', $e->getMessage());
    $messages[] = 'La recoleccion se entrego correctamente, pero la notificacion automatica fallo.';
}

$message = 'Recoleccion entregada correctamente.';
if ($notificationAttempted && !empty($messages)) {
    $message = implode(' ', $messages);
} elseif (!$notificationAttempted) {
    $message = 'Recoleccion entregada sin notificacion automatica.';
}

exit;
