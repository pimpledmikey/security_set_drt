# Base de datos

Esta carpeta concentra los scripts SQL que sostienen la operación del proyecto `security_set_drt`. Aquí vive la estructura principal de tablas, catálogos base, seeds iniciales y scripts de migración incremental.

## Objetivo

La base de datos es el punto de integración entre la app Flutter, los endpoints PHP generados desde Scriptcase y los procesos auxiliares de notificación, auditoría y evidencia documental. Mantener estos scripts versionados permite instalar el sistema desde cero, reproducir entornos y aplicar cambios de forma controlada.

## Contenido principal

- `runway_access_schema.sql`: esquema base del sistema.
- `runway_access_seed.sql`: datos iniciales mínimos para operar.
- `runway_access_hosts_from_excel.sql`: carga inicial de anfitriones desde una fuente externa.
- `runway_access_guards_from_excel.sql`: carga inicial de guardias desde una fuente externa.
- `runway_access_alter_v6.sql`: cambios incrementales para una versión previa.
- `runway_access_alter_v7.sql`: cambios incrementales para una versión previa.
- `runway_access_alter_v7_plain.sql`: variante de migración v7 pensada para entornos donde conviene ejecutar SQL más directo o sin dependencias adicionales.
- Scripts por tabla como `ra_packages.sql`, `ra_visitors.sql`, `ra_internal_alerts.sql`, `ra_package_notifications.sql`, etc.: referencia granular o apoyo para reconstrucción puntual de entidades.

## Instalación en una base nueva

Orden recomendado para un entorno limpio:

1. Crear la base de datos destino en MySQL o MariaDB.
2. Importar `runway_access_schema.sql`.
3. Importar `runway_access_seed.sql`.
4. Importar, si aplica, `runway_access_hosts_from_excel.sql` y `runway_access_guards_from_excel.sql`.
5. Revisar la tabla `ra_app_settings` y completar valores reales de operación.

Ejemplo:

```bash
mysql -u TU_USUARIO -p TU_BASE < runway_access_schema.sql
mysql -u TU_USUARIO -p TU_BASE < runway_access_seed.sql
mysql -u TU_USUARIO -p TU_BASE < runway_access_hosts_from_excel.sql
mysql -u TU_USUARIO -p TU_BASE < runway_access_guards_from_excel.sql
```

## Respaldo antes de cualquier cambio

Antes de ejecutar alters o cargas masivas, genera un respaldo completo.

Ejemplo:

```bash
mysqldump -u TU_USUARIO -p --routines --triggers --single-transaction TU_BASE > backup_pre_migracion.sql
```

Si el entorno es crítico, también conviene generar un respaldo comprimido con fecha:

```bash
mysqldump -u TU_USUARIO -p --routines --triggers --single-transaction TU_BASE | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

## Migraciones en entornos existentes

Si la base ya está en producción o en uso, no vuelvas a importar el esquema completo. En ese caso:

1. Genera respaldo completo.
2. Identifica la versión actual del entorno.
3. Aplica los scripts de migración uno por uno en el orden correcto.
4. Valida estructura, datos y operación de la app después de cada cambio.

Orden sugerido si vienes de una versión antigua:

1. `runway_access_alter_v6.sql`
2. `runway_access_alter_v7.sql` o `runway_access_alter_v7_plain.sql`, según el entorno

Ejemplo:

```bash
mysql -u TU_USUARIO -p TU_BASE < runway_access_alter_v6.sql
mysql -u TU_USUARIO -p TU_BASE < runway_access_alter_v7.sql
```

## Recomendaciones de migración

- Aplica cambios primero en desarrollo o staging antes de tocar producción.
- No modifiques scripts históricos ya usados en otros entornos; agrega un nuevo archivo de migración cuando el cambio ya fue liberado.
- Mantén una secuencia clara de versiones para evitar dudas al desplegar.
- Si un script altera columnas usadas por Flutter o Scriptcase, valida también los blanks/API que dependen de ellas.
- Documenta cualquier dato manual posterior a la importación, especialmente claves de API, SMTP y configuraciones en `ra_app_settings`.

## Tablas clave del flujo

Algunas tablas especialmente importantes dentro del sistema:

- `ra_visitors`, `ra_visit_events`, `ra_visitor_documents`: control de visitantes, eventos de entrada/salida y evidencias.
- `ra_packages`, `ra_package_delivery`, `ra_package_evidence`, `ra_package_notifications`: flujo de recepción, entrega y notificación de paquetes.
- `ra_collections`, `ra_collection_delivery`, `ra_collection_evidence`, `ra_collection_notifications`: flujo de recolecciones.
- `ra_internal_alerts`: bitácora operativa para eventos internos.
- `ra_app_settings`: configuración dinámica del sistema.

## Relación con Flutter, Scriptcase e IA

- Flutter consume la API PHP y depende de que la estructura de tablas y columnas coincida con los contratos esperados por la app.
- Scriptcase ejecuta los blanks que consultan y actualizan estas tablas para registrar operaciones y responder en JSON.
- La parte de IA puede apoyarse en esta base para persistir metadatos, documentos procesados o resultados normalizados, pero conviene mantener la lógica de inferencia desacoplada del núcleo transaccional.

## Buenas prácticas operativas

- Mantén `ra_internal_alerts` y las tablas de notificación como parte de la trazabilidad del sistema.
- Evita ejecutar scripts manualmente sin respaldo previo.
- Conserva este directorio como fuente única de verdad para instalaciones y migraciones.
- Si haces un cambio estructural, acompáñalo con verificación funcional en la app Flutter y en los endpoints PHP.