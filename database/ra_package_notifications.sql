create table ra_package_notifications
(
    id              bigint auto_increment
        primary key,
    package_id      bigint                                not null,
    recipient_email varchar(160)                          not null,
    subject_line    varchar(255)                          not null,
    delivery_status varchar(20) default 'FAILED'          not null,
    error_message   text                                  null,
    sent_at         datetime                              null,
    created_at      datetime    default CURRENT_TIMESTAMP not null,
    constraint fk_ra_package_notifications_package
        foreign key (package_id) references ra_packages (id)
            on update cascade on delete cascade
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_package_notifications_package_created_at
    on ra_package_notifications (package_id, created_at);

INSERT INTO smi.ra_package_notifications (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at) VALUES (1, 'mavila@drt.com.mx', 'Tienes un paquete en recepcion - Control Entradas DRT', 'SENT', null, '2026-03-24 12:29:02', '2026-03-24 12:29:02');
INSERT INTO smi.ra_package_notifications (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at) VALUES (2, 'aescamilla@drt.com.mx', 'Tienes un paquete en recepcion - Control Entradas DRT', 'SENT', null, '2026-03-24 12:55:29', '2026-03-24 12:55:29');
INSERT INTO smi.ra_package_notifications (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at) VALUES (3, 'mavila@drt.com.mx', 'Tienes un paquete en recepcion - Control Entradas DRT', 'SENT', null, '2026-03-24 14:02:02', '2026-03-24 14:02:02');
INSERT INTO smi.ra_package_notifications (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at) VALUES (4, 'aescamilla@drt.com.mx', 'Tienes un paquete en recepcion - Control Entradas DRT', 'SENT', null, '2026-03-26 10:06:18', '2026-03-26 10:06:18');
INSERT INTO smi.ra_package_notifications (package_id, recipient_email, subject_line, delivery_status, error_message, sent_at, created_at) VALUES (5, 'aescamilla@drt.com.mx', 'Tienes un paquete en recepcion - Control Entradas DRT', 'SENT', null, '2026-03-26 10:39:56', '2026-03-26 10:39:56');
