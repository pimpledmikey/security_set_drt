SET @db_name := DATABASE();

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

SET @package_mime_type_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @db_name
    AND TABLE_NAME = 'ra_package_delivery'
    AND COLUMN_NAME = 'mime_type'
);
SET @sql := IF(
  @package_mime_type_exists = 0,
  'ALTER TABLE ra_package_delivery ADD COLUMN mime_type VARCHAR(80) NOT NULL DEFAULT ''image/png'' AFTER signature_encrypted_blob',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @package_delivery_notes_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @db_name
    AND TABLE_NAME = 'ra_package_delivery'
    AND COLUMN_NAME = 'delivery_notes'
);
SET @sql := IF(
  @package_delivery_notes_exists = 0,
  'ALTER TABLE ra_package_delivery ADD COLUMN delivery_notes VARCHAR(255) NULL AFTER mime_type',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @package_created_at_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @db_name
    AND TABLE_NAME = 'ra_package_delivery'
    AND COLUMN_NAME = 'created_at'
);
SET @sql := IF(
  @package_created_at_exists = 0,
  'ALTER TABLE ra_package_delivery ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER delivered_at',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

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

SET @collection_mime_type_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @db_name
    AND TABLE_NAME = 'ra_collection_delivery'
    AND COLUMN_NAME = 'mime_type'
);
SET @sql := IF(
  @collection_mime_type_exists = 0,
  'ALTER TABLE ra_collection_delivery ADD COLUMN mime_type VARCHAR(80) NOT NULL DEFAULT ''image/png'' AFTER signature_encrypted_blob',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @collection_delivery_notes_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @db_name
    AND TABLE_NAME = 'ra_collection_delivery'
    AND COLUMN_NAME = 'delivery_notes'
);
SET @sql := IF(
  @collection_delivery_notes_exists = 0,
  'ALTER TABLE ra_collection_delivery ADD COLUMN delivery_notes VARCHAR(255) NULL AFTER mime_type',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @collection_created_at_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @db_name
    AND TABLE_NAME = 'ra_collection_delivery'
    AND COLUMN_NAME = 'created_at'
);
SET @sql := IF(
  @collection_created_at_exists = 0,
  'ALTER TABLE ra_collection_delivery ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER delivered_at',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
