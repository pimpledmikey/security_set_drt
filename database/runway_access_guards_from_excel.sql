INSERT INTO ra_guards (username, password_hash, full_name, role_name, status)
VALUES
  ('hector.torres', 'CATALOG_ONLY_NO_LOGIN', 'Héctor Torres', 'GUARDIA', 'ACTIVE'),
  ('javier.hernandez', 'CATALOG_ONLY_NO_LOGIN', 'Javier Hernández', 'GUARDIA', 'ACTIVE'),
  ('jose.cruz.silva', 'CATALOG_ONLY_NO_LOGIN', 'José Cruz Silva', 'GUARDIA', 'ACTIVE'),
  ('marco.antonio', 'CATALOG_ONLY_NO_LOGIN', 'Marco Antonio', 'GUARDIA', 'ACTIVE'),
  ('ramiro.rojas', 'CATALOG_ONLY_NO_LOGIN', 'Ramiro Rojas', 'GUARDIA', 'ACTIVE'),
  ('ramon.pilar', 'CATALOG_ONLY_NO_LOGIN', 'Ramón Pilar', 'GUARDIA', 'ACTIVE'),
  ('raul.hurtado', 'CATALOG_ONLY_NO_LOGIN', 'Raúl Hurtado', 'GUARDIA', 'ACTIVE')
ON DUPLICATE KEY UPDATE
  full_name = VALUES(full_name),
  role_name = VALUES(role_name),
  status = VALUES(status),
  updated_at = CURRENT_TIMESTAMP;
