create table ra_visit_appointments
(
    id               bigint auto_increment
        primary key,
    visitor_name     varchar(180)                          not null,
    host_id          bigint                                not null,
    appointment_date date                                  not null,
    appointment_time time                                  null,
    notes            varchar(255)                          null,
    status           varchar(30) default 'PENDING'         not null,
    created_at       datetime    default CURRENT_TIMESTAMP not null,
    updated_at       datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint fk_ra_visit_appointments_host
        foreign key (host_id) references ra_hosts (id)
            on update cascade
)
    collate = utf8mb4_unicode_ci;

