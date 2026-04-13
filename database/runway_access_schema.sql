CREATE TABLE IF NOT EXISTS ra_guards (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(160) NOT NULL,
  role_name VARCHAR(40) NOT NULL DEFAULT 'GUARDIA',
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_hosts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  employee_ref VARCHAR(80) NULL,
  full_name VARCHAR(160) NOT NULL,
  area_name VARCHAR(120) NULL,
  email VARCHAR(160) NULL,
  phone_number VARCHAR(40) NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  search_alias VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_visitors (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(180) NOT NULL,
  identifier_type VARCHAR(60) NULL,
  identifier_value VARCHAR(160) NULL,
  birth_date DATE NULL,
  document_label VARCHAR(120) NULL,
  issuer VARCHAR(120) NULL,
  last_seen_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_visit_events (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  visitor_id BIGINT NOT NULL,
  host_id BIGINT NULL,
  host_name_snapshot VARCHAR(160) NULL,
  host_phone_snapshot VARCHAR(40) NULL,
  guard_id BIGINT NULL,
  purpose VARCHAR(255) NULL,
  observations VARCHAR(255) NULL,
  has_appointment TINYINT(1) NOT NULL DEFAULT 0,
  group_size INT NOT NULL DEFAULT 1,
  entered_at DATETIME NOT NULL,
  checked_out_at DATETIME NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'INSIDE',
  source VARCHAR(40) NOT NULL DEFAULT 'FLUTTER',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_visit_events_visitor FOREIGN KEY (visitor_id) REFERENCES ra_visitors (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ra_visit_events_host FOREIGN KEY (host_id) REFERENCES ra_hosts (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_ra_visit_events_guard FOREIGN KEY (guard_id) REFERENCES ra_guards (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_visitor_documents (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  visitor_id BIGINT NOT NULL,
  visit_event_id BIGINT NULL,
  encrypted_blob LONGTEXT NOT NULL,
  mime_type VARCHAR(80) NOT NULL,
  key_version VARCHAR(40) NOT NULL DEFAULT 'v1',
  captured_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_visitor_documents_visitor FOREIGN KEY (visitor_id) REFERENCES ra_visitors (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ra_visitor_documents_visit FOREIGN KEY (visit_event_id) REFERENCES ra_visit_events (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_internal_alerts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  visit_event_id BIGINT NULL,
  alert_type VARCHAR(60) NOT NULL,
  title VARCHAR(160) NOT NULL,
  body_text TEXT NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_internal_alerts_visit FOREIGN KEY (visit_event_id) REFERENCES ra_visit_events (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_app_settings (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  setting_key VARCHAR(120) NOT NULL UNIQUE,
  setting_value TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_visit_appointments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  visitor_name VARCHAR(180) NOT NULL,
  host_id BIGINT NOT NULL,
  appointment_date DATE NOT NULL,
  appointment_time TIME NULL,
  notes VARCHAR(255) NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_visit_appointments_host FOREIGN KEY (host_id) REFERENCES ra_hosts (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_package_carriers (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  carrier_name VARCHAR(120) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_ra_package_carriers_name (carrier_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_packages (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  host_id BIGINT NULL,
  guard_received_id BIGINT NULL,
  guard_delivered_id BIGINT NULL,
  recipient_name_snapshot VARCHAR(160) NOT NULL,
  recipient_email_snapshot VARCHAR(160) NULL,
  recipient_phone_snapshot VARCHAR(40) NULL,
  brought_by_name VARCHAR(160) NULL,
  tracking_number VARCHAR(160) NULL,
  carrier_company VARCHAR(160) NULL,
  package_count INT NOT NULL DEFAULT 1,
  notes VARCHAR(255) NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'RECEIVED',
  received_at DATETIME NOT NULL,
  notified_at DATETIME NULL,
  delivered_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_packages_host FOREIGN KEY (host_id) REFERENCES ra_hosts (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ra_packages_guard_received FOREIGN KEY (guard_received_id) REFERENCES ra_guards (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_ra_packages_guard_delivered FOREIGN KEY (guard_delivered_id) REFERENCES ra_guards (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_package_evidence (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  package_id BIGINT NOT NULL,
  encrypted_blob LONGTEXT NOT NULL,
  mime_type VARCHAR(80) NOT NULL DEFAULT 'image/jpeg',
  key_version VARCHAR(40) NOT NULL DEFAULT 'v1',
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  captured_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_package_evidence_package FOREIGN KEY (package_id) REFERENCES ra_packages (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ra_package_notifications (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  package_id BIGINT NOT NULL,
  recipient_email VARCHAR(160) NOT NULL,
  subject_line VARCHAR(255) NOT NULL,
  delivery_status VARCHAR(20) NOT NULL DEFAULT 'FAILED',
  error_message TEXT NULL,
  sent_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ra_package_notifications_package FOREIGN KEY (package_id) REFERENCES ra_packages (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

CREATE INDEX idx_ra_hosts_full_name ON ra_hosts (full_name);
CREATE INDEX idx_ra_hosts_status_full_name ON ra_hosts (status, full_name);
CREATE INDEX idx_ra_visitors_full_name ON ra_visitors (full_name);
CREATE INDEX idx_ra_visitors_identifier_value ON ra_visitors (identifier_value);
CREATE INDEX idx_ra_visitors_name_identifier ON ra_visitors (full_name, identifier_value);
CREATE INDEX idx_ra_visit_events_status ON ra_visit_events (status, entered_at);
CREATE INDEX idx_ra_visit_events_active ON ra_visit_events (checked_out_at, entered_at);
CREATE INDEX idx_ra_visit_events_visitor ON ra_visit_events (visitor_id);
CREATE INDEX idx_ra_visit_events_host ON ra_visit_events (host_id);
CREATE INDEX idx_ra_visit_events_group_size ON ra_visit_events (group_size);
CREATE INDEX idx_ra_internal_alerts_is_read_created_at ON ra_internal_alerts (is_read, created_at);
CREATE INDEX idx_ra_package_carriers_status_sort ON ra_package_carriers (status, sort_order, carrier_name);
CREATE INDEX idx_ra_packages_status_received_at ON ra_packages (status, received_at);
CREATE INDEX idx_ra_packages_host ON ra_packages (host_id);
CREATE INDEX idx_ra_packages_delivered_at ON ra_packages (delivered_at);
CREATE INDEX idx_ra_package_evidence_package_sort ON ra_package_evidence (package_id, sort_order);
CREATE INDEX idx_ra_package_notifications_package_created_at ON ra_package_notifications (package_id, created_at);
CREATE INDEX idx_ra_collections_status_registered_at ON ra_collections (status, registered_at);
CREATE INDEX idx_ra_collections_host ON ra_collections (host_id);
CREATE INDEX idx_ra_collections_delivered_at ON ra_collections (delivered_at);
CREATE INDEX idx_ra_collection_evidence_collection_sort ON ra_collection_evidence (collection_id, sort_order);
CREATE INDEX idx_ra_collection_notifications_collection_created_at ON ra_collection_notifications (collection_id, created_at);
