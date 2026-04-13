# Scriptcase

## Carpeta

- `lib/lib_runway_access_api.php`: libreria compartida
- `blanks/*.php`: contenido sugerido para aplicaciones `Blank`
- `blanks/blank_api_visit_detail.php`: detalle de visita con foto del documento
- `blanks/blank_guard_admin_dashboard.php`: dashboard HTML para jefe de guardias con filtros, tiempos y fotos

La libreria de proyecto recomendada en Scriptcase se llama `lib_runway_access_api`.
Configuracion mas simple: libreria **interna** (`prj`).
Usa libreria **externa** (`sys`) solo si la compartiras entre varios proyectos.

La libreria debe quedar en PHP puro.
Las macros `sc_lookup`, `sc_select`, `sc_exec_sql` y placeholders tipo `{rs_x}` deben quedarse dentro de los `Blank`, no dentro de la libreria incluida.

## Apps visuales sugeridas

- `form_hosts_admin`
- `grid_hosts_admin`
- `grid_visits_today`
- `grid_visits_active`
- `grid_document_audit`
- `dashboard_runway_access`

## Convencion

Cada `Blank` esta separado para que puedas copiar y pegar el contenido directamente en Scriptcase.

## Importante

Algunos archivos no pasan `php -l` fuera de Scriptcase porque usan placeholders tipo `{rs_xxx}` y macros `sc_*` que Scriptcase transforma internamente. Eso es normal para este tipo de archivo.
