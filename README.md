# security_set_drt

Proyecto para el control de accesos y recepción de paquetes/visitas, compuesto por una aplicación móvil Flutter y una API/administración en PHP (Scriptcase).

## Descripción

Este repositorio contiene la solución usada por el equipo para gestionar entradas, paquetes y notificaciones en instalaciones corporativas. La app móvil (Flutter) interactúa con blanks PHP generados por Scriptcase que ejecutan las operaciones sobre la base de datos MySQL y disparan notificaciones (WhatsApp / correo) en segundo plano.

## Por qué funciona así

La arquitectura prioriza la experiencia de usuario: los registros (paquetes, recolecciones, check-in de visitas) confirman inmediatamente que la acción fue grabada, y el envío de notificaciones se realiza "por debajo" para no hacer esperar al usuario. Esto mejora la percepción de velocidad y resiliencia frente a latencias externas.

## Enfoque y buenas prácticas

- Autores y responsable: Miguel Avila Requena
- Uso de automatizaciones e IA: la solución fomenta el uso de herramientas de asistencia (IA) y prácticas reproducibles para mejorar mantenibilidad y acelerar tareas rutinarias.
- Separación de responsabilidades: operaciones de persistencia y notificación separadas para evitar bloqueos y timeouts en el cliente.
- Manejo explícito de timeouts y reintentos para integraciones externas (p. ej. Wasender API).

## Estructura del repositorio

- `flutter_app/`: Aplicación Flutter (cliente móvil)
- `scriptcase/` o `blanks/`: blanks y librerías PHP para Scriptcase
- `database/`: scripts SQL para crear/alterar tablas y datos de seed
- `assets/`: assets del proyecto (Lottie, imágenes)

## Requisitos previos

- Flutter SDK (para compilar la app móvil)
- PHP + Scriptcase (para los blanks/administración)
- MySQL o MariaDB
- Git y acceso a tu cuenta de GitHub (para push)

## Instalación rápida - Frontend (Flutter)

1. Abrir la carpeta `flutter_app`.
2. Instalar dependencias:

```bash
cd flutter_app
flutter pub get
```

3. Ejecutar en dispositivo/emulador:

```bash
flutter run
```

## Instalación rápida - Backend (Scriptcase / PHP)

1. Importar los scripts SQL dentro de `database/` en la base de datos.
2. En Scriptcase, desplegar los blanks desde la carpeta `scriptcase/blanks/` y asegurarse de incluir la librería `lib_runway_access_api.php`.
3. Configurar las variables de entorno / settings en `ra_app_settings` (p. ej. `wasender_api_url`, `wasender_api_key`, SMTP).

## Notas de despliegue

- El servidor PHP debe permitir `fastcgi_finish_request()` o el patrón de flush usado en `ra_json_response_then_continue()` para que las notificaciones se ejecuten después de enviar la respuesta al cliente.
- Ajusta los timeouts en las llamadas HTTP hacia servicios externos según la latencia esperada.

## Contribuir

Si quieres contribuir:

1. Haz fork del repositorio.
2. Crea una rama con un nombre descriptivo.
3. Envía un pull request con una descripción clara de los cambios.

## Contacto

Miguel Avila Requena — perfil: https://github.com/pimpledmikey

Gracias por revisar el proyecto. Si quieres, puedo:

- Añadir un CI básico para `flutter analyze` y `flutter test`.
- Preparar un script de despliegue para el backend.

