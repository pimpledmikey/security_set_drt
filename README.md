<div align="center">

# security_set_drt

### Sistema de Control de Acceso y Asistencia Empresarial

<p>
	<img src="https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.0+" />
	<img src="https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart 3.0+" />
	<img src="https://img.shields.io/badge/iOS-14%2B-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 14+" />
	<img src="https://img.shields.io/badge/Android-6.0%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android 6.0+" />
</p>

</div>

Proyecto para el control de accesos, asistencia, visitas, paquetes y recolecciones, compuesto por una aplicación móvil Flutter y una API/administración en PHP con Scriptcase.

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

## Base de datos y logs

Los scripts SQL se mantienen dentro de `database/` junto con la estructura de tablas de auditoría y logs (p. ej. `ra_internal_alerts`). Mantener la base de datos versionada permite:

- Restaurar estados en despliegues.
- Auditar eventos importantes (entradas, notificaciones, errores).
- Facilitar migraciones controladas (ALTERs con versiones).

## Integración: Flutter ↔ Scriptcase ↔ IA

Breve explicación técnica de la integración actual:

- La app Flutter actúa como cliente móvil y consume endpoints tipo "blanks" generados por Scriptcase (PHP). Estos endpoints realizan operaciones CRUD sobre MySQL y devuelven JSON.
- Para evitar que el cliente espere por operaciones lentas (envío de WhatsApp/correos), los blanks usan un patrón que envía la respuesta al cliente primero y luego continúa la ejecución del envío de notificaciones en segundo plano (`ra_json_response_then_continue()` + `fastcgi_finish_request()` cuando está disponible).
- La integración con servicios externos (p. ej. Wasender API para WhatsApp) se realiza mediante llamadas HTTP desde PHP con timeouts y manejo de errores; los resultados se registran en tablas de notificaciones para trazabilidad.
- El uso de IA se aplica en tareas de normalización y procesamiento de documentos, por ejemplo análisis y extracción de datos con modelos de lenguaje. Esta lógica se mantiene desacoplada del núcleo transaccional y se expone a través de la API para conservar un backend principal simple y estable.

