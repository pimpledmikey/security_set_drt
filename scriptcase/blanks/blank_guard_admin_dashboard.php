<?php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);

function ra_admin_h($value)
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

function ra_admin_url($params = [])
{
    $query = $_GET;
    foreach ((array) $params as $key => $value) {
        if ($value === null) {
            unset($query[$key]);
            continue;
        }
        $query[$key] = $value;
    }

    $built = http_build_query($query);
    return $built !== '' ? ('?' . $built) : '?';
}

function ra_admin_format_minutes($minutes)
{
    $minutes = (int) $minutes;
    if ($minutes < 0) {
        $minutes = 0;
    }

    $hours = floor($minutes / 60);
    $remaining = $minutes % 60;

    if ($hours <= 0) {
        return $remaining . ' min';
    }

    return $hours . ' h ' . str_pad((string) $remaining, 2, '0', STR_PAD_LEFT) . ' min';
}

function ra_admin_format_datetime($value)
{
    if (empty($value)) {
        return 'No disponible';
    }

    $timestamp = strtotime((string) $value);
    if ($timestamp === false) {
        return (string) $value;
    }

    return date('d/m/Y H:i', $timestamp);
}

function ra_admin_status_label($checkedOutAt)
{
    return empty($checkedOutAt) ? 'Dentro' : 'Salida';
}

function ra_admin_package_status_label($status)
{
    $status = strtoupper(trim((string) $status));
    if ($status === 'DELIVERED') {
        return 'Entregado';
    }
    if ($status === 'NOTIFIED') {
        return 'Notificado';
    }
    return 'Pendiente';
}

function ra_admin_package_status_class($status)
{
    $status = strtoupper(trim((string) $status));
    if ($status === 'DELIVERED') {
        return 'success';
    }
    if ($status === 'NOTIFIED') {
        return 'primary';
    }
    return 'warning';
}

function ra_admin_collection_status_label($status)
{
    $status = strtoupper(trim((string) $status));
    if ($status === 'DELIVERED') {
        return 'Entregada';
    }
    return 'Pendiente';
}

function ra_admin_collection_status_class($status)
{
    $status = strtoupper(trim((string) $status));
    if ($status === 'DELIVERED') {
        return 'success';
    }
    return 'warning';
}

function ra_admin_notification_label($status)
{
    $status = strtoupper(trim((string) $status));
    if ($status === 'SENT') {
        return 'Aviso enviado';
    }
    if ($status === 'FAILED') {
        return 'Aviso con error';
    }
    return 'Sin envio';
}

function ra_admin_notification_class($status)
{
    $status = strtoupper(trim((string) $status));
    if ($status === 'SENT') {
        return 'success';
    }
    if ($status === 'FAILED') {
        return 'warning';
    }
    return 'primary';
}

$mode = trim((string) ($_GET['mode'] ?? ''));
$documentSecret = 'CHANGE_THIS_TO_A_REAL_SECRET';
sc_lookup(
    rs_admin_secret,
    "SELECT setting_value
     FROM ra_app_settings
     WHERE setting_key = 'document_encryption_key'
     LIMIT 1"
);
if ({rs_admin_secret} !== false && !empty({rs_admin_secret})) {
    $documentSecret = (string) {rs_admin_secret[0][0]};
}

if ($mode === 'photo') {
    ra_require_method('GET');

    $visitId = (int) ($_GET['visit_id'] ?? 0);
    if ($visitId <= 0) {
        ra_json_response([
            'ok' => false,
            'message' => 'Debes indicar visit_id.',
        ], 422);
    }

    $photoBase64 = '';
    $sqlPhoto = "SELECT encrypted_blob, COALESCE(mime_type, 'image/jpeg')
                 FROM ra_visitor_documents
                 WHERE visit_event_id = " . $visitId . "
                 ORDER BY id DESC
                 LIMIT 1";
    sc_lookup(rs_admin_photo, $sqlPhoto);
    if ({rs_admin_photo} !== false && !empty({rs_admin_photo})) {
        $photoBase64 = (string) ra_decrypt_document_image_reference(
            {rs_admin_photo[0][0]},
            $documentSecret
        );
    }

    ra_json_response([
        'ok' => true,
        'data' => [
            'image_base64' => $photoBase64,
            'mime_type' => ({rs_admin_photo} !== false && !empty({rs_admin_photo}))
                ? (string) {rs_admin_photo[0][1]}
                : 'image/jpeg',
        ],
    ]);
}

if ($mode === 'package_photos') {
    ra_require_method('GET');

    $packageId = (int) ($_GET['package_id'] ?? 0);
    if ($packageId <= 0) {
        ra_json_response([
            'ok' => false,
            'message' => 'Debes indicar package_id.',
        ], 422);
    }

    $photos = [];
    $sqlPackagePhotos = "SELECT encrypted_blob, COALESCE(mime_type, 'image/jpeg'), sort_order
                         FROM ra_package_evidence
                         WHERE package_id = " . $packageId . "
                         ORDER BY sort_order ASC, id ASC";
    sc_select(rs_admin_package_photos, $sqlPackagePhotos);
    if ({rs_admin_package_photos} !== false) {
        while (!{rs_admin_package_photos}->EOF) {
            $photos[] = [
                'image_base64' => (string) ra_decrypt_document_image_reference(
                    {rs_admin_package_photos}->fields[0],
                    $documentSecret
                ),
                'mime_type' => (string) {rs_admin_package_photos}->fields[1],
                'sort_order' => (int) {rs_admin_package_photos}->fields[2],
            ];
            {rs_admin_package_photos}->MoveNext();
        }
        {rs_admin_package_photos}->Close();
    }

    ra_json_response([
        'ok' => true,
        'data' => [
            'photos' => $photos,
        ],
    ]);
}

if ($mode === 'package_signature') {
    ra_require_method('GET');

    $packageId = (int) ($_GET['package_id'] ?? 0);
    if ($packageId <= 0) {
        ra_json_response([
            'ok' => false,
            'message' => 'Debes indicar package_id.',
        ], 422);
    }

    $packageSignatureMimeSelect = ra_table_has_column('ra_package_delivery', 'mime_type')
        ? "COALESCE(mime_type, 'image/png')"
        : "'image/png'";
    $sqlSignature = "SELECT received_by_name, signature_encrypted_blob, " . $packageSignatureMimeSelect . " AS mime_type, delivered_at
                     FROM ra_package_delivery
                     WHERE package_id = " . $packageId . "
                     LIMIT 1";
    sc_lookup(rs_admin_package_signature, $sqlSignature);

    if ({rs_admin_package_signature} === false || empty({rs_admin_package_signature})) {
        ra_json_response([
            'ok' => true,
            'data' => [
                'signature_base64' => '',
                'received_by_name' => '',
                'delivered_at' => '',
            ],
        ]);
    }

    ra_json_response([
        'ok' => true,
        'data' => [
            'signature_base64' => (string) ra_decrypt_document_image_reference(
                {rs_admin_package_signature[0][1]},
                $documentSecret
            ),
            'received_by_name' => (string) {rs_admin_package_signature[0][0]},
            'mime_type' => (string) {rs_admin_package_signature[0][2]},
            'delivered_at' => (string) {rs_admin_package_signature[0][3]},
        ],
    ]);
}

if ($mode === 'collection_photos') {
    ra_require_method('GET');

    $collectionId = (int) ($_GET['collection_id'] ?? 0);
    if ($collectionId <= 0) {
        ra_json_response([
            'ok' => false,
            'message' => 'Debes indicar collection_id.',
        ], 422);
    }

    $photos = [];
    $sqlCollectionPhotos = "SELECT encrypted_blob, COALESCE(mime_type, 'image/jpeg'), sort_order
                            FROM ra_collection_evidence
                            WHERE collection_id = " . $collectionId . "
                            ORDER BY sort_order ASC, id ASC";
    sc_select(rs_admin_collection_photos, $sqlCollectionPhotos);
    if ({rs_admin_collection_photos} !== false) {
        while (!{rs_admin_collection_photos}->EOF) {
            $photos[] = [
                'image_base64' => (string) ra_decrypt_document_image_reference(
                    {rs_admin_collection_photos}->fields[0],
                    $documentSecret
                ),
                'mime_type' => (string) {rs_admin_collection_photos}->fields[1],
                'sort_order' => (int) {rs_admin_collection_photos}->fields[2],
            ];
            {rs_admin_collection_photos}->MoveNext();
        }
        {rs_admin_collection_photos}->Close();
    }

    ra_json_response([
        'ok' => true,
        'data' => [
            'photos' => $photos,
        ],
    ]);
}

if ($mode === 'collection_signature') {
    ra_require_method('GET');

    $collectionId = (int) ($_GET['collection_id'] ?? 0);
    if ($collectionId <= 0) {
        ra_json_response([
            'ok' => false,
            'message' => 'Debes indicar collection_id.',
        ], 422);
    }

    $collectionSignatureMimeSelect = ra_table_has_column('ra_collection_delivery', 'mime_type')
        ? "COALESCE(mime_type, 'image/png')"
        : "'image/png'";
    $sqlCollectionSignature = "SELECT delivered_to_name, signature_encrypted_blob, " . $collectionSignatureMimeSelect . " AS mime_type, delivered_at
                               FROM ra_collection_delivery
                               WHERE collection_id = " . $collectionId . "
                               LIMIT 1";
    sc_lookup(rs_admin_collection_signature, $sqlCollectionSignature);

    if ({rs_admin_collection_signature} === false || empty({rs_admin_collection_signature})) {
        ra_json_response([
            'ok' => true,
            'data' => [
                'signature_base64' => '',
                'received_by_name' => '',
                'delivered_at' => '',
            ],
        ]);
    }

    ra_json_response([
        'ok' => true,
        'data' => [
            'signature_base64' => (string) ra_decrypt_document_image_reference(
                {rs_admin_collection_signature[0][1]},
                $documentSecret
            ),
            'received_by_name' => (string) {rs_admin_collection_signature[0][0]},
            'mime_type' => (string) {rs_admin_collection_signature[0][2]},
            'delivered_at' => (string) {rs_admin_collection_signature[0][3]},
        ],
    ]);
}

$today = date('Y-m-d');
$datePreset = trim((string) ($_GET['date_preset'] ?? ''));
if (!in_array($datePreset, ['', 'today', '7d', '30d'], true)) {
    $datePreset = '';
}
$legacyDate = trim((string) ($_GET['date'] ?? $today));
$dateFrom = trim((string) ($_GET['date_from'] ?? $legacyDate));
$dateTo = trim((string) ($_GET['date_to'] ?? $legacyDate));
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateFrom)) {
    $dateFrom = $today;
}
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateTo)) {
    $dateTo = $dateFrom;
}
if ($dateFrom > $dateTo) {
    $tmpDate = $dateFrom;
    $dateFrom = $dateTo;
    $dateTo = $tmpDate;
}
if ($datePreset === 'today') {
    $dateFrom = $today;
    $dateTo = $today;
} elseif ($datePreset === '7d') {
    $dateFrom = date('Y-m-d', strtotime('-6 days'));
    $dateTo = $today;
} elseif ($datePreset === '30d') {
    $dateFrom = date('Y-m-d', strtotime('-29 days'));
    $dateTo = $today;
}

$legacyStatus = trim((string) ($_GET['status'] ?? ''));
$section = trim((string) ($_GET['section'] ?? 'visits'));
if (!in_array($section, ['visits', 'packages', 'collections'], true)) {
    $section = 'visits';
}

$quick = trim((string) ($_GET['quick'] ?? ''));
if (!in_array($quick, ['', 'visits_inside_now', 'packages_pending_all', 'collections_pending_all'], true)) {
    $quick = '';
}

$visitStatus = trim((string) ($_GET['visit_status'] ?? ($legacyStatus !== '' ? $legacyStatus : 'all')));
if (!in_array($visitStatus, ['all', 'inside', 'completed'], true)) {
    $visitStatus = 'all';
}

$packageStatus = trim((string) ($_GET['package_status'] ?? ''));
if ($packageStatus === '') {
    $packageStatus = $legacyStatus === 'completed' ? 'delivered' : 'pending';
}
if ($packageStatus === 'delivered_range' || $packageStatus === 'delivered_all' || $packageStatus === 'all') {
    $packageStatus = $packageStatus === 'pending' ? 'pending' : 'delivered';
}
if (!in_array($packageStatus, ['pending', 'delivered'], true)) {
    $packageStatus = 'pending';
}
$legacyPackageEmailFilter = trim((string) ($_GET['package_email_filter'] ?? 'all'));
$packageContactFilter = trim((string) ($_GET['package_contact_filter'] ?? $legacyPackageEmailFilter));
if ($packageContactFilter === 'missing') {
    $packageContactFilter = 'missing_email';
} elseif ($packageContactFilter === 'present') {
    $packageContactFilter = 'email';
}
if (!in_array($packageContactFilter, ['all', 'missing_phone', 'missing_email', 'missing_contact', 'phone', 'email'], true)) {
    $packageContactFilter = 'all';
}
$collectionStatus = trim((string) ($_GET['collection_status'] ?? ''));
if ($collectionStatus === '') {
    $collectionStatus = $legacyStatus === 'completed' ? 'delivered' : 'pending';
}
if (!in_array($collectionStatus, ['pending', 'delivered'], true)) {
    $collectionStatus = 'pending';
}
$legacyCollectionPhoneFilter = trim((string) ($_GET['collection_phone_filter'] ?? 'all'));
$collectionContactFilter = trim((string) ($_GET['collection_contact_filter'] ?? $legacyCollectionPhoneFilter));
if ($collectionContactFilter === 'missing') {
    $collectionContactFilter = 'missing_phone';
} elseif ($collectionContactFilter === 'present') {
    $collectionContactFilter = 'phone';
}
if (!in_array($collectionContactFilter, ['all', 'missing_phone', 'missing_email', 'missing_contact', 'phone', 'email'], true)) {
    $collectionContactFilter = 'all';
}
$visitAlertMinutes = 1440;
$packageAlertDays = 3;
$collectionAlertDays = 3;

if ($quick === 'visits_inside_now') {
    $section = 'visits';
    $visitStatus = 'inside';
}
if ($quick === 'packages_pending_all') {
    $section = 'packages';
    $packageStatus = 'pending';
}
if ($quick === 'collections_pending_all') {
    $section = 'collections';
    $collectionStatus = 'pending';
}

$search = trim((string) ($_GET['q'] ?? ''));
$dateFromStart = $dateFrom . ' 00:00:00';
$dateToEnd = $dateTo . ' 23:59:59';
$where = [];
if ($quick !== 'visits_inside_now') {
    $where[] = "e.entered_at >= '" . ra_escape($dateFromStart) . "'";
    $where[] = "e.entered_at <= '" . ra_escape($dateToEnd) . "'";
}

if ($visitStatus === 'inside') {
    $where[] = "e.checked_out_at IS NULL";
} elseif ($visitStatus === 'completed') {
    $where[] = "e.checked_out_at IS NOT NULL";
}

if ($search !== '') {
    $where[] = "(
        v.full_name LIKE '%" . ra_escape($search) . "%'
        OR COALESCE(h.full_name, '') LIKE '%" . ra_escape($search) . "%'
        OR COALESCE(e.purpose, '') LIKE '%" . ra_escape($search) . "%'
        OR COALESCE(e.observations, '') LIKE '%" . ra_escape($search) . "%'
    )";
}

$whereSql = implode(' AND ', $where);

$summarySql = "SELECT
                  COUNT(*) AS total_visits,
                  SUM(CASE WHEN e.checked_out_at IS NULL THEN 1 ELSE 0 END) AS inside_count,
                  COALESCE(SUM(e.group_size), 0) AS people_count,
                  COALESCE(AVG(TIMESTAMPDIFF(MINUTE, e.entered_at, COALESCE(e.checked_out_at, NOW()))), 0) AS avg_minutes
               FROM ra_visit_events e
               INNER JOIN ra_visitors v ON v.id = e.visitor_id
               LEFT JOIN ra_hosts h ON h.id = e.host_id
               WHERE " . $whereSql;
sc_lookup(rs_admin_summary, $summarySql);

$summary = [
    'total_visits' => (int) ({rs_admin_summary[0][0]} ?? 0),
    'inside_count' => (int) ({rs_admin_summary[0][1]} ?? 0),
    'people_count' => (int) ({rs_admin_summary[0][2]} ?? 0),
    'avg_minutes' => (int) round((float) ({rs_admin_summary[0][3]} ?? 0)),
];

$rowsSql = "SELECT
                e.id,
                v.full_name,
                COALESCE(h.full_name, 'Sin anfitrion') AS host_name,
                COALESCE(e.purpose, 'Visita general') AS purpose,
                COALESCE(e.observations, '') AS observations,
                e.has_appointment,
                COALESCE(e.group_size, 1) AS group_size,
                e.entered_at,
                e.checked_out_at,
                TIMESTAMPDIFF(MINUTE, e.entered_at, COALESCE(e.checked_out_at, NOW())) AS duration_minutes,
                (
                    SELECT COUNT(*)
                    FROM ra_visitor_documents d
                    WHERE d.visit_event_id = e.id
                ) AS document_count
            FROM ra_visit_events e
            INNER JOIN ra_visitors v ON v.id = e.visitor_id
            LEFT JOIN ra_hosts h ON h.id = e.host_id
            WHERE " . $whereSql . "
            ORDER BY e.entered_at DESC
            LIMIT 80";

sc_select(rs_admin_rows, $rowsSql);
$rows = [];
if ({rs_admin_rows} !== false) {
    while (!{rs_admin_rows}->EOF) {
        $rows[] = [
            'id' => (int) {rs_admin_rows}->fields[0],
            'full_name' => (string) {rs_admin_rows}->fields[1],
            'host_name' => (string) {rs_admin_rows}->fields[2],
            'purpose' => (string) {rs_admin_rows}->fields[3],
            'observations' => (string) {rs_admin_rows}->fields[4],
            'has_appointment' => (int) {rs_admin_rows}->fields[5] === 1,
            'group_size' => (int) {rs_admin_rows}->fields[6],
            'entered_at' => (string) {rs_admin_rows}->fields[7],
            'checked_out_at' => (string) {rs_admin_rows}->fields[8],
            'duration_minutes' => (int) {rs_admin_rows}->fields[9],
            'has_photo' => (int) {rs_admin_rows}->fields[10] > 0,
            'is_long_inside' => ((string) {rs_admin_rows}->fields[8] === '')
                && ((int) {rs_admin_rows}->fields[9] >= $visitAlertMinutes),
        ];
        {rs_admin_rows}->MoveNext();
    }
    {rs_admin_rows}->Close();
}

$cards = [
    ['label' => 'Entradas', 'value' => $summary['total_visits']],
    ['label' => 'Dentro', 'value' => $summary['inside_count']],
    ['label' => 'Personas', 'value' => $summary['people_count']],
    ['label' => 'Tiempo promedio', 'value' => ra_admin_format_minutes($summary['avg_minutes'])],
];

$visitInsideBubbleCount = 0;
sc_lookup(
    rs_admin_inside_bubble,
    "SELECT COALESCE(SUM(COALESCE(group_size, 1)), 0)
     FROM ra_visit_events
     WHERE checked_out_at IS NULL"
);
$visitInsideBubbleCount = (int) ({rs_admin_inside_bubble[0][0]} ?? 0);

$packageRows = [];
$packagePendingBubbleCount = 0;
$packageCards = [
    ['label' => 'Paquetes pendientes', 'value' => 0],
    ['label' => 'Piezas pendientes', 'value' => 0],
    ['label' => 'Con WhatsApp', 'value' => 0],
    ['label' => 'Sin contacto', 'value' => 0],
];
$packageSchemaMessage = '';

sc_lookup(rs_admin_has_packages, "SHOW TABLES LIKE 'ra_packages'");
sc_lookup(rs_admin_has_package_evidence, "SHOW TABLES LIKE 'ra_package_evidence'");
sc_lookup(rs_admin_has_package_delivery, "SHOW TABLES LIKE 'ra_package_delivery'");

if (
    {rs_admin_has_packages} === false ||
    empty({rs_admin_has_packages}) ||
    {rs_admin_has_package_evidence} === false ||
    empty({rs_admin_has_package_evidence}) ||
    {rs_admin_has_package_delivery} === false ||
    empty({rs_admin_has_package_delivery})
) {
    $packageSchemaMessage = 'Falta crear las tablas de paqueteria para supervisarlas aqui.';
} else {
    sc_lookup(
        rs_admin_package_pending_bubble,
        "SELECT COUNT(*)
         FROM ra_packages
         WHERE status <> 'DELIVERED'"
    );
    $packagePendingBubbleCount = (int) ({rs_admin_package_pending_bubble[0][0]} ?? 0);

    $packageSearchWhere = [];
    if ($search !== '') {
        $packageSearchWhere[] = "(
            COALESCE(p.recipient_name_snapshot, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(p.recipient_email_snapshot, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(p.recipient_phone_snapshot, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(h.full_name, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(g.full_name, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(p.tracking_number, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(p.carrier_company, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(p.notes, '') LIKE '%" . ra_escape($search) . "%'
        )";
    }
    if ($packageContactFilter === 'missing_phone') {
        $packageSearchWhere[] = "COALESCE(p.recipient_phone_snapshot, '') = ''";
    } elseif ($packageContactFilter === 'missing_email') {
        $packageSearchWhere[] = "COALESCE(p.recipient_email_snapshot, '') = ''";
    } elseif ($packageContactFilter === 'missing_contact') {
        $packageSearchWhere[] = "COALESCE(p.recipient_phone_snapshot, '') = ''";
        $packageSearchWhere[] = "COALESCE(p.recipient_email_snapshot, '') = ''";
    } elseif ($packageContactFilter === 'phone') {
        $packageSearchWhere[] = "COALESCE(p.recipient_phone_snapshot, '') <> ''";
    } elseif ($packageContactFilter === 'email') {
        $packageSearchWhere[] = "COALESCE(p.recipient_email_snapshot, '') <> ''";
    }

    $packageBaseWhere = $packageSearchWhere;
    if ($packageStatus === 'delivered') {
        $packageBaseWhere[] = "p.status = 'DELIVERED'";
        $packageBaseWhere[] = "p.delivered_at >= '" . ra_escape($dateFromStart) . "'";
        $packageBaseWhere[] = "p.delivered_at <= '" . ra_escape($dateToEnd) . "'";
    } else {
        $packageBaseWhere[] = "p.status <> 'DELIVERED'";
    }

    $packageWhereSql = empty($packageBaseWhere)
        ? '1=1'
        : implode(' AND ', $packageBaseWhere);

    $packageSummarySql = "SELECT
                            COUNT(*) AS package_total,
                            COALESCE(SUM(p.package_count), 0) AS piece_total,
                            SUM(CASE WHEN COALESCE(p.recipient_phone_snapshot, '') <> '' THEN 1 ELSE 0 END) AS with_phone_total,
                            SUM(CASE WHEN COALESCE(p.recipient_email_snapshot, '') <> '' THEN 1 ELSE 0 END) AS with_email_total,
                            SUM(CASE WHEN COALESCE(p.recipient_phone_snapshot, '') = '' AND COALESCE(p.recipient_email_snapshot, '') = '' THEN 1 ELSE 0 END) AS without_contact_total,
                            SUM(CASE WHEN EXISTS(
                                SELECT 1
                                FROM ra_package_delivery pd
                                WHERE pd.package_id = p.id
                            ) THEN 1 ELSE 0 END) AS signed_total
                         FROM ra_packages p
                         LEFT JOIN ra_hosts h ON h.id = p.host_id
                         LEFT JOIN ra_guards g ON g.id = p.guard_received_id
                         WHERE " . $packageWhereSql;
    sc_lookup(rs_admin_package_summary, $packageSummarySql);

    if ($packageStatus === 'delivered') {
        $packageCards = [
            ['label' => 'Paquetes entregados', 'value' => (int) ({rs_admin_package_summary[0][0]} ?? 0)],
            ['label' => 'Piezas entregadas', 'value' => (int) ({rs_admin_package_summary[0][1]} ?? 0)],
            ['label' => 'Entregas con firma', 'value' => (int) ({rs_admin_package_summary[0][5]} ?? 0)],
            ['label' => 'Con WhatsApp', 'value' => (int) ({rs_admin_package_summary[0][2]} ?? 0)],
        ];
    } else {
        $packageCards = [
            ['label' => 'Paquetes pendientes', 'value' => (int) ({rs_admin_package_summary[0][0]} ?? 0)],
            ['label' => 'Piezas pendientes', 'value' => (int) ({rs_admin_package_summary[0][1]} ?? 0)],
            ['label' => 'Con WhatsApp', 'value' => (int) ({rs_admin_package_summary[0][2]} ?? 0)],
            ['label' => 'Sin contacto', 'value' => (int) ({rs_admin_package_summary[0][4]} ?? 0)],
        ];
    }

    $packageRowsSql = "SELECT
                          p.id,
                          COALESCE(p.recipient_name_snapshot, '') AS recipient_name,
                          COALESCE(p.recipient_email_snapshot, '') AS recipient_email,
                          COALESCE(p.recipient_phone_snapshot, '') AS recipient_phone,
                          COALESCE(h.full_name, p.recipient_name_snapshot) AS host_name,
                          COALESCE(g.full_name, '') AS guard_received_name,
                          COALESCE(p.tracking_number, '') AS tracking_number,
                          COALESCE(p.carrier_company, '') AS carrier_company,
                          COALESCE(p.package_count, 1) AS package_count,
                          COALESCE(p.notes, '') AS notes,
                          p.status,
                          p.received_at,
                          COALESCE(p.notified_at, '') AS notified_at,
                          COALESCE(p.delivered_at, '') AS delivered_at,
                          (
                              SELECT COUNT(*)
                              FROM ra_package_evidence pe
                              WHERE pe.package_id = p.id
                          ) AS photo_count,
                          COALESCE((
                              SELECT pd.received_by_name
                              FROM ra_package_delivery pd
                              WHERE pd.package_id = p.id
                              LIMIT 1
                          ), '') AS received_by_name,
                          COALESCE((
                              SELECT pn.delivery_status
                              FROM ra_package_notifications pn
                              WHERE pn.package_id = p.id
                              ORDER BY pn.id DESC
                              LIMIT 1
                          ), '') AS notification_status,
                          (
                              SELECT COUNT(*)
                              FROM ra_package_delivery pd2
                              WHERE pd2.package_id = p.id
                          ) AS signature_count,
                          TIMESTAMPDIFF(DAY, p.received_at, NOW()) AS pending_age_days
                      FROM ra_packages p
                      LEFT JOIN ra_hosts h ON h.id = p.host_id
                      LEFT JOIN ra_guards g ON g.id = p.guard_received_id
                      WHERE " . $packageWhereSql . "
                      ORDER BY
                        " . ($packageStatus === 'delivered'
                            ? "p.delivered_at DESC"
                            : "p.received_at ASC") . "
                      LIMIT 80";
    sc_select(rs_admin_package_rows, $packageRowsSql);
    if ({rs_admin_package_rows} !== false) {
        while (!{rs_admin_package_rows}->EOF) {
            $packageRows[] = [
                'id' => (int) {rs_admin_package_rows}->fields[0],
                'recipient_name' => (string) {rs_admin_package_rows}->fields[1],
                'recipient_email' => (string) {rs_admin_package_rows}->fields[2],
                'recipient_phone' => (string) {rs_admin_package_rows}->fields[3],
                'host_name' => (string) {rs_admin_package_rows}->fields[4],
                'guard_received_name' => (string) {rs_admin_package_rows}->fields[5],
                'tracking_number' => (string) {rs_admin_package_rows}->fields[6],
                'carrier_company' => (string) {rs_admin_package_rows}->fields[7],
                'package_count' => (int) {rs_admin_package_rows}->fields[8],
                'notes' => (string) {rs_admin_package_rows}->fields[9],
                'status' => (string) {rs_admin_package_rows}->fields[10],
                'received_at' => (string) {rs_admin_package_rows}->fields[11],
                'notified_at' => (string) {rs_admin_package_rows}->fields[12],
                'delivered_at' => (string) {rs_admin_package_rows}->fields[13],
                'photo_count' => (int) {rs_admin_package_rows}->fields[14],
                'received_by_name' => (string) {rs_admin_package_rows}->fields[15],
                'notification_status' => (string) {rs_admin_package_rows}->fields[16],
                'has_signature' => (int) {rs_admin_package_rows}->fields[17] > 0,
                'pending_age_days' => (int) {rs_admin_package_rows}->fields[18],
                'is_old_pending' => strtoupper((string) {rs_admin_package_rows}->fields[10]) !== 'DELIVERED'
                    && (int) {rs_admin_package_rows}->fields[18] >= $packageAlertDays,
            ];
            {rs_admin_package_rows}->MoveNext();
        }
            {rs_admin_package_rows}->Close();
    }
}

$collectionRows = [];
$collectionPendingBubbleCount = 0;
$collectionCards = [
    ['label' => 'Solicitudes pendientes', 'value' => 0],
    ['label' => 'Con WhatsApp', 'value' => 0],
    ['label' => 'Con correo', 'value' => 0],
    ['label' => 'Sin contacto', 'value' => 0],
];
$collectionSchemaMessage = '';

sc_lookup(rs_admin_has_collections, "SHOW TABLES LIKE 'ra_collections'");
sc_lookup(rs_admin_has_collection_evidence, "SHOW TABLES LIKE 'ra_collection_evidence'");
sc_lookup(rs_admin_has_collection_delivery, "SHOW TABLES LIKE 'ra_collection_delivery'");

if (
    {rs_admin_has_collections} === false ||
    empty({rs_admin_has_collections}) ||
    {rs_admin_has_collection_evidence} === false ||
    empty({rs_admin_has_collection_evidence}) ||
    {rs_admin_has_collection_delivery} === false ||
    empty({rs_admin_has_collection_delivery})
) {
    $collectionSchemaMessage = 'Falta crear las tablas de recolección para supervisarlas aquí.';
} else {
    sc_lookup(
        rs_admin_collection_pending_bubble,
        "SELECT COUNT(*)
         FROM ra_collections
         WHERE status <> 'DELIVERED'"
    );
    $collectionPendingBubbleCount = (int) ({rs_admin_collection_pending_bubble[0][0]} ?? 0);

    $collectionSearchWhere = [];
    if ($search !== '') {
        $collectionSearchWhere[] = "(
            COALESCE(c.requester_name_snapshot, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(c.requester_email_snapshot, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(c.requester_phone_snapshot, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(h.full_name, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(g.full_name, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(c.tracking_number, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(c.carrier_company, '') LIKE '%" . ra_escape($search) . "%'
            OR COALESCE(c.notes, '') LIKE '%" . ra_escape($search) . "%'
        )";
    }
    if ($collectionContactFilter === 'missing_phone') {
        $collectionSearchWhere[] = "COALESCE(c.requester_phone_snapshot, '') = ''";
    } elseif ($collectionContactFilter === 'missing_email') {
        $collectionSearchWhere[] = "COALESCE(c.requester_email_snapshot, '') = ''";
    } elseif ($collectionContactFilter === 'missing_contact') {
        $collectionSearchWhere[] = "COALESCE(c.requester_phone_snapshot, '') = ''";
        $collectionSearchWhere[] = "COALESCE(c.requester_email_snapshot, '') = ''";
    } elseif ($collectionContactFilter === 'phone') {
        $collectionSearchWhere[] = "COALESCE(c.requester_phone_snapshot, '') <> ''";
    } elseif ($collectionContactFilter === 'email') {
        $collectionSearchWhere[] = "COALESCE(c.requester_email_snapshot, '') <> ''";
    }

    $collectionBaseWhere = $collectionSearchWhere;
    if ($collectionStatus === 'delivered') {
        $collectionBaseWhere[] = "c.status = 'DELIVERED'";
        $collectionBaseWhere[] = "c.delivered_at >= '" . ra_escape($dateFromStart) . "'";
        $collectionBaseWhere[] = "c.delivered_at <= '" . ra_escape($dateToEnd) . "'";
    } else {
        $collectionBaseWhere[] = "c.status <> 'DELIVERED'";
    }

    $collectionWhereSql = empty($collectionBaseWhere)
        ? '1=1'
        : implode(' AND ', $collectionBaseWhere);

    $collectionSummarySql = "SELECT
                                COUNT(*) AS collection_total,
                                SUM(CASE WHEN COALESCE(c.requester_phone_snapshot, '') <> '' THEN 1 ELSE 0 END) AS with_phone_total,
                                SUM(CASE WHEN COALESCE(c.requester_email_snapshot, '') <> '' THEN 1 ELSE 0 END) AS with_email_total,
                                SUM(CASE WHEN COALESCE(c.requester_phone_snapshot, '') = '' AND COALESCE(c.requester_email_snapshot, '') = '' THEN 1 ELSE 0 END) AS no_contact_total,
                                SUM(CASE WHEN EXISTS(
                                    SELECT 1
                                    FROM ra_collection_delivery cd
                                    WHERE cd.collection_id = c.id
                                ) THEN 1 ELSE 0 END) AS signed_total,
                                SUM(CASE WHEN EXISTS(
                                    SELECT 1
                                    FROM ra_collection_notifications cn
                                    WHERE cn.collection_id = c.id
                                      AND cn.delivery_status = 'SENT'
                                ) THEN 1 ELSE 0 END) AS notified_total
                             FROM ra_collections c
                             LEFT JOIN ra_hosts h ON h.id = c.host_id
                             LEFT JOIN ra_guards g ON g.id = c.guard_handover_id
                             WHERE " . $collectionWhereSql;
    sc_lookup(rs_admin_collection_summary, $collectionSummarySql);

    if ($collectionStatus === 'delivered') {
        $collectionCards = [
            ['label' => 'Recolecciones entregadas', 'value' => (int) ({rs_admin_collection_summary[0][0]} ?? 0)],
            ['label' => 'Entregas con firma', 'value' => (int) ({rs_admin_collection_summary[0][4]} ?? 0)],
            ['label' => 'Avisos enviados', 'value' => (int) ({rs_admin_collection_summary[0][5]} ?? 0)],
            ['label' => 'Con WhatsApp', 'value' => (int) ({rs_admin_collection_summary[0][1]} ?? 0)],
        ];
    } else {
        $collectionCards = [
            ['label' => 'Solicitudes pendientes', 'value' => (int) ({rs_admin_collection_summary[0][0]} ?? 0)],
            ['label' => 'Con WhatsApp', 'value' => (int) ({rs_admin_collection_summary[0][1]} ?? 0)],
            ['label' => 'Con correo', 'value' => (int) ({rs_admin_collection_summary[0][2]} ?? 0)],
            ['label' => 'Sin contacto', 'value' => (int) ({rs_admin_collection_summary[0][3]} ?? 0)],
        ];
    }

    $collectionRowsSql = "SELECT
                             c.id,
                             COALESCE(c.requester_name_snapshot, '') AS requester_name,
                             COALESCE(c.requester_email_snapshot, '') AS requester_email,
                             COALESCE(c.requester_phone_snapshot, '') AS requester_phone,
                             COALESCE(h.full_name, c.requester_name_snapshot) AS host_name,
                             COALESCE(g.full_name, '') AS guard_handover_name,
                             COALESCE(c.tracking_number, '') AS tracking_number,
                             COALESCE(c.carrier_company, '') AS carrier_company,
                             COALESCE(c.notes, '') AS notes,
                             c.status,
                             c.registered_at,
                             COALESCE(c.delivered_at, '') AS delivered_at,
                             (SELECT COUNT(*) FROM ra_collection_evidence ce WHERE ce.collection_id = c.id) AS photo_count,
                             COALESCE((
                                 SELECT cd.delivered_to_name
                                 FROM ra_collection_delivery cd
                                 WHERE cd.collection_id = c.id
                                 LIMIT 1
                             ), '') AS delivered_to_name,
                             COALESCE((
                                 SELECT cn.delivery_status
                                 FROM ra_collection_notifications cn
                                 WHERE cn.collection_id = c.id
                                 ORDER BY cn.id DESC
                                 LIMIT 1
                             ), '') AS notification_status,
                             COALESCE((
                                 SELECT cn.sent_at
                                 FROM ra_collection_notifications cn
                                 WHERE cn.collection_id = c.id
                                 ORDER BY cn.id DESC
                                 LIMIT 1
                             ), '') AS notification_sent_at,
                             (SELECT COUNT(*) FROM ra_collection_delivery cd2 WHERE cd2.collection_id = c.id) AS signature_count,
                             TIMESTAMPDIFF(DAY, c.registered_at, NOW()) AS pending_age_days
                         FROM ra_collections c
                         LEFT JOIN ra_hosts h ON h.id = c.host_id
                         LEFT JOIN ra_guards g ON g.id = c.guard_handover_id
                         WHERE " . $collectionWhereSql . "
                         ORDER BY
                           " . ($collectionStatus === 'delivered'
                                ? "c.delivered_at DESC"
                                : "c.registered_at ASC") . "
                         LIMIT 80";
    sc_select(rs_admin_collection_rows, $collectionRowsSql);
    if ({rs_admin_collection_rows} !== false) {
        while (!{rs_admin_collection_rows}->EOF) {
            $collectionRows[] = [
                'id' => (int) {rs_admin_collection_rows}->fields[0],
                'requester_name' => (string) {rs_admin_collection_rows}->fields[1],
                'requester_email' => (string) {rs_admin_collection_rows}->fields[2],
                'requester_phone' => (string) {rs_admin_collection_rows}->fields[3],
                'host_name' => (string) {rs_admin_collection_rows}->fields[4],
                'guard_handover_name' => (string) {rs_admin_collection_rows}->fields[5],
                'tracking_number' => (string) {rs_admin_collection_rows}->fields[6],
                'carrier_company' => (string) {rs_admin_collection_rows}->fields[7],
                'notes' => (string) {rs_admin_collection_rows}->fields[8],
                'status' => (string) {rs_admin_collection_rows}->fields[9],
                'registered_at' => (string) {rs_admin_collection_rows}->fields[10],
                'delivered_at' => (string) {rs_admin_collection_rows}->fields[11],
                'photo_count' => (int) {rs_admin_collection_rows}->fields[12],
                'delivered_to_name' => (string) {rs_admin_collection_rows}->fields[13],
                'notification_status' => (string) {rs_admin_collection_rows}->fields[14],
                'notification_sent_at' => (string) {rs_admin_collection_rows}->fields[15],
                'has_signature' => (int) {rs_admin_collection_rows}->fields[16] > 0,
                'pending_age_days' => (int) {rs_admin_collection_rows}->fields[17],
                'is_old_pending' => strtoupper((string) {rs_admin_collection_rows}->fields[9]) !== 'DELIVERED'
                    && (int) {rs_admin_collection_rows}->fields[17] >= $collectionAlertDays,
            ];
            {rs_admin_collection_rows}->MoveNext();
        }
        {rs_admin_collection_rows}->Close();
    }
}
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Control Entradas DRT</title>
  <style>
    :root {
      --bg: #f4f7fb;
      --card: #ffffff;
      --line: #d9e2ec;
      --text: #102133;
      --soft: #5b6b7d;
      --primary: #1f4fbf;
      --primary-soft: #e9f0ff;
      --success: #166534;
      --success-soft: #dcfce7;
      --warning: #92400e;
      --warning-soft: #fef3c7;
      --shadow: 0 12px 32px rgba(16, 33, 51, 0.08);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Plus Jakarta Sans", "Segoe UI", sans-serif;
      background: linear-gradient(180deg, #eef4ff 0%, var(--bg) 180px);
      color: var(--text);
    }
    .page {
      max-width: 1400px;
      margin: 0 auto;
      padding: 28px 20px 36px;
    }
    .hero {
      background: linear-gradient(135deg, #0f1d36 0%, #173a7a 100%);
      color: #fff;
      border-radius: 28px;
      padding: 26px;
      box-shadow: var(--shadow);
      margin-bottom: 20px;
    }
    .hero-header {
      display: flex;
      align-items: center;
      gap: 18px;
    }
    .hero-mark {
      width: 72px;
      height: 72px;
      border-radius: 22px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, rgba(255,255,255,0.24) 0%, rgba(255,255,255,0.08) 100%);
      border: 1px solid rgba(255,255,255,0.14);
      font-size: 24px;
      font-weight: 800;
      letter-spacing: 0.08em;
    }
    .hero-eyebrow {
      font-size: 12px;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: rgba(255,255,255,0.64);
      margin-bottom: 6px;
    }
    .hero h1 {
      margin: 0 0 8px;
      font-size: 30px;
    }
    .hero p {
      margin: 0;
      color: rgba(255,255,255,0.82);
    }
    .tabs {
      display: inline-flex;
      gap: 8px;
      margin-top: 18px;
      padding: 6px;
      border-radius: 18px;
      background: rgba(255,255,255,0.1);
    }
    .tab-link {
      text-decoration: none;
      color: rgba(255,255,255,0.82);
      font-weight: 700;
      padding: 11px 16px;
      border-radius: 14px;
      transition: 0.18s ease;
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }
    .tab-link.active {
      background: #fff;
      color: var(--primary);
    }
    .tab-count {
      min-width: 22px;
      height: 22px;
      padding: 0 7px;
      border-radius: 999px;
      background: #ffedd5;
      color: #9a3412;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      font-weight: 800;
      line-height: 1;
    }
    .tab-link.active .tab-count {
      background: #eef2ff;
      color: var(--primary);
    }
    .filters {
      margin-top: 18px;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
    }
    .filters input,
    .filters select,
    .filters button {
      width: 100%;
      border-radius: 16px;
      border: 1px solid rgba(255,255,255,0.16);
      padding: 13px 14px;
      font: inherit;
    }
    .filters input,
    .filters select {
      background: rgba(255,255,255,0.12);
      color: #fff;
    }
    .filters button {
      background: #fff;
      color: var(--primary);
      font-weight: 800;
      cursor: pointer;
      border: none;
    }
    .filters option {
      color: var(--text);
    }
    .hero-tip {
      margin-top: 12px;
      color: rgba(255,255,255,0.78);
      font-size: 13px;
    }
    .quick-actions {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 14px;
    }
    .quick-link {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 14px;
      border-radius: 14px;
      text-decoration: none;
      font-weight: 700;
      background: rgba(255,255,255,0.12);
      color: #fff;
      border: 1px solid rgba(255,255,255,0.14);
    }
    .quick-link.active {
      background: #fff;
      color: var(--primary);
    }
    .age-note {
      display: inline-flex;
      align-items: center;
      margin-top: 6px;
      font-size: 12px;
      font-weight: 700;
      color: #9a3412;
    }
    .row-alert td {
      background: #fff7ed;
    }
    .row-alert td:first-child {
      box-shadow: inset 4px 0 0 #f59e0b;
    }
    .cards {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 14px;
      margin-bottom: 18px;
    }
    .section-head {
      display: flex;
      align-items: end;
      justify-content: space-between;
      gap: 16px;
      margin: 8px 0 12px;
    }
    .section-head h2 {
      margin: 0;
      font-size: 22px;
    }
    .section-head p {
      margin: 4px 0 0;
      color: var(--soft);
      font-size: 14px;
    }
    .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 22px;
      padding: 20px;
      box-shadow: var(--shadow);
    }
    .card .label {
      color: var(--soft);
      font-size: 13px;
      margin-bottom: 8px;
    }
    .card .value {
      font-size: 30px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    .table-card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 24px;
      padding: 14px;
      box-shadow: var(--shadow);
      overflow: hidden;
    }
    .table-scroll {
      overflow: auto;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      min-width: 1200px;
    }
    th, td {
      padding: 13px 12px;
      border-bottom: 1px solid #eef2f7;
      vertical-align: top;
      text-align: left;
      font-size: 14px;
    }
    th {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      color: var(--soft);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      border-radius: 999px;
      padding: 6px 10px;
      font-size: 12px;
      font-weight: 700;
      white-space: nowrap;
    }
    .badge.primary { background: var(--primary-soft); color: var(--primary); }
    .badge.success { background: var(--success-soft); color: var(--success); }
    .badge.warning { background: var(--warning-soft); color: var(--warning); }
    .photo-btn {
      border: 1px solid var(--line);
      background: #fff;
      border-radius: 12px;
      padding: 8px 12px;
      font: inherit;
      font-weight: 700;
      color: var(--primary);
      cursor: pointer;
    }
    .photo-btn[disabled] {
      color: #8a97a6;
      cursor: not-allowed;
      background: #f8fafc;
    }
    .action-stack {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .note {
      background: #fff8e8;
      border: 1px solid #f3d9a5;
      border-radius: 18px;
      padding: 16px 18px;
      color: #7a5611;
      margin-top: 12px;
    }
    .muted {
      color: var(--soft);
    }
    .empty {
      padding: 36px 20px;
      text-align: center;
      color: var(--soft);
    }
    .modal {
      position: fixed;
      inset: 0;
      background: rgba(15, 23, 42, 0.62);
      display: none;
      align-items: center;
      justify-content: center;
      padding: 24px;
      z-index: 999;
    }
    .modal.open { display: flex; }
    .modal-card {
      width: min(900px, 100%);
      max-height: 90vh;
      overflow: auto;
      background: #fff;
      border-radius: 24px;
      padding: 18px;
      box-shadow: var(--shadow);
    }
    .modal-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
      gap: 12px;
    }
    .modal-head h2 {
      margin: 0;
      font-size: 22px;
    }
    .close-btn {
      border: none;
      background: #eef2f7;
      width: 38px;
      height: 38px;
      border-radius: 12px;
      cursor: pointer;
      font-size: 20px;
    }
    .photo-frame {
      border: 1px solid var(--line);
      border-radius: 18px;
      background: #f8fafc;
      min-height: 240px;
      padding: 14px;
    }
    .media-state {
      min-height: 210px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .media-gallery {
      display: none;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
    }
    .media-gallery img {
      max-width: 100%;
      max-height: 68vh;
      object-fit: contain;
      width: 100%;
      display: block;
      background: #fff;
      border: 1px solid var(--line);
      border-radius: 16px;
      padding: 8px;
    }
    .media-meta {
      display: none;
      margin-top: 12px;
      padding: 12px 14px;
      border-radius: 16px;
      background: #f3f7fd;
      color: var(--text);
    }
    @media (max-width: 980px) {
      .hero-header {
        align-items: flex-start;
        flex-direction: column;
      }
      .cards,
      .filters {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="page">
    <section class="hero">
      <div class="hero-header">
        <div class="hero-mark">DRT</div>
        <div>
          <div class="hero-eyebrow">Centro de Supervisión</div>
          <h1>Control Entradas DRT</h1>
          <p>Supervisa accesos, paquetería y recolección con filtros separados para que la consulta diaria sea más clara.</p>
        </div>
      </div>
      <div class="tabs">
        <a class="tab-link <?php echo $section === 'visits' ? 'active' : ''; ?>" href="<?php echo ra_admin_h(ra_admin_url(['section' => 'visits'])); ?>">
          <span>Visitas</span>
          <?php if ($visitInsideBubbleCount > 0) { ?>
            <span class="tab-count"><?php echo ra_admin_h($visitInsideBubbleCount); ?></span>
          <?php } ?>
        </a>
        <a class="tab-link <?php echo $section === 'packages' ? 'active' : ''; ?>" href="<?php echo ra_admin_h(ra_admin_url(['section' => 'packages'])); ?>">
          <span>Paquetería</span>
          <?php if ($packagePendingBubbleCount > 0) { ?>
            <span class="tab-count"><?php echo ra_admin_h($packagePendingBubbleCount); ?></span>
          <?php } ?>
        </a>
        <a class="tab-link <?php echo $section === 'collections' ? 'active' : ''; ?>" href="<?php echo ra_admin_h(ra_admin_url(['section' => 'collections'])); ?>">
          <span>Recolección</span>
          <?php if ($collectionPendingBubbleCount > 0) { ?>
            <span class="tab-count"><?php echo ra_admin_h($collectionPendingBubbleCount); ?></span>
          <?php } ?>
        </a>
      </div>
      <?php if ($section === 'visits') { ?>
        <form class="filters" method="get">
          <input type="hidden" name="section" value="visits">
          <input type="hidden" name="quick" value="<?php echo $quick === 'visits_inside_now' ? 'visits_inside_now' : ''; ?>">
          <input type="date" name="date_from" value="<?php echo ra_admin_h($dateFrom); ?>">
          <input type="date" name="date_to" value="<?php echo ra_admin_h($dateTo); ?>">
          <select name="visit_status">
            <option value="all" <?php echo $visitStatus === 'all' ? 'selected' : ''; ?>>Todas las visitas</option>
            <option value="inside" <?php echo $visitStatus === 'inside' ? 'selected' : ''; ?>>Solo dentro</option>
            <option value="completed" <?php echo $visitStatus === 'completed' ? 'selected' : ''; ?>>Solo con salida</option>
          </select>
          <input type="text" name="q" value="<?php echo ra_admin_h($search); ?>" placeholder="Buscar visitante, anfitrion, motivo o notas">
          <button type="submit">Actualizar</button>
        </form>
        <div class="quick-actions">
          <a
            class="quick-link <?php echo $quick === 'visits_inside_now' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'visits',
                'quick' => 'visits_inside_now',
                'date_preset' => null,
                'visit_status' => 'inside',
                'q' => null,
            ])); ?>"
          >
            Ver los que siguen dentro
          </a>
          <a
            class="quick-link <?php echo $datePreset === 'today' && $quick === '' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'visits',
                'quick' => null,
                'date_preset' => 'today',
                'visit_status' => 'all',
                'q' => null,
            ])); ?>"
          >
            Hoy
          </a>
          <a
            class="quick-link <?php echo $datePreset === '7d' && $quick === '' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'visits',
                'quick' => null,
                'date_preset' => '7d',
                'visit_status' => 'all',
                'q' => null,
            ])); ?>"
          >
            7 días
          </a>
          <a
            class="quick-link <?php echo $datePreset === '30d' && $quick === '' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'visits',
                'quick' => null,
                'date_preset' => '30d',
                'visit_status' => 'all',
                'q' => null,
            ])); ?>"
          >
            30 días
          </a>
          <a
            class="quick-link <?php echo $quick === '' && $datePreset === '' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'visits',
                'quick' => null,
                'date_preset' => null,
                'visit_status' => 'all',
                'q' => null,
            ])); ?>"
          >
            Volver a rango por fecha
          </a>
        </div>
        <div class="hero-tip">Se resalta en ámbar quien lleva más de 1 día dentro.</div>
      <?php } elseif ($section === 'packages') { ?>
        <form class="filters" method="get">
          <input type="hidden" name="section" value="packages">
          <input type="hidden" name="quick" value="<?php echo $quick === 'packages_pending_all' ? 'packages_pending_all' : ''; ?>">
          <select name="package_status">
            <option value="pending" <?php echo $packageStatus === 'pending' ? 'selected' : ''; ?>>Pendientes</option>
            <option value="delivered" <?php echo $packageStatus === 'delivered' ? 'selected' : ''; ?>>Entregados</option>
          </select>
          <select name="package_contact_filter">
            <option value="all" <?php echo $packageContactFilter === 'all' ? 'selected' : ''; ?>>Todos los contactos</option>
            <option value="missing_phone" <?php echo $packageContactFilter === 'missing_phone' ? 'selected' : ''; ?>>Sin WhatsApp</option>
            <option value="missing_email" <?php echo $packageContactFilter === 'missing_email' ? 'selected' : ''; ?>>Sin correo</option>
            <option value="missing_contact" <?php echo $packageContactFilter === 'missing_contact' ? 'selected' : ''; ?>>Sin contacto</option>
            <option value="phone" <?php echo $packageContactFilter === 'phone' ? 'selected' : ''; ?>>Con WhatsApp</option>
            <option value="email" <?php echo $packageContactFilter === 'email' ? 'selected' : ''; ?>>Con correo</option>
          </select>
          <input type="date" name="date_from" value="<?php echo ra_admin_h($dateFrom); ?>">
          <input type="date" name="date_to" value="<?php echo ra_admin_h($dateTo); ?>">
          <input type="text" name="q" value="<?php echo ra_admin_h($search); ?>" placeholder="Buscar destinatario, correo, paquetería o notas">
          <button type="submit">Actualizar</button>
        </form>
        <div class="quick-actions">
          <a
            class="quick-link <?php echo $packageStatus === 'pending' && $packageContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'packages',
                'quick' => 'packages_pending_all',
                'date_preset' => null,
                'package_status' => 'pending',
                'package_contact_filter' => 'all',
                'q' => null,
            ])); ?>"
          >
            Ver pendientes sin fecha
          </a>
          <a
            class="quick-link <?php echo $packageStatus === 'pending' && $packageContactFilter === 'missing_phone' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'packages',
                'quick' => 'packages_pending_all',
                'package_status' => 'pending',
                'package_contact_filter' => 'missing_phone',
                'q' => null,
            ])); ?>"
          >
            Sin WhatsApp
          </a>
          <a
            class="quick-link <?php echo $packageStatus === 'pending' && $packageContactFilter === 'missing_contact' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'packages',
                'quick' => 'packages_pending_all',
                'package_status' => 'pending',
                'package_contact_filter' => 'missing_contact',
                'q' => null,
            ])); ?>"
          >
            Sin contacto
          </a>
          <a
            class="quick-link <?php echo $packageStatus === 'delivered' && $datePreset === 'today' && $packageContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'packages',
                'quick' => null,
                'package_status' => 'delivered',
                'package_contact_filter' => 'all',
                'date_preset' => 'today',
                'q' => null,
            ])); ?>"
          >
            Hoy
          </a>
          <a
            class="quick-link <?php echo $packageStatus === 'delivered' && $datePreset === '7d' && $packageContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'packages',
                'quick' => null,
                'package_status' => 'delivered',
                'package_contact_filter' => 'all',
                'date_preset' => '7d',
                'q' => null,
            ])); ?>"
          >
            7 días
          </a>
          <a
            class="quick-link <?php echo $packageStatus === 'delivered' && $datePreset === '30d' && $packageContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'packages',
                'quick' => null,
                'package_status' => 'delivered',
                'package_contact_filter' => 'all',
                'date_preset' => '30d',
                'q' => null,
            ])); ?>"
          >
            30 días
          </a>
          <a
            class="quick-link <?php echo $packageStatus === 'delivered' && $datePreset === '' && $packageContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'packages',
                'quick' => null,
                'package_status' => 'delivered',
                'package_contact_filter' => 'all',
                'date_preset' => null,
                'q' => null,
            ])); ?>"
          >
            Ver entregados por fecha
          </a>
        </div>
        <div class="hero-tip">
          <?php echo $packageStatus === 'pending'
              ? 'Pendientes muestra todos los paquetes sin entregar, aunque no sean del mismo día. Se resalta en ámbar lo pendiente por más de ' . $packageAlertDays . ' días. El aviso prioriza WhatsApp y cae a correo si hace falta.'
              : 'Entregados usa el rango de fechas para auditar entregas pasadas.'; ?>
        </div>
      <?php } else { ?>
        <form class="filters" method="get">
          <input type="hidden" name="section" value="collections">
          <input type="hidden" name="quick" value="<?php echo $quick === 'collections_pending_all' ? 'collections_pending_all' : ''; ?>">
          <select name="collection_status">
            <option value="pending" <?php echo $collectionStatus === 'pending' ? 'selected' : ''; ?>>Pendientes</option>
            <option value="delivered" <?php echo $collectionStatus === 'delivered' ? 'selected' : ''; ?>>Entregadas</option>
          </select>
          <select name="collection_contact_filter">
            <option value="all" <?php echo $collectionContactFilter === 'all' ? 'selected' : ''; ?>>Todos los contactos</option>
            <option value="missing_phone" <?php echo $collectionContactFilter === 'missing_phone' ? 'selected' : ''; ?>>Sin WhatsApp</option>
            <option value="missing_email" <?php echo $collectionContactFilter === 'missing_email' ? 'selected' : ''; ?>>Sin correo</option>
            <option value="missing_contact" <?php echo $collectionContactFilter === 'missing_contact' ? 'selected' : ''; ?>>Sin contacto</option>
            <option value="phone" <?php echo $collectionContactFilter === 'phone' ? 'selected' : ''; ?>>Con WhatsApp</option>
            <option value="email" <?php echo $collectionContactFilter === 'email' ? 'selected' : ''; ?>>Con correo</option>
          </select>
          <input type="date" name="date_from" value="<?php echo ra_admin_h($dateFrom); ?>">
          <input type="date" name="date_to" value="<?php echo ra_admin_h($dateTo); ?>">
          <input type="text" name="q" value="<?php echo ra_admin_h($search); ?>" placeholder="Buscar solicitante, guía, WhatsApp o notas">
          <button type="submit">Actualizar</button>
        </form>
        <div class="quick-actions">
          <a
            class="quick-link <?php echo $collectionStatus === 'pending' && $collectionContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'collections',
                'quick' => 'collections_pending_all',
                'date_preset' => null,
                'collection_status' => 'pending',
                'collection_contact_filter' => 'all',
                'q' => null,
            ])); ?>"
          >
            Ver pendientes sin fecha
          </a>
          <a
            class="quick-link <?php echo $collectionStatus === 'pending' && $collectionContactFilter === 'missing_phone' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'collections',
                'quick' => 'collections_pending_all',
                'collection_status' => 'pending',
                'collection_contact_filter' => 'missing_phone',
                'q' => null,
            ])); ?>"
          >
            Sin WhatsApp
          </a>
          <a
            class="quick-link <?php echo $collectionStatus === 'pending' && $collectionContactFilter === 'missing_contact' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'collections',
                'quick' => 'collections_pending_all',
                'collection_status' => 'pending',
                'collection_contact_filter' => 'missing_contact',
                'q' => null,
            ])); ?>"
          >
            Sin contacto
          </a>
          <a
            class="quick-link <?php echo $collectionStatus === 'delivered' && $datePreset === 'today' && $collectionContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'collections',
                'quick' => null,
                'collection_status' => 'delivered',
                'collection_contact_filter' => 'all',
                'date_preset' => 'today',
                'q' => null,
            ])); ?>"
          >
            Hoy
          </a>
          <a
            class="quick-link <?php echo $collectionStatus === 'delivered' && $datePreset === '7d' && $collectionContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'collections',
                'quick' => null,
                'collection_status' => 'delivered',
                'collection_contact_filter' => 'all',
                'date_preset' => '7d',
                'q' => null,
            ])); ?>"
          >
            7 días
          </a>
          <a
            class="quick-link <?php echo $collectionStatus === 'delivered' && $datePreset === '30d' && $collectionContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'collections',
                'quick' => null,
                'collection_status' => 'delivered',
                'collection_contact_filter' => 'all',
                'date_preset' => '30d',
                'q' => null,
            ])); ?>"
          >
            30 días
          </a>
          <a
            class="quick-link <?php echo $collectionStatus === 'delivered' && $datePreset === '' && $collectionContactFilter === 'all' ? 'active' : ''; ?>"
            href="<?php echo ra_admin_h(ra_admin_url([
                'section' => 'collections',
                'quick' => null,
                'collection_status' => 'delivered',
                'collection_contact_filter' => 'all',
                'date_preset' => null,
                'q' => null,
            ])); ?>"
          >
            Ver entregadas por fecha
          </a>
        </div>
        <div class="hero-tip">
          <?php echo $collectionStatus === 'pending'
              ? 'Pendientes muestra todas las solicitudes sin entregar. Se resalta en ámbar lo pendiente por más de ' . $collectionAlertDays . ' días. El aviso prioriza WhatsApp y cae a correo si hace falta.'
              : 'Entregadas usa el rango de fechas para auditar recolecciones pasadas.'; ?>
        </div>
      <?php } ?>
    </section>

    <?php if ($section === 'visits') { ?>
    <div class="section-head">
      <div>
        <h2>Visitas</h2>
        <p><?php echo $quick === 'visits_inside_now'
            ? 'Lista de quienes siguen dentro en este momento, sin importar la fecha de entrada.'
            : 'Entradas, salidas, tiempo dentro y foto del documento dentro del rango seleccionado.'; ?></p>
      </div>
    </div>
    <section class="cards">
      <?php foreach ($cards as $card) { ?>
        <article class="card">
          <div class="label"><?php echo ra_admin_h($card['label']); ?></div>
          <div class="value"><?php echo ra_admin_h($card['value']); ?></div>
        </article>
      <?php } ?>
    </section>

    <section class="table-card">
      <div class="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Visitante</th>
              <th>Anfitrion</th>
              <th>Cita</th>
              <th>Personas</th>
              <th>Motivo</th>
              <th>Observaciones</th>
              <th>Entrada</th>
              <th>Salida</th>
              <th>Tiempo dentro</th>
              <th>Estatus</th>
              <th>Foto</th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($rows)) { ?>
              <tr>
                <td colspan="11" class="empty">
                  <?php echo $quick === 'visits_inside_now'
                      ? 'No hay personas dentro en este momento.'
                      : 'No hay visitas para el filtro actual.'; ?>
                </td>
              </tr>
            <?php } ?>
            <?php foreach ($rows as $row) { ?>
              <tr class="<?php echo $row['is_long_inside'] ? 'row-alert' : ''; ?>">
                <td>
                  <strong><?php echo ra_admin_h($row['full_name']); ?></strong>
                </td>
                <td><?php echo ra_admin_h($row['host_name']); ?></td>
                <td>
                  <span class="badge <?php echo $row['has_appointment'] ? 'success' : 'warning'; ?>">
                    <?php echo $row['has_appointment'] ? 'Si' : 'No'; ?>
                  </span>
                </td>
                <td><?php echo ra_admin_h($row['group_size'] == 1 ? '1 persona' : $row['group_size'] . ' personas'); ?></td>
                <td><?php echo ra_admin_h($row['purpose']); ?></td>
                <td class="muted"><?php echo ra_admin_h($row['observations'] !== '' ? $row['observations'] : 'Sin observaciones'); ?></td>
                <td><?php echo ra_admin_h(ra_admin_format_datetime($row['entered_at'])); ?></td>
                <td><?php echo ra_admin_h($row['checked_out_at'] !== '' ? ra_admin_format_datetime($row['checked_out_at']) : 'Dentro'); ?></td>
                <td>
                  <?php echo ra_admin_h(ra_admin_format_minutes($row['duration_minutes'])); ?>
                  <?php if ($row['is_long_inside']) { ?>
                    <span class="age-note">Más de 1 día dentro</span>
                  <?php } ?>
                </td>
                <td>
                  <span class="badge <?php echo $row['checked_out_at'] === '' ? 'primary' : 'success'; ?>">
                    <?php echo ra_admin_h(ra_admin_status_label($row['checked_out_at'])); ?>
                  </span>
                </td>
                <td>
                  <button
                    type="button"
                    class="photo-btn"
                    <?php echo $row['has_photo'] ? '' : 'disabled'; ?>
                    onclick='openPhoto(<?php echo (int) $row["id"]; ?>, <?php echo json_encode($row["full_name"], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT); ?>)'
                  >
                    <?php echo $row['has_photo'] ? 'Ver foto' : 'Sin foto'; ?>
                  </button>
                </td>
              </tr>
            <?php } ?>
          </tbody>
        </table>
      </div>
    </section>
    <?php } ?>

    <?php if ($section === 'packages') { ?>
    <div class="section-head" style="margin-top: 26px;">
      <div>
        <h2>Paquetería</h2>
        <p><?php echo $packageStatus === 'pending'
            ? 'Lista de todos los paquetes pendientes, con su fecha de recepción y evidencia.'
            : 'Lista de paquetes entregados dentro del rango elegido, con firma y evidencia.'; ?></p>
      </div>
    </div>

    <section class="cards">
      <?php foreach ($packageCards as $card) { ?>
        <article class="card">
          <div class="label"><?php echo ra_admin_h($card['label']); ?></div>
          <div class="value"><?php echo ra_admin_h($card['value']); ?></div>
        </article>
      <?php } ?>
    </section>

    <section class="table-card">
      <?php if ($packageSchemaMessage !== '') { ?>
        <div class="note"><?php echo ra_admin_h($packageSchemaMessage); ?></div>
      <?php } else { ?>
        <div class="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Destinatario</th>
                <th>WhatsApp</th>
                <th>Correo</th>
                <th>Guía</th>
                <th>Paquetería</th>
                <th>Piezas</th>
                <th>Vigilante</th>
                <th>Recepción</th>
                <th>Notificación</th>
                <th>Entrega</th>
                <th>Estatus</th>
                <th>Evidencia</th>
              </tr>
            </thead>
            <tbody>
              <?php if (empty($packageRows)) { ?>
                <tr>
                  <td colspan="12" class="empty">
                    <?php echo $packageStatus === 'pending'
                        ? 'No hay paquetes pendientes para mostrar.'
                        : 'No hay paquetes entregados en el rango seleccionado.'; ?>
                  </td>
                </tr>
              <?php } ?>
              <?php foreach ($packageRows as $row) { ?>
              <tr class="<?php echo $row['is_old_pending'] ? 'row-alert' : ''; ?>">
                <td>
                  <strong><?php echo ra_admin_h($row['recipient_name']); ?></strong><br>
                    <span class="muted"><?php echo ra_admin_h($row['host_name']); ?></span>
                </td>
                  <td><?php echo ra_admin_h($row['recipient_phone'] !== '' ? $row['recipient_phone'] : 'Sin WhatsApp'); ?></td>
                  <td><?php echo ra_admin_h($row['recipient_email'] !== '' ? $row['recipient_email'] : 'Sin correo'); ?></td>
                  <td><?php echo ra_admin_h($row['tracking_number'] !== '' ? $row['tracking_number'] : 'Sin guia'); ?></td>
                  <td><?php echo ra_admin_h($row['carrier_company'] !== '' ? $row['carrier_company'] : 'Sin paquetería'); ?></td>
                  <td><?php echo ra_admin_h($row['package_count'] == 1 ? '1 pieza' : $row['package_count'] . ' piezas'); ?></td>
                  <td><?php echo ra_admin_h($row['guard_received_name'] !== '' ? $row['guard_received_name'] : 'Sin vigilante'); ?></td>
                  <td>
                    <?php echo ra_admin_h(ra_admin_format_datetime($row['received_at'])); ?>
                    <?php if ($row['is_old_pending']) { ?>
                      <span class="age-note"><?php echo ra_admin_h($row['pending_age_days'] . ' días pendiente'); ?></span>
                    <?php } ?>
                  </td>
                  <td>
                    <span class="badge <?php echo ra_admin_notification_class($row['notification_status']); ?>">
                      <?php echo ra_admin_h(ra_admin_notification_label($row['notification_status'])); ?>
                    </span>
                    <?php if ($row['notified_at'] !== '') { ?><br><span class="muted"><?php echo ra_admin_h(ra_admin_format_datetime($row['notified_at'])); ?></span><?php } ?>
                  </td>
                  <td>
                    <?php if ($row['delivered_at'] !== '') { ?>
                      <strong><?php echo ra_admin_h(ra_admin_format_datetime($row['delivered_at'])); ?></strong><br>
                      <span class="muted"><?php echo ra_admin_h($row['received_by_name'] !== '' ? $row['received_by_name'] : 'Sin nombre'); ?></span>
                    <?php } else { ?>
                      <span class="muted">Pendiente</span>
                    <?php } ?>
                  </td>
                  <td>
                    <span class="badge <?php echo ra_admin_package_status_class($row['status']); ?>">
                      <?php echo ra_admin_h(ra_admin_package_status_label($row['status'])); ?>
                    </span>
                  </td>
                  <td>
                    <div class="action-stack">
                      <button
                        type="button"
                        class="photo-btn"
                        <?php echo $row['photo_count'] > 0 ? '' : 'disabled'; ?>
                        onclick='openPackagePhotos(<?php echo (int) $row["id"]; ?>, <?php echo json_encode($row["recipient_name"], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT); ?>)'
                      >
                        <?php echo $row['photo_count'] > 0 ? 'Ver fotos' : 'Sin fotos'; ?>
                      </button>
                      <button
                        type="button"
                        class="photo-btn"
                        <?php echo $row['has_signature'] ? '' : 'disabled'; ?>
                        onclick='openPackageSignature(<?php echo (int) $row["id"]; ?>, <?php echo json_encode($row["recipient_name"], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT); ?>)'
                      >
                        <?php echo $row['has_signature'] ? 'Ver firma' : 'Sin firma'; ?>
                      </button>
                    </div>
                  </td>
                </tr>
              <?php } ?>
            </tbody>
          </table>
        </div>
      <?php } ?>
    </section>
    <?php } ?>

    <?php if ($section === 'collections') { ?>
    <div class="section-head" style="margin-top: 26px;">
      <div>
        <h2>Recolección</h2>
        <p><?php echo $collectionStatus === 'pending'
            ? 'Lista de solicitudes pendientes, con fecha de registro, contacto y evidencia.'
            : 'Lista de recolecciones entregadas dentro del rango elegido, con firma y aviso.'; ?></p>
      </div>
    </div>

    <section class="cards">
      <?php foreach ($collectionCards as $card) { ?>
        <article class="card">
          <div class="label"><?php echo ra_admin_h($card['label']); ?></div>
          <div class="value"><?php echo ra_admin_h($card['value']); ?></div>
        </article>
      <?php } ?>
    </section>

    <section class="table-card">
      <?php if ($collectionSchemaMessage !== '') { ?>
        <div class="note"><?php echo ra_admin_h($collectionSchemaMessage); ?></div>
      <?php } else { ?>
        <div class="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Solicita</th>
                <th>Correo</th>
                <th>WhatsApp</th>
                <th>Guía</th>
                <th>Recolector</th>
                <th>Vigilante</th>
                <th>Registro</th>
                <th>Notificación</th>
                <th>Entrega</th>
                <th>Estatus</th>
                <th>Evidencia</th>
              </tr>
            </thead>
            <tbody>
              <?php if (empty($collectionRows)) { ?>
                <tr>
                  <td colspan="11" class="empty">
                    <?php echo $collectionStatus === 'pending'
                        ? 'No hay recolecciones pendientes para mostrar.'
                        : 'No hay recolecciones entregadas en el rango seleccionado.'; ?>
                  </td>
                </tr>
              <?php } ?>
              <?php foreach ($collectionRows as $row) { ?>
                <tr class="<?php echo $row['is_old_pending'] ? 'row-alert' : ''; ?>">
                  <td>
                    <strong><?php echo ra_admin_h($row['requester_name']); ?></strong><br>
                    <span class="muted"><?php echo ra_admin_h($row['host_name']); ?></span>
                  </td>
                  <td><?php echo ra_admin_h($row['requester_email'] !== '' ? $row['requester_email'] : 'Sin correo'); ?></td>
                  <td><?php echo ra_admin_h($row['requester_phone'] !== '' ? $row['requester_phone'] : 'Sin WhatsApp'); ?></td>
                  <td><?php echo ra_admin_h($row['tracking_number'] !== '' ? $row['tracking_number'] : 'Sin guía'); ?></td>
                  <td><?php echo ra_admin_h($row['carrier_company'] !== '' ? $row['carrier_company'] : 'Sin recolector'); ?></td>
                  <td><?php echo ra_admin_h($row['guard_handover_name'] !== '' ? $row['guard_handover_name'] : 'Sin vigilante'); ?></td>
                  <td>
                    <?php echo ra_admin_h(ra_admin_format_datetime($row['registered_at'])); ?>
                    <?php if ($row['is_old_pending']) { ?>
                      <span class="age-note"><?php echo ra_admin_h($row['pending_age_days'] . ' días pendiente'); ?></span>
                    <?php } ?>
                  </td>
                  <td>
                    <span class="badge <?php echo ra_admin_notification_class($row['notification_status']); ?>">
                      <?php echo ra_admin_h(ra_admin_notification_label($row['notification_status'])); ?>
                    </span>
                    <?php if ($row['notification_sent_at'] !== '') { ?><br><span class="muted"><?php echo ra_admin_h(ra_admin_format_datetime($row['notification_sent_at'])); ?></span><?php } ?>
                  </td>
                  <td>
                    <?php if ($row['delivered_at'] !== '') { ?>
                      <strong><?php echo ra_admin_h(ra_admin_format_datetime($row['delivered_at'])); ?></strong><br>
                      <span class="muted"><?php echo ra_admin_h($row['delivered_to_name'] !== '' ? $row['delivered_to_name'] : 'Sin nombre'); ?></span>
                    <?php } else { ?>
                      <span class="muted">Pendiente</span>
                    <?php } ?>
                  </td>
                  <td>
                    <span class="badge <?php echo ra_admin_collection_status_class($row['status']); ?>">
                      <?php echo ra_admin_h(ra_admin_collection_status_label($row['status'])); ?>
                    </span>
                  </td>
                  <td>
                    <div class="action-stack">
                      <button
                        type="button"
                        class="photo-btn"
                        <?php echo $row['photo_count'] > 0 ? '' : 'disabled'; ?>
                        onclick='openCollectionPhotos(<?php echo (int) $row["id"]; ?>, <?php echo json_encode($row["requester_name"], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT); ?>)'
                      >
                        <?php echo $row['photo_count'] > 0 ? 'Ver fotos' : 'Sin fotos'; ?>
                      </button>
                      <button
                        type="button"
                        class="photo-btn"
                        <?php echo $row['has_signature'] ? '' : 'disabled'; ?>
                        onclick='openCollectionSignature(<?php echo (int) $row["id"]; ?>, <?php echo json_encode($row["requester_name"], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT); ?>)'
                      >
                        <?php echo $row['has_signature'] ? 'Ver firma' : 'Sin firma'; ?>
                      </button>
                    </div>
                  </td>
                </tr>
              <?php } ?>
            </tbody>
          </table>
        </div>
      <?php } ?>
    </section>
    <?php } ?>
  </div>

  <div class="modal" id="photoModal" onclick="closePhoto(event)">
    <div class="modal-card" onclick="event.stopPropagation()">
      <div class="modal-head">
        <h2 id="photoTitle">Evidencia</h2>
        <button class="close-btn" type="button" onclick="closePhoto()">×</button>
      </div>
      <div class="photo-frame">
        <div id="photoState" class="muted media-state">Selecciona un registro para ver la evidencia.</div>
        <div id="photoGallery" class="media-gallery"></div>
      </div>
      <div id="photoMeta" class="media-meta"></div>
    </div>
  </div>

  <script>
    function buildDashboardUrl(extraParams) {
      const basePath = window.location.pathname.endsWith('.htm')
        ? window.location.pathname.replace(/\.htm$/, '.php')
        : window.location.pathname;
      const url = new URL(basePath, window.location.origin);
      Object.entries(extraParams).forEach(([key, value]) => {
        url.searchParams.set(key, value);
      });
      return url.toString();
    }

    function resetMediaModal(titleText) {
      const modal = document.getElementById('photoModal');
      const gallery = document.getElementById('photoGallery');
      const state = document.getElementById('photoState');
      const title = document.getElementById('photoTitle');
      const meta = document.getElementById('photoMeta');

      title.textContent = titleText;
      gallery.innerHTML = '';
      gallery.style.display = 'none';
      state.style.display = 'flex';
      state.textContent = 'Cargando evidencia...';
      meta.style.display = 'none';
      meta.textContent = '';
      modal.classList.add('open');
    }

    function renderMedia(images, emptyMessage) {
      const gallery = document.getElementById('photoGallery');
      const state = document.getElementById('photoState');
      gallery.innerHTML = '';

      if (!images || images.length === 0) {
        state.style.display = 'flex';
        state.textContent = emptyMessage;
        gallery.style.display = 'none';
        return;
      }

      images.forEach((item, index) => {
        if (!item || !item.base64) {
          return;
        }
        const wrapper = document.createElement('div');
        const image = document.createElement('img');
        image.alt = item.label || ('Evidencia ' + (index + 1));
        image.src = 'data:' + (item.mimeType || 'image/jpeg') + ';base64,' + item.base64;
        wrapper.appendChild(image);
        gallery.appendChild(wrapper);
      });

      if (!gallery.children.length) {
        state.style.display = 'flex';
        state.textContent = emptyMessage;
        gallery.style.display = 'none';
        return;
      }

      state.style.display = 'none';
      gallery.style.display = 'grid';
    }

    async function openPhoto(visitId, fullName) {
      resetMediaModal('Documento de ' + fullName);

      try {
        const response = await fetch(buildDashboardUrl({
          mode: 'photo',
          visit_id: visitId
        }), {
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });
        const payload = await response.json();
        if (!payload.ok || !payload.data || !payload.data.image_base64) {
          renderMedia([], 'No hay foto disponible para esta visita.');
          return;
        }
        renderMedia([
          {
            base64: payload.data.image_base64,
            label: 'Documento',
            mimeType: payload.data.mime_type || 'image/jpeg'
          }
        ], 'No hay foto disponible para esta visita.');
      } catch (error) {
        renderMedia([], 'No se pudo cargar la foto.');
      }
    }

    async function openPackagePhotos(packageId, recipientName) {
      resetMediaModal('Fotos del paquete de ' + recipientName);

      try {
        const response = await fetch(buildDashboardUrl({
          mode: 'package_photos',
          package_id: packageId
        }), {
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });
        const payload = await response.json();
        if (!payload.ok || !payload.data) {
          renderMedia([], 'No se pudieron cargar las fotos del paquete.');
          return;
        }

        const photos = (payload.data.photos || []).map((item, index) => ({
          base64: item.image_base64 || '',
          label: 'Foto ' + (index + 1),
          mimeType: item.mime_type || 'image/jpeg'
        }));
        renderMedia(photos, 'No hay fotos disponibles para este paquete.');
      } catch (error) {
        renderMedia([], 'No se pudieron cargar las fotos del paquete.');
      }
    }

    async function openPackageSignature(packageId, recipientName) {
      resetMediaModal('Firma de entrega de ' + recipientName);

      try {
        const response = await fetch(buildDashboardUrl({
          mode: 'package_signature',
          package_id: packageId
        }), {
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });
        const payload = await response.json();
        if (!payload.ok || !payload.data || !payload.data.signature_base64) {
          renderMedia([], 'No hay firma disponible para este paquete.');
          return;
        }

        renderMedia([
          {
            base64: payload.data.signature_base64,
            label: 'Firma',
            mimeType: payload.data.mime_type || 'image/png'
          }
        ], 'No hay firma disponible para este paquete.');

        const meta = document.getElementById('photoMeta');
        meta.innerHTML =
          '<strong>Recibió:</strong> ' + (payload.data.received_by_name || 'Sin nombre') +
          '<br><strong>Entregado:</strong> ' + (payload.data.delivered_at || 'No disponible');
        meta.style.display = 'block';
      } catch (error) {
        renderMedia([], 'No se pudo cargar la firma.');
      }
    }

    async function openCollectionPhotos(collectionId, requesterName) {
      resetMediaModal('Fotos de recolección de ' + requesterName);

      try {
        const response = await fetch(buildDashboardUrl({
          mode: 'collection_photos',
          collection_id: collectionId
        }), {
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });
        const payload = await response.json();
        if (!payload.ok || !payload.data) {
          renderMedia([], 'No se pudieron cargar las fotos de la recolección.');
          return;
        }

        const photos = (payload.data.photos || []).map((item, index) => ({
          base64: item.image_base64 || '',
          label: 'Foto ' + (index + 1),
          mimeType: item.mime_type || 'image/jpeg'
        }));
        renderMedia(photos, 'No hay fotos disponibles para esta recolección.');
      } catch (error) {
        renderMedia([], 'No se pudieron cargar las fotos de la recolección.');
      }
    }

    async function openCollectionSignature(collectionId, requesterName) {
      resetMediaModal('Firma de entrega de recolección de ' + requesterName);

      try {
        const response = await fetch(buildDashboardUrl({
          mode: 'collection_signature',
          collection_id: collectionId
        }), {
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });
        const payload = await response.json();
        if (!payload.ok || !payload.data || !payload.data.signature_base64) {
          renderMedia([], 'No hay firma disponible para esta recolección.');
          return;
        }

        renderMedia([
          {
            base64: payload.data.signature_base64,
            label: 'Firma',
            mimeType: payload.data.mime_type || 'image/png'
          }
        ], 'No hay firma disponible para esta recolección.');

        const meta = document.getElementById('photoMeta');
        meta.innerHTML =
          '<strong>Recibió:</strong> ' + (payload.data.received_by_name || 'Sin nombre') +
          '<br><strong>Entregado:</strong> ' + (payload.data.delivered_at || 'No disponible');
        meta.style.display = 'block';
      } catch (error) {
        renderMedia([], 'No se pudo cargar la firma.');
      }
    }

    function closePhoto(event) {
      if (event && event.target && event.target.id && event.target.id !== 'photoModal') {
        return;
      }
      document.getElementById('photoModal').classList.remove('open');
    }
  </script>
</body>
</html>
