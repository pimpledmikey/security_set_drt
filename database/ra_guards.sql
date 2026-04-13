create table ra_guards
(
    id            bigint auto_increment
        primary key,
    username      varchar(80)                           not null,
    password_hash varchar(255)                          not null,
    full_name     varchar(160)                          not null,
    role_name     varchar(40) default 'GUARDIA'         not null,
    status        varchar(20) default 'ACTIVE'          not null,
    last_login_at datetime                              null,
    created_at    datetime    default CURRENT_TIMESTAMP not null,
    updated_at    datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint username
        unique (username)
)
    collate = utf8mb4_unicode_ci;

INSERT INTO smi.ra_guards (username, password_hash, full_name, role_name, status, last_login_at, created_at, updated_at) VALUES ('hector.torres', 'CATALOG_ONLY_NO_LOGIN', 'Héctor Torres', 'GUARDIA', 'ACTIVE', null, '2026-03-24 11:46:00', '2026-03-24 11:46:00');
INSERT INTO smi.ra_guards (username, password_hash, full_name, role_name, status, last_login_at, created_at, updated_at) VALUES ('javier.hernandez', 'CATALOG_ONLY_NO_LOGIN', 'Javier Hernández', 'GUARDIA', 'ACTIVE', null, '2026-03-24 11:46:00', '2026-03-24 11:46:00');
INSERT INTO smi.ra_guards (username, password_hash, full_name, role_name, status, last_login_at, created_at, updated_at) VALUES ('jose.cruz.silva', 'CATALOG_ONLY_NO_LOGIN', 'José Cruz Silva', 'GUARDIA', 'ACTIVE', null, '2026-03-24 11:46:00', '2026-03-24 11:46:00');
INSERT INTO smi.ra_guards (username, password_hash, full_name, role_name, status, last_login_at, created_at, updated_at) VALUES ('marco.antonio', 'CATALOG_ONLY_NO_LOGIN', 'Marco Antonio', 'GUARDIA', 'ACTIVE', null, '2026-03-24 11:46:00', '2026-03-24 11:46:00');
INSERT INTO smi.ra_guards (username, password_hash, full_name, role_name, status, last_login_at, created_at, updated_at) VALUES ('ramiro.rojas', 'CATALOG_ONLY_NO_LOGIN', 'Ramiro Rojas', 'GUARDIA', 'ACTIVE', null, '2026-03-24 11:46:00', '2026-03-24 11:46:00');
INSERT INTO smi.ra_guards (username, password_hash, full_name, role_name, status, last_login_at, created_at, updated_at) VALUES ('ramon.pilar', 'CATALOG_ONLY_NO_LOGIN', 'Ramón Pilar', 'GUARDIA', 'ACTIVE', null, '2026-03-24 11:46:00', '2026-03-24 11:46:00');
INSERT INTO smi.ra_guards (username, password_hash, full_name, role_name, status, last_login_at, created_at, updated_at) VALUES ('raul.hurtado', 'CATALOG_ONLY_NO_LOGIN', 'Raúl Hurtado', 'GUARDIA', 'ACTIVE', null, '2026-03-24 11:46:00', '2026-03-24 11:46:00');
