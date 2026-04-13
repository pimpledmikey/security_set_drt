# Instalacion rapida en Scriptcase

## 1. Base de datos

Ejecuta en este orden:

1. `database/runway_access_schema.sql`
2. `database/runway_access_seed.sql`
3. `database/runway_access_hosts_from_excel.sql`

Si ya tienes la base creada y solo quieres agregar los nuevos campos de visitas grupales y observaciones, ejecuta tambien:

4. `database/runway_access_alter_v2.sql`

## 2. Libreria del proyecto

Crea una libreria de proyecto llamada `lib_runway_access_api` y pega el contenido de:

- `scriptcase/lib/lib_runway_access_api.php`

Para este proyecto, usa **libreria interna de proyecto** (`prj`). Es la opcion mas simple.
Solo usa libreria externa (`sys`) si vas a compartir la misma libreria entre varios proyectos Scriptcase.

## 3. Blank apps

Crea estas aplicaciones `Blank` y pega el archivo correspondiente:

- `blank_api_guard_login`
- `blank_api_bootstrap`
- `blank_api_visitor_extract`
- `blank_api_host_search`
- `blank_api_visit_checkin`
- `blank_api_visit_active`
- `blank_api_visit_detail`
- `blank_api_visit_checkout`
- `blank_api_dashboard_summary`
- `blank_api_internal_alerts`
- `blank_guard_admin_dashboard`

`blank_api_guard_login` queda disponible como opcional/futuro. La app Flutter actual entra directo a home sin login.

Todos usan la libreria:

```php
sc_include_library('prj', 'lib_runway_access_api', 'lib_runway_access_api.php', true, true);
```

## 4. Conexion

Asigna en cada Blank la conexion de base de datos que ya usas en tu proyecto Scriptcase.

## 5. Ajustes obligatorios

En `ra_app_settings` cambia:

- `openai_api_key`
- `document_encryption_key`
- `company_name` si quieres otro nombre visible

`openai_api_key` debe guardar tu llave de OpenAI.
`document_encryption_key` debe ser otra cadena distinta, larga y privada, usada solo para cifrar la foto del documento.

## 6. URLs esperadas

Flutter ahora apunta por defecto a:

- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_guard_login/blank_api_guard_login.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_bootstrap/blank_api_bootstrap.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_visitor_extract/blank_api_visitor_extract.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_host_search/blank_api_host_search.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_visit_checkin/blank_api_visit_checkin.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_visit_active/blank_api_visit_active.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_visit_detail/blank_api_visit_detail.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_visit_checkout/blank_api_visit_checkout.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_dashboard_summary/blank_api_dashboard_summary.php`
- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_api_internal_alerts/blank_api_internal_alerts.php`

Dashboard administrativo sugerido:

- `https://dev.bsys.mx/scriptcase/app/Gilneas/blank_guard_admin_dashboard/blank_guard_admin_dashboard.php`

Si tu URL real cambia, ajusta `flutter_app/lib/core/config/env.dart`.
