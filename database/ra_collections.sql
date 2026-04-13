create table ra_collections
(
    id                       bigint auto_increment
        primary key,
    host_id                  bigint                                null,
    guard_handover_id        bigint                                null,
    requester_name_snapshot  varchar(160)                          not null,
    requester_email_snapshot varchar(160)                          null,
    requester_phone_snapshot varchar(40)                           null,
    tracking_number          varchar(160)                          not null,
    carrier_company          varchar(160)                          null,
    notes                    varchar(255)                          null,
    status                   varchar(30) default 'REGISTERED'      not null,
    registered_at            datetime                              not null,
    delivered_at             datetime                              null,
    created_at               datetime    default CURRENT_TIMESTAMP not null,
    updated_at               datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint fk_ra_collections_guard_handover
        foreign key (guard_handover_id) references ra_guards (id)
            on update cascade on delete set null,
    constraint fk_ra_collections_host
        foreign key (host_id) references ra_hosts (id)
            on update cascade on delete set null
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_collections_delivered_at
    on ra_collections (delivered_at);

create index idx_ra_collections_host
    on ra_collections (host_id);

create index idx_ra_collections_status_registered_at
    on ra_collections (status, registered_at);

INSERT INTO smi.ra_collections (host_id, guard_handover_id, requester_name_snapshot, requester_email_snapshot, requester_phone_snapshot, tracking_number, carrier_company, notes, status, registered_at, delivered_at, created_at, updated_at) VALUES (4, 6, 'Abraham Escamilla', 'aescamilla@drt.com.mx', null, 'HUJK', 'ESTAFETA', 'JSKSWK', 'DELIVERED', '2026-03-27 10:59:25', '2026-03-27 10:59:43', '2026-03-27 10:59:25', '2026-03-27 10:59:43');
INSERT INTO smi.ra_collections (host_id, guard_handover_id, requester_name_snapshot, requester_email_snapshot, requester_phone_snapshot, tracking_number, carrier_company, notes, status, registered_at, delivered_at, created_at, updated_at) VALUES (72, 6, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', 'JDDJDXJDJ', 'LIVERPOOL', null, 'DELIVERED', '2026-03-27 11:04:53', '2026-03-27 11:05:10', '2026-03-27 11:04:53', '2026-03-27 11:05:10');
INSERT INTO smi.ra_collections (host_id, guard_handover_id, requester_name_snapshot, requester_email_snapshot, requester_phone_snapshot, tracking_number, carrier_company, notes, status, registered_at, delivered_at, created_at, updated_at) VALUES (72, 5, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', 'CC DC', 'PAQUETEXPRESS', 'MSKSSKS', 'DELIVERED', '2026-03-27 11:07:02', '2026-03-27 11:07:19', '2026-03-27 11:07:02', '2026-03-27 11:07:19');
INSERT INTO smi.ra_collections (host_id, guard_handover_id, requester_name_snapshot, requester_email_snapshot, requester_phone_snapshot, tracking_number, carrier_company, notes, status, registered_at, delivered_at, created_at, updated_at) VALUES (72, 5, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', '-- * M³ R 45 >', 'ENVIAME', null, 'DELIVERED', '2026-04-07 11:42:01', '2026-04-07 11:44:00', '2026-04-07 11:42:01', '2026-04-07 11:44:00');
INSERT INTO smi.ra_collections (host_id, guard_handover_id, requester_name_snapshot, requester_email_snapshot, requester_phone_snapshot, tracking_number, carrier_company, notes, status, registered_at, delivered_at, created_at, updated_at) VALUES (72, 5, 'Miguel Angel Avila Requena', 'mavila@drt.com.mx', '4426015698', 'A- →. . . _ _', 'LIVERPOOL', null, 'REGISTERED', '2026-04-07 12:32:41', null, '2026-04-07 12:32:41', '2026-04-07 12:32:41');
