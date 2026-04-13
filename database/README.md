# Database scripts

Instrucciones para importar y respaldar la base de datos MySQL/MariaDB usadas por este proyecto.

## Archivos

- `ra_*` y `runway_access_*.sql` — scripts de esquema y alteraciones.
- `runway_access_seed.sql` — datos semilla (ej. app settings, usuarios de ejemplo).

## Importar en una base de datos nueva

1. Crear la base de datos (ejemplo):

```bash
mysql -u root -p -e "CREATE DATABASE runway_access CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

2. Importar el esquema y seed (orden recomendado):

```bash
mysql -u root -p runway_access < runway_access_schema.sql
mysql -u root -p runway_access < runway_access_seed.sql
```

3. Verificar tablas:

```bash
mysql -u root -p -e "USE runway_access; SHOW TABLES;"
```

## Respaldos (exportar)

Exportar toda la base de datos:

```bash
mysqldump -u root -p runway_access > runway_access_backup_$(date +%F_%H%M).sql
```

Exportar solo estructura (sin datos):

```bash
mysqldump -u root -p --no-data runway_access > runway_access_schema_only.sql
```

## Migraciones y control de versiones

- Mantén cambios de esquema en archivos separados con nombres que indiquen versión (p. ej. `runway_access_alter_v6.sql`).
- Aplica las alters en orden y registra la versión aplicada en una tabla `ra_migrations` si deseas automatizar.

## Logs y auditoría

- El proyecto usa tablas de auditoría (`ra_internal_alerts`, tablas de notificaciones) para seguimiento. No borres esas tablas al hacer limpiezas de datos; mejor exporta registros antiguos y archívalos.

## Buenas prácticas

- Haz backups antes de aplicar alters en producción.
- Prueba las migraciones en un entorno staging idéntico.
- Usa credenciales y usuarios de DB con permisos mínimos para la app.

Si quieres, pongo ejemplos de `ra_migrations` y un script sencillo de `apply_migrations.sh`.
