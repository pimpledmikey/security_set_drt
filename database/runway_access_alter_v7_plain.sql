-- Ejecuta solo las lineas de columnas que realmente falten en tu base actual.
-- Si una columna ya existe, esa linea puede fallar y puedes omitirla.

ALTER TABLE ra_package_delivery
  ADD COLUMN mime_type VARCHAR(80) NOT NULL DEFAULT 'image/png' AFTER signature_encrypted_blob;

ALTER TABLE ra_package_delivery
  ADD COLUMN delivery_notes VARCHAR(255) NULL AFTER mime_type;

ALTER TABLE ra_package_delivery
  ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER delivered_at;

ALTER TABLE ra_collection_delivery
  ADD COLUMN mime_type VARCHAR(80) NOT NULL DEFAULT 'image/png' AFTER signature_encrypted_blob;

ALTER TABLE ra_collection_delivery
  ADD COLUMN delivery_notes VARCHAR(255) NULL AFTER mime_type;

ALTER TABLE ra_collection_delivery
  ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER delivered_at;
