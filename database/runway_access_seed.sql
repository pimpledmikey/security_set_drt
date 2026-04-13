INSERT INTO ra_app_settings (setting_key, setting_value)
VALUES
  ('company_name', 'Control Entradas DRT'),
  ('default_theme', 'midnight'),
  ('appointments_enabled', 'false'),
  ('openai_api_key', ''),
  ('openai_model_text', 'gpt-5-mini'),
  ('openai_model_vision', 'gpt-4o-mini'),
  ('document_encryption_key', 'CHANGE_THIS_TO_A_REAL_SECRET'),
  ('smtp_server', 'smtp.office365.com'),
  ('smtp_user', 'informatica@drt.com.mx'),
  ('smtp_pass', ''),
  ('smtp_from', 'informatica@drt.com.mx'),
  ('smtp_port', '587'),
  ('smtp_security', 'T'),
  ('package_email_enabled', 'true'),
  ('package_whatsapp_enabled', 'true'),
  ('collection_email_enabled', 'true'),
  ('collection_whatsapp_enabled', 'true'),
  ('visit_email_enabled', 'true'),
  ('visit_whatsapp_enabled', 'true'),
  ('wasender_api_url', 'https://wasenderapi.com/api/send-message'),
  ('wasender_api_key', '');

INSERT INTO ra_hosts (full_name, area_name, email, phone_number, search_alias)
VALUES
  ('Juridico', 'Legal', NULL, NULL, 'juridico legal'),
  ('Recepcion Corporativa', 'Recepcion', NULL, NULL, 'recepcion lobby front desk'),
  ('Sistemas', 'TI', NULL, NULL, 'sistemas tecnologia soporte'),
  ('Miguel Angel Avila Requena', 'Direccion', 'mavila@drt.com.mx', NULL, 'miguel angel avila requena mavila avila requena');

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

INSERT INTO ra_package_carriers (carrier_name, status, sort_order)
VALUES
  ('AMAZON', 'ACTIVE', 10),
  ('DHL', 'ACTIVE', 20),
  ('ENVIAME', 'ACTIVE', 30),
  ('ESTAFETA', 'ACTIVE', 40),
  ('FEDEX', 'ACTIVE', 50),
  ('LIVERPOOL', 'ACTIVE', 60),
  ('OTRO', 'ACTIVE', 70),
  ('PAQUETEXPRESS', 'ACTIVE', 80),
  ('PALACIO DE HIERRO', 'ACTIVE', 90),
  ('PARTICULAR', 'ACTIVE', 100),
  ('REDPACK', 'ACTIVE', 110),
  ('SHEIN', 'ACTIVE', 120)
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  sort_order = VALUES(sort_order),
  updated_at = CURRENT_TIMESTAMP;
