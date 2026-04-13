ALTER TABLE ra_app_settings
  MODIFY setting_value TEXT NOT NULL;

INSERT INTO ra_app_settings (setting_key, setting_value, created_at, updated_at)
VALUES
  ('package_email_enabled', 'true', NOW(), NOW()),
  ('package_whatsapp_enabled', 'true', NOW(), NOW()),
  ('collection_email_enabled', 'true', NOW(), NOW()),
  ('collection_whatsapp_enabled', 'true', NOW(), NOW()),
  ('visit_email_enabled', 'true', NOW(), NOW()),
  ('visit_whatsapp_enabled', 'true', NOW(), NOW()),
  ('wasender_api_url', 'https://wasenderapi.com/api/send-message', NOW(), NOW()),
  ('wasender_api_key', '', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  setting_value = setting_value,
  updated_at = updated_at;

CREATE TABLE IF NOT EXISTS ra_package_delivery (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  package_id BIGINT NOT NULL UNIQUE,
  received_by_name VARCHAR(160) NOT NULL,
  signature_encrypted_blob LONGTEXT NOT NULL,
  mime_type VARCHAR(80) NOT NULL DEFAULT 'image/png',
  delivery_notes VARCHAR(255) NULL,
  delivered_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_package_delivery_package FOREIGN KEY (package_id) REFERENCES ra_packages (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_collections (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  host_id BIGINT NULL,
  guard_handover_id BIGINT NULL,
  requester_name_snapshot VARCHAR(160) NOT NULL,
  requester_email_snapshot VARCHAR(160) NULL,
  requester_phone_snapshot VARCHAR(40) NULL,
  tracking_number VARCHAR(160) NOT NULL,
  carrier_company VARCHAR(160) NULL,
  notes VARCHAR(255) NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'REGISTERED',
  registered_at DATETIME NOT NULL,
  delivered_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_collections_host FOREIGN KEY (host_id) REFERENCES ra_hosts (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_ra_collections_guard_handover FOREIGN KEY (guard_handover_id) REFERENCES ra_guards (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_collection_evidence (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  collection_id BIGINT NOT NULL,
  encrypted_blob LONGTEXT NOT NULL,
  mime_type VARCHAR(80) NOT NULL DEFAULT 'image/jpeg',
  key_version VARCHAR(40) NOT NULL DEFAULT 'v1',
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  captured_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_collection_evidence_collection FOREIGN KEY (collection_id) REFERENCES ra_collections (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_collection_notifications (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  collection_id BIGINT NOT NULL,
  recipient_contact VARCHAR(160) NOT NULL,
  subject_line VARCHAR(255) NOT NULL,
  delivery_status VARCHAR(20) NOT NULL DEFAULT 'FAILED',
  error_message TEXT NULL,
  sent_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_collection_notifications_collection FOREIGN KEY (collection_id) REFERENCES ra_collections (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_collection_delivery (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  collection_id BIGINT NOT NULL UNIQUE,
  delivered_to_name VARCHAR(160) NOT NULL,
  signature_encrypted_blob LONGTEXT NOT NULL,
  mime_type VARCHAR(80) NOT NULL DEFAULT 'image/png',
  delivery_notes VARCHAR(255) NULL,
  delivered_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_collection_delivery_collection FOREIGN KEY (collection_id) REFERENCES ra_collections (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_ra_collections_status_registered_at ON ra_collections (status, registered_at);
CREATE INDEX idx_ra_collections_host ON ra_collections (host_id);
CREATE INDEX idx_ra_collections_delivered_at ON ra_collections (delivered_at);
CREATE INDEX idx_ra_collection_evidence_collection_sort ON ra_collection_evidence (collection_id, sort_order);
CREATE INDEX idx_ra_collection_notifications_collection_created_at ON ra_collection_notifications (collection_id, created_at);
