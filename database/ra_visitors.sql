create table ra_visitors
(
    id               bigint auto_increment
        primary key,
    full_name        varchar(180)                       not null,
    identifier_type  varchar(60)                        null,
    identifier_value varchar(160)                       null,
    birth_date       date                               null,
    document_label   varchar(120)                       null,
    issuer           varchar(120)                       null,
    last_seen_at     datetime                           null,
    created_at       datetime default CURRENT_TIMESTAMP not null,
    updated_at       datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_visitors_full_name
    on ra_visitors (full_name);

create index idx_ra_visitors_identifier_value
    on ra_visitors (identifier_value);

create index idx_ra_visitors_name_identifier
    on ra_visitors (full_name, identifier_value);

INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('INSTITUTO NACIONAL ELECTORAL', 'Pasaporte', 'INSTITUTO', null, 'Documento capturado', '', '2026-03-23 12:35:11', '2026-03-23 12:35:11', '2026-03-23 12:35:11');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('MIGUEL ANGEL AVILA REQUENA', 'CURP', 'AIRM950702HQTVQGO9', '1995-07-02', 'CREDENCIAL PARA VOTAR', '', '2026-03-23 13:04:06', '2026-03-23 13:04:06', '2026-03-23 13:04:06');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Dwight Kurt Schrute', 'Otro', 'Campo', null, 'Credencial builder.systems', '', '2026-03-23 13:10:12', '2026-03-23 13:10:12', '2026-03-23 13:10:12');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('MIGUEL ANGEL AVILA REQUENA', 'No. de Licencia', 'Q195448-19', '0000-00-00', 'Licencia para conducir', '', '2026-03-23 13:17:19', '2026-03-23 13:17:19', '2026-03-23 13:17:19');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Maria Fernanda Hernandez Cruz', 'Otro', 'credencial', null, 'Credencial Corporativa', '', '2026-03-23 13:38:24', '2026-03-23 13:38:24', '2026-03-23 13:38:24');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('MIGUEL ANGEL REQUENA', 'Clave de elector', 'AVRQMG95070222H700', '1995-07-02', 'CREDENCIAL PARA VOTAR', '', '2026-03-23 14:40:42', '2026-03-23 14:40:42', '2026-03-23 14:40:42');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Maria Fernanda Hernandez Cruz', 'Otro', 'eslsl', null, 'Credencial Corporativa', '', '2026-03-23 14:41:30', '2026-03-23 14:41:30', '2026-03-23 14:41:30');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('MIGUEL ANGEL AVILA REQUENA', 'CLAVE DE ELECTOR', 'AVROMG95070222H700', '0000-00-00', 'CREDENCIAL PARA VOTAR', '', '2026-03-23 14:55:07', '2026-03-23 14:55:07', '2026-03-23 14:55:07');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Rebeca Medina Suarez', 'Pasaporte', 'INFOUEL1', null, 'Supervisor', '', '2026-03-23 15:40:06', '2026-03-23 15:40:06', '2026-03-23 15:40:06');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Maria Fernanda Hernandez Cruz', 'Otro', '', null, 'Identificacion capturada', '', '2026-03-24 08:40:37', '2026-03-24 08:40:37', '2026-03-24 08:40:37');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Rebeca Medina Suarez', 'Otro', '', null, 'Identification badge', '', '2026-03-24 09:01:40', '2026-03-24 09:01:40', '2026-03-24 09:01:40');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('ABRAHAM ESCAMILLA SERRANO', 'Otro', '', null, 'Identificacion capturada', '', '2026-03-24 09:08:41', '2026-03-24 09:08:41', '2026-03-24 09:08:41');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Dwight Kurt Schrute', 'Otro', '', null, 'Identificacion capturada', '', '2026-03-24 09:13:11', '2026-03-24 09:13:11', '2026-03-24 09:13:11');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('MIGUEL ANGEL AVILA REQUENA', 'CLAVE DE ELECTOR', 'AVRQMG95070222H700', '0000-00-00', 'CREDENCIAL PARA VOTAR', '', '2026-03-24 09:16:22', '2026-03-24 09:16:22', '2026-03-24 09:16:22');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Estados Unidos Mexic', 'Pasaporte', 'Q195448', null, 'Licencia', '', '2026-03-24 10:14:19', '2026-03-24 10:14:19', '2026-03-24 10:14:19');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('MIGUEL ANGEL AVILA REQUENA', 'Pasaporte', 'Q195448', null, 'Licencia', '', '2026-03-24 13:35:31', '2026-03-24 13:35:31', '2026-03-24 13:35:31');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('MIGUEL ANGEL MIGUEL ANGEL', 'Pasaporte', 'Q195448', null, 'Licencia', '', '2026-03-24 14:01:14', '2026-03-24 14:01:14', '2026-03-24 14:01:14');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('ESCAMILLA SERRANO ABRAHAM', 'Otro', '', null, 'Identificacion capturada', '', '2026-03-26 08:31:00', '2026-03-26 08:31:00', '2026-03-26 08:31:00');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('ABRAHAM ESCAMILLA', 'Pasaporte', 'A307309622', null, 'Identificacion capturada', '', '2026-03-26 08:51:38', '2026-03-26 08:51:38', '2026-03-26 08:51:38');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('ESCAMILLA SERRANO ARARAM', 'employee_number', '01419', null, 'employee ID', '', '2026-03-26 09:57:10', '2026-03-26 09:57:10', '2026-03-26 09:57:10');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('BARBARA LOPEZ', 'Otro', '', null, 'Identificacion capturada', '', '2026-03-26 13:49:58', '2026-03-26 13:49:58', '2026-03-26 13:49:58');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('FSVADVF', 'Otro', '', null, 'Identificación Personal', '', '2026-03-27 08:47:50', '2026-03-27 08:47:50', '2026-03-27 08:47:50');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('FRANCO Recursos Humanos', 'Otro', '', null, 'Identificacion capturada', '', '2026-03-27 11:01:26', '2026-03-27 11:01:26', '2026-03-27 11:01:26');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Nocuty Secult Bob Smith', 'Otro', '', null, 'Identificacion capturada', '', '2026-04-06 13:04:17', '2026-04-06 13:04:17', '2026-04-06 13:04:17');
INSERT INTO smi.ra_visitors (full_name, identifier_type, identifier_value, birth_date, document_label, issuer, last_seen_at, created_at, updated_at) VALUES ('Bob Smith', 'Otro', '', null, 'security_badge', '', '2026-04-06 17:19:32', '2026-04-06 17:19:32', '2026-04-06 17:19:32');
