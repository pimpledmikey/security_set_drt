create table ra_package_carriers
(
    id           bigint auto_increment
        primary key,
    carrier_name varchar(120)                          not null,
    status       varchar(20) default 'ACTIVE'          not null,
    sort_order   int         default 0                 not null,
    created_at   datetime    default CURRENT_TIMESTAMP not null,
    updated_at   datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_ra_package_carriers_name
        unique (carrier_name)
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_package_carriers_status_sort
    on ra_package_carriers (status, sort_order, carrier_name);

INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('AMAZON', 'ACTIVE', 10, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('DHL', 'ACTIVE', 20, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('ENVIAME', 'ACTIVE', 30, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('ESTAFETA', 'ACTIVE', 40, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('FEDEX', 'ACTIVE', 50, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('LIVERPOOL', 'ACTIVE', 60, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('OTRO', 'ACTIVE', 70, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('PAQUETEXPRESS', 'ACTIVE', 80, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('PALACIO DE HIERRO', 'ACTIVE', 90, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('PARTICULAR', 'ACTIVE', 100, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('REDPACK', 'ACTIVE', 110, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
INSERT INTO smi.ra_package_carriers (carrier_name, status, sort_order, created_at, updated_at) VALUES ('SHEIN', 'ACTIVE', 120, '2026-03-24 13:28:41', '2026-03-24 13:28:41');
