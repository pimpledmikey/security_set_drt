create table ra_visit_events
(
    id              bigint auto_increment
        primary key,
    visitor_id      bigint                                not null,
    host_id         bigint                                null,
    host_name_snapshot unknown null,
    host_phone_snapshot unknown null,
    guard_id        bigint                                null,
    purpose         varchar(255)                          null,
    observations    varchar(255)                          null,
    has_appointment tinyint(1)  default 0                 not null,
    group_size      int         default 1                 not null,
    entered_at      datetime                              not null,
    checked_out_at  datetime                              null,
    status          varchar(30) default 'INSIDE'          not null,
    source          varchar(40) default 'FLUTTER'         not null,
    created_at      datetime    default CURRENT_TIMESTAMP not null,
    updated_at      datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint fk_ra_visit_events_guard
        foreign key (guard_id) references ra_guards (id)
            on update cascade on delete set null,
    constraint fk_ra_visit_events_host
        foreign key (host_id) references ra_hosts (id)
            on update cascade on delete set null,
    constraint fk_ra_visit_events_visitor
        foreign key (visitor_id) references ra_visitors (id)
            on update cascade
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_visit_events_active
    on ra_visit_events (checked_out_at, entered_at);

create index idx_ra_visit_events_group_size
    on ra_visit_events (group_size);

create index idx_ra_visit_events_host
    on ra_visit_events (host_id);

create index idx_ra_visit_events_status
    on ra_visit_events (status, entered_at);

create index idx_ra_visit_events_visitor
    on ra_visit_events (visitor_id);

INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (1, 3, null, null, null, 'Visita general', null, 0, 1, '2026-03-23 12:35:11', '2026-03-23 12:36:52', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 12:35:11', '2026-03-23 12:36:52');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (2, 3, null, null, null, 'Visita general', null, 0, 1, '2026-03-23 13:04:06', '2026-03-23 17:19:17', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 13:04:06', '2026-03-23 17:19:17');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (3, 2, null, null, null, 'Visita general', null, 0, 1, '2026-03-23 13:10:12', '2026-03-23 17:19:14', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 13:10:12', '2026-03-23 17:19:14');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (4, 1, null, null, null, 'Visita general', null, 0, 1, '2026-03-23 13:17:19', '2026-03-23 13:38:36', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 13:17:19', '2026-03-23 13:38:36');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (5, 1, null, null, null, 'Visita general', null, 1, 1, '2026-03-23 13:38:24', '2026-03-23 14:55:15', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 13:38:24', '2026-03-23 14:55:15');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (6, 2, null, null, null, 'Visita general', null, 1, 1, '2026-03-23 14:40:42', '2026-03-23 17:19:12', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 14:40:42', '2026-03-23 17:19:12');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (7, 1, null, null, null, 'Visita general', null, 0, 1, '2026-03-23 14:41:30', '2026-03-23 17:19:10', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 14:41:30', '2026-03-23 17:19:10');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (8, 2, null, null, null, 'Visita general', null, 1, 1, '2026-03-23 14:55:07', '2026-03-23 14:55:12', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 14:55:07', '2026-03-23 14:55:12');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (9, 1, null, null, null, 'personal', null, 0, 1, '2026-03-23 15:40:06', '2026-03-23 15:40:19', 'CHECKED_OUT', 'FLUTTER', '2026-03-23 15:40:06', '2026-03-23 15:40:19');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (10, 4, null, null, null, 'Visita general', null, 0, 1, '2026-03-24 08:40:37', '2026-03-24 09:17:27', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 08:40:37', '2026-03-24 09:17:27');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (11, 53, null, null, null, 'Visita general', null, 1, 4, '2026-03-24 09:01:40', '2026-03-24 09:29:35', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 09:01:40', '2026-03-24 09:29:35');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (12, 7, null, null, null, 'Visita general', null, 0, 1, '2026-03-24 09:08:41', '2026-03-26 08:26:08', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 09:08:41', '2026-03-26 08:26:08');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (13, 11, null, null, null, 'rotororo', null, 0, 1, '2026-03-24 09:13:11', '2026-03-26 08:26:07', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 09:13:11', '2026-03-26 08:26:07');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (14, 4, null, null, null, 'Personal', null, 0, 3, '2026-03-24 09:16:22', '2026-03-24 09:29:06', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 09:16:22', '2026-03-24 09:29:06');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (4, 16, null, null, null, 'Visita general', null, 0, 7, '2026-03-24 09:24:40', '2026-03-24 10:23:14', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 09:24:40', '2026-03-24 10:23:14');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (15, 4, null, null, null, 'idoso', null, 1, 2, '2026-03-24 10:14:19', '2026-03-26 08:26:05', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 10:14:19', '2026-03-26 08:26:05');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (16, 72, null, null, null, 'dosowo', null, 1, 1, '2026-03-24 13:35:31', '2026-03-26 08:25:48', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 13:35:31', '2026-03-26 08:25:48');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (17, 72, null, null, null, 'njynj', null, 1, 5, '2026-03-24 14:01:14', '2026-03-26 08:25:45', 'CHECKED_OUT', 'FLUTTER', '2026-03-24 14:01:14', '2026-03-26 08:25:45');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (18, 72, null, null, null, 'Personal', null, 1, 1, '2026-03-26 08:31:00', '2026-03-26 08:37:11', 'CHECKED_OUT', 'FLUTTER', '2026-03-26 08:31:00', '2026-03-26 08:37:11');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (19, 4, null, null, null, 'personal', null, 1, 1, '2026-03-26 08:51:38', '2026-03-26 08:53:17', 'CHECKED_OUT', 'FLUTTER', '2026-03-26 08:51:38', '2026-03-26 08:53:17');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (20, 8, null, null, null, 'Personal', null, 1, 1, '2026-03-26 09:57:10', '2026-03-26 10:12:45', 'CHECKED_OUT', 'FLUTTER', '2026-03-26 09:57:10', '2026-03-26 10:12:45');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (21, 72, 'Miguel Angel Avila Requena', null, null, 'WL', 'SA', 1, 1, '2026-03-26 13:49:58', null, 'INSIDE', 'FLUTTER', '2026-03-26 13:49:58', '2026-03-26 13:49:58');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (22, 72, 'Miguel Angel Avila Requena', null, null, 'DDIDID', null, 1, 1, '2026-03-27 08:47:50', '2026-04-07 11:44:19', 'CHECKED_OUT', 'FLUTTER', '2026-03-27 08:47:50', '2026-04-07 11:44:19');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (23, 72, 'Miguel Angel Avila Requena', null, null, 'SKSSI', null, 1, 2, '2026-03-27 11:01:26', '2026-04-07 11:44:15', 'CHECKED_OUT', 'FLUTTER', '2026-03-27 11:01:26', '2026-04-07 11:44:15');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (24, 72, 'Miguel Angel Avila Requena', '4426015698', null, 'VISITA', null, 1, 3, '2026-04-06 13:04:17', '2026-04-07 11:44:13', 'CHECKED_OUT', 'FLUTTER', '2026-04-06 13:04:17', '2026-04-07 11:44:13');
INSERT INTO smi.ra_visit_events (visitor_id, host_id, host_name_snapshot, host_phone_snapshot, guard_id, purpose, observations, has_appointment, group_size, entered_at, checked_out_at, status, source, created_at, updated_at) VALUES (25, 4, 'Abraham Escamilla', null, null, 'DNDJDWISJ', null, 1, 1, '2026-04-06 17:19:32', '2026-04-07 11:44:11', 'CHECKED_OUT', 'FLUTTER', '2026-04-06 17:19:32', '2026-04-07 11:44:11');
