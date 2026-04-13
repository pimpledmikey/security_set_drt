create table ra_collection_notifications
(
    id                bigint auto_increment
        primary key,
    collection_id     bigint                                not null,
    recipient_contact varchar(160)                          not null,
    subject_line      varchar(255)                          not null,
    delivery_status   varchar(20) default 'FAILED'          not null,
    error_message     text                                  null,
    sent_at           datetime                              null,
    created_at        datetime    default CURRENT_TIMESTAMP not null,
    constraint fk_ra_collection_notifications_collection
        foreign key (collection_id) references ra_collections (id)
            on update cascade on delete cascade
)
    collate = utf8mb4_unicode_ci;

create index idx_ra_collection_notifications_collection_created_at
    on ra_collection_notifications (collection_id, created_at);

