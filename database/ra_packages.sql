create table ra_packages
(
    id                       bigint auto_increment
        primary key,
    host_id                  bigint                                not null,
    guard_received_id        bigint                                null,
    guard_delivered_id       bigint                                null,
    recipient_name_snapshot  varchar(160)                          not null,
    recipient_email_snapshot varchar(160)                          null,
    recipient_phone_snapshot unknown null,
    brought_by_name          varchar(160)                          not null,
    tracking_number unknown null,
    carrier_company          varchar(160)                          null,
    package_count            int         default 1                 not null,
    notes                    varchar(255)                          null,
    status                   varchar(30) default 'RECEIVED'        not null,
    received_at              datetime                              not null,
    notified_at              datetime                              null,
    delivered_at             datetime                              null,
    created_at               datetime    default CURRENT_TIMESTAMP not null,
    updated_at               datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint fk_ra_packages_guard_delivered
        foreign key (guard_delivered_id) references ra_guards (id)
            on update cascade on delete set null,
    constraint fk_ra_packages_guard_received
        foreign key (guard_received_id) references ra_guards (id)
            on update cascade on delete set null,
    constraint fk_ra_packages_host
        foreign key (host_id) references ra_hosts (id)
            on update cascade
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_packages_delivered_at
    on ra_packages (delivered_at);

create index idx_ra_packages_host
    on ra_packages (host_id);

create index idx_ra_packages_status_received_at
    on ra_packages (status, received_at);

INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 3, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', null, 'amazon', null, 'dksksxm', 1, null, 'DELIVERED', '2026-03-24 12:28:59', '2026-03-24 12:29:02', '2026-03-24 13:06:50', '2026-03-24 12:28:59', '2026-03-26 08:43:06');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (4, 7, null, 'Abraham Escamilla', 'aescamilla@drt.com.mx', null, 'pedro hernandez', null, 'DHL', 1, 'guía dofkejeekk3423', 'DELIVERED', '2026-03-24 12:55:26', '2026-03-24 12:55:29', '2026-03-24 12:57:18', '2026-03-24 12:55:26', '2026-03-24 12:57:18');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 7, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', null, 'dkdkdk', null, 'AMAZON', 3, null, 'DELIVERED', '2026-03-24 14:02:00', '2026-03-24 14:02:02', '2026-03-26 08:38:00', '2026-03-24 14:02:00', '2026-03-26 08:43:51');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (4, 3, null, 'Abraham Escamilla', 'aescamilla@drt.com.mx', null, 'Anonimo', null, 'OTRO', 1, null, 'DELIVERED', '2026-03-26 10:06:14', '2026-03-26 10:06:18', '2026-03-26 10:10:50', '2026-03-26 10:06:14', '2026-03-26 10:10:50');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (4, 5, null, 'Abraham Escamilla', 'aescamilla@drt.com.mx', null, '123456789', null, null, 1, null, 'DELIVERED', '2026-03-26 10:39:54', '2026-03-26 10:39:56', '2026-03-26 10:40:50', '2026-03-26 10:39:54', '2026-03-26 10:40:50');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 3, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, 'G4WH35NBE', 'ESTAFETA', 1, null, 'DELIVERED', '2026-03-26 13:36:07', null, '2026-03-26 13:41:49', '2026-03-26 13:36:07', '2026-03-26 13:41:49');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 5, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, 'DDEE3JXX8M', 'ENVIAME', 1, null, 'DELIVERED', '2026-03-26 13:37:58', '2026-03-26 13:38:00', '2026-03-26 13:41:28', '2026-03-26 13:37:58', '2026-03-26 13:41:28');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 5, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, 'FII83CDC', 'LIVERPOOL', 1, null, 'NOTIFIED', '2026-03-26 13:40:58', '2026-03-26 13:40:59', null, '2026-03-26 13:40:58', '2026-03-26 13:40:59');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (4, 3, null, 'Abraham Escamilla', 'aescamilla@drt.com.mx', '4425956615', null, '123456789', 'DHL', 1, null, 'NOTIFIED', '2026-03-26 15:09:33', '2026-03-26 15:09:34', null, '2026-03-26 15:09:33', '2026-03-26 15:09:34');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (4, 4, null, 'Abraham Escamilla', 'aescamilla@drt.com.mx', '4425956615', null, '123456789', 'DHL', 1, null, 'DELIVERED', '2026-03-26 15:11:01', '2026-03-26 15:11:01', '2026-03-26 16:35:48', '2026-03-26 15:11:01', '2026-03-26 16:35:48');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 4, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, 'BCNSFNT', 'LIVERPOOL', 3, null, 'NOTIFIED', '2026-03-27 09:01:25', '2026-03-27 09:01:26', null, '2026-03-27 09:01:25', '2026-03-27 09:01:26');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 4, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, 'DE DC VE DE C', 'PAQUETEXPRESS', 1, null, 'NOTIFIED', '2026-03-27 11:23:50', '2026-03-27 11:23:52', null, '2026-03-27 11:23:50', '2026-03-27 11:23:52');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 4, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, '. 7) 6- I. :', null, 1, null, 'DELIVERED', '2026-04-06 13:05:17', '2026-04-06 13:05:20', '2026-04-06 13:23:48', '2026-04-06 13:05:17', '2026-04-06 13:23:48');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 5, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, '. . 45 Q 3) M', 'ESTAFETA', 1, null, 'NOTIFIED', '2026-04-07 11:43:27', '2026-04-07 11:43:29', null, '2026-04-07 11:43:27', '2026-04-07 11:43:29');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 5, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, '13 11296', 'ENVIAME', 3, null, 'NOTIFIED', '2026-04-07 12:52:08', '2026-04-07 12:52:10', null, '2026-04-07 12:52:08', '2026-04-07 12:52:10');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 4, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, 'V T W', 'ENVIAME', 1, null, 'NOTIFIED', '2026-04-07 12:53:00', '2026-04-07 12:53:02', null, '2026-04-07 12:53:00', '2026-04-07 12:53:02');
INSERT INTO smi.ra_packages (host_id, guard_received_id, guard_delivered_id, recipient_name_snapshot, recipient_email_snapshot, recipient_phone_snapshot, brought_by_name, tracking_number, carrier_company, package_count, notes, status, received_at, notified_at, delivered_at, created_at, updated_at) VALUES (72, 3, null, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', null, '→ -RU . : . -U', 'LIVERPOOL', 1, null, 'NOTIFIED', '2026-04-07 12:54:28', '2026-04-07 12:54:30', null, '2026-04-07 12:54:28', '2026-04-07 12:54:30');
