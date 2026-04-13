create table ra_internal_alerts
(
    id             bigint auto_increment
        primary key,
    visit_event_id bigint                               null,
    alert_type     varchar(60)                          not null,
    title          varchar(160)                         not null,
    body_text      text                                 not null,
    is_read        tinyint(1) default 0                 not null,
    created_at     datetime   default CURRENT_TIMESTAMP not null,
    constraint fk_ra_internal_alerts_visit
        foreign key (visit_event_id) references ra_visit_events (id)
            on update cascade on delete set null
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_internal_alerts_is_read_created_at
    on ra_internal_alerts (is_read, created_at);

INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (1, 'NEW_CHECKIN', 'Nuevo ingreso', 'INSTITUTO NACIONAL ELECTORAL ingreso al corporativo.', 0, '2026-03-23 12:35:11');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (1, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 12:36:52');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (2, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL AVILA REQUENA ingreso al corporativo.', 0, '2026-03-23 13:04:06');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (3, 'NEW_CHECKIN', 'Nuevo ingreso', 'Dwight Kurt Schrute ingreso al corporativo.', 0, '2026-03-23 13:10:12');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (4, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL AVILA REQUENA ingreso al corporativo.', 0, '2026-03-23 13:17:19');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (5, 'NEW_CHECKIN', 'Nuevo ingreso', 'Maria Fernanda Hernandez Cruz ingreso al corporativo.', 0, '2026-03-23 13:38:24');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (4, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 13:38:36');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (6, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL REQUENA ingreso al corporativo.', 0, '2026-03-23 14:40:42');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (7, 'NEW_CHECKIN', 'Nuevo ingreso', 'Maria Fernanda Hernandez Cruz ingreso al corporativo.', 0, '2026-03-23 14:41:30');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (8, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL AVILA REQUENA ingreso al corporativo.', 0, '2026-03-23 14:55:07');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (8, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 14:55:12');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (5, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 14:55:15');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (9, 'NEW_CHECKIN', 'Nuevo ingreso', 'Rebeca Medina Suarez ingreso al corporativo.', 0, '2026-03-23 15:40:06');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (9, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 15:40:19');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (7, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 17:19:10');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (6, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 17:19:12');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (3, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 17:19:14');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (2, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-23 17:19:17');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (10, 'NEW_CHECKIN', 'Nuevo ingreso', 'Maria Fernanda Hernandez Cruz ingreso al corporativo.', 0, '2026-03-24 08:40:37');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (11, 'NEW_CHECKIN', 'Nuevo ingreso', 'Rebeca Medina Suarez ingreso al corporativo.', 0, '2026-03-24 09:01:40');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (12, 'NEW_CHECKIN', 'Nuevo ingreso', 'ABRAHAM ESCAMILLA SERRANO ingreso al corporativo.', 0, '2026-03-24 09:08:41');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (13, 'NEW_CHECKIN', 'Nuevo ingreso', 'Dwight Kurt Schrute ingreso al corporativo.', 0, '2026-03-24 09:13:11');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (14, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL AVILA REQUENA ingreso al corporativo.', 0, '2026-03-24 09:16:22');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (10, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-24 09:17:27');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (15, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL AVILA REQUENA ingreso al corporativo.', 0, '2026-03-24 09:24:40');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (14, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-24 09:29:06');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (11, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-24 09:29:35');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (16, 'NEW_CHECKIN', 'Nuevo ingreso', 'Estados Unidos Mexic ingreso al corporativo.', 0, '2026-03-24 10:14:19');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (15, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-24 10:23:14');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (17, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL AVILA REQUENA ingreso al corporativo.', 0, '2026-03-24 13:35:31');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (18, 'NEW_CHECKIN', 'Nuevo ingreso', 'MIGUEL ANGEL MIGUEL ANGEL ingreso al corporativo.', 0, '2026-03-24 14:01:14');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (18, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 08:25:45');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (17, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 08:25:48');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (16, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 08:26:05');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (13, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 08:26:07');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (12, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 08:26:08');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (19, 'NEW_CHECKIN', 'Nuevo ingreso', 'ESCAMILLA SERRANO ABRAHAM ingreso al corporativo.', 0, '2026-03-26 08:31:00');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (19, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 08:37:11');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (20, 'NEW_CHECKIN', 'Nuevo ingreso', 'ABRAHAM ESCAMILLA ingreso al corporativo.', 0, '2026-03-26 08:51:38');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (20, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 08:53:17');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (21, 'NEW_CHECKIN', 'Nuevo ingreso', 'ESCAMILLA SERRANO ARARAM ingreso al corporativo.', 0, '2026-03-26 09:57:10');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (21, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-03-26 10:12:45');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (22, 'NEW_CHECKIN', 'Nuevo ingreso', 'BARBARA LOPEZ ingreso al corporativo.', 0, '2026-03-26 13:49:58');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (23, 'NEW_CHECKIN', 'Nuevo ingreso', 'FSVADVF ingreso al corporativo.', 0, '2026-03-27 08:47:50');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (24, 'NEW_CHECKIN', 'Nuevo ingreso', 'FRANCO Recursos Humanos ingreso al corporativo.', 0, '2026-03-27 11:01:26');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (25, 'NEW_CHECKIN', 'Nuevo ingreso', 'Nocuty Secult Bob Smith ingreso al corporativo.', 0, '2026-04-06 13:04:17');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (26, 'NEW_CHECKIN', 'Nuevo ingreso', 'Bob Smith ingreso al corporativo.', 0, '2026-04-06 17:19:32');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (26, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-04-07 11:44:11');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (25, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-04-07 11:44:13');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (24, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-04-07 11:44:15');
INSERT INTO smi.ra_internal_alerts (visit_event_id, alert_type, title, body_text, is_read, created_at) VALUES (23, 'CHECKOUT', 'Salida registrada', 'La salida fue registrada por Guardia.', 0, '2026-04-07 11:44:19');
