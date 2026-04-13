create table ra_app_settings
(
    id            bigint auto_increment
        primary key,
    setting_key   varchar(120)                       not null,
    setting_value text                               not null,
    created_at    datetime default CURRENT_TIMESTAMP not null,
    updated_at    datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint setting_key
        unique (setting_key)
)
    collate = utf8mb4_unicode_ci;

INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('company_name', 'Control Entradas DRT', '2026-03-23 11:58:08', '2026-03-23 13:00:12');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('default_theme', 'midnight', '2026-03-23 11:58:08', '2026-03-23 11:58:08');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('appointments_enabled', 'false', '2026-03-23 11:58:08', '2026-03-23 11:58:08');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('openai_model_text', 'gpt-5-mini', '2026-03-23 11:58:08', '2026-03-24 10:05:03');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('openai_model_vision', 'gpt-4o-mini', '2026-03-23 11:58:08', '2026-03-24 10:05:04');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('document_encryption_key', 'CHANGE_ME_DOCUMENT_ENCRYPTION_KEY', '2026-03-23 11:58:08', '2026-03-23 13:01:00');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('openai_api_key', '', '2026-03-23 12:59:08', '2026-03-23 12:59:40');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('smtp_server', 'smtp.office365.com', '2026-03-24 11:45:00', '2026-03-24 12:11:02');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('smtp_user', 'admin@example.com', '2026-03-24 11:45:00', '2026-03-24 12:11:03');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('smtp_pass', '', '2026-03-24 11:45:00', '2026-03-24 12:11:02');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('smtp_from', 'noreply@example.com', '2026-03-24 11:45:00', '2026-03-24 12:11:02');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('smtp_port', '587', '2026-03-24 11:45:00', '2026-03-24 11:45:00');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('smtp_security', 'T', '2026-03-24 11:45:00', '2026-03-24 11:45:00');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('package_email_enabled', 'true', '2026-03-26 12:58:57', '2026-04-07 12:53:51');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('package_whatsapp_enabled', 'false', '2026-03-26 12:58:57', '2026-04-07 12:53:51');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('visit_whatsapp_enabled', 'false', '2026-03-26 12:58:57', '2026-04-07 12:53:51');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('wasender_api_url', 'https://wasenderapi.com/api/send-message', '2026-03-26 12:58:57', '2026-03-26 12:58:57');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('wasender_api_key', '', '2026-03-26 12:58:57', '2026-03-26 13:03:28');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('collection_email_enabled', 'true', '2026-03-27 08:55:43', '2026-04-07 12:53:51');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('collection_whatsapp_enabled', 'false', '2026-03-27 08:55:43', '2026-04-07 12:53:51');
INSERT INTO smi.ra_app_settings (setting_key, setting_value, created_at, updated_at) VALUES ('visit_email_enabled', 'true', '2026-03-27 11:00:40', '2026-04-07 12:53:51');
