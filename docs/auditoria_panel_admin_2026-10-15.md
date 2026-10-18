# Auditoría del panel administrador — 15/10/2026

## Cambios

- Regularizar una jornada exige un motivo de 1 a 500 caracteres después de recortar espacios. La auditoría conserva el administrador, trabajador, fecha del servidor y horas anteriores/nuevas.
- Cada marca corregida o completada guarda `ultimaAuditoriaId`. La marca y su auditoría se confirman en la misma transacción.
- Las reglas locales exigen una auditoría nueva en la misma operación para las correcciones administrativas de asistencia. Comprueban trabajador, identificador de marca y fechas anterior/nueva. Las marcas existentes solo permiten corregir hora y observación, además del vínculo de auditoría; no permiten cambiar identidad, sede, horario o validaciones. No se permite borrar asistencias desde los clientes.
- Crear/editar un trabajador, guardar una sede y habilitar/aprobar/retirar una autorización biométrica desde el panel generan un registro en `auditoriaAdministrativa`, dentro de la misma transacción del cambio.
- Los registros generales usan campos seleccionados. No contienen contraseñas, tokens del dispositivo, imágenes ni vectores faciales.
- La nueva sección **Auditoría** consulta ambas colecciones por categoría, ordena por fecha y carga 30 registros por página. Permite ver el detalle, sin editar ni eliminar registros.
- Las reglas solo permiten consultar las auditorías a administradores activos y prohíben su actualización o eliminación desde los clientes.
- Las auditorías históricas se conservan: si no tenían motivo se indica expresamente en pantalla.

## Alcance

La auditoría general registra las operaciones realizadas mediante estos servicios del panel. No es un registro de las operaciones efectuadas mediante Firebase Console o Admin SDK. Las reglas obligan a auditar las regularizaciones de asistencia; los demás servicios guardan su auditoría de forma atómica, pero mantienen los permisos administrativos existentes de sus colecciones.

No se reconstruyen cambios históricos que nunca se registraron ni se generan motivos ficticios.

## Verificación

- 30 pruebas de servicios, transacciones, regularizaciones y jornadas con varias sedes aprobadas.
- Prueba de consulta de auditorías antiguas y administrativas aprobada; se corrigió un desbordamiento del selector detectado por esa prueba.
- 134 pruebas de reglas aprobadas en Firestore Emulator, proyecto `demo-asiscredi-reglas`, loopback `127.0.0.1:8185`.
- Las pruebas no utilizan cuentas ni registros reales.

## Publicación realizada

Panel y reglas publicados conjuntamente el 15/10/2026 en el proyecto `asistenciageolocalizacio-368fc`.

- URL: https://asistenciageolocalizacio-368fc.web.app
- Compilación web de producción completada correctamente.
- Firebase confirmó la publicación de Hosting y Firestore Rules.
- Se verificó que las reglas remotas coincidan con el archivo local y que `index.html`, `flutter_bootstrap.js`, `main.dart.js` y `manifest.json` respondan HTTP 200 y coincidan por SHA-256 con la compilación.
- Evidencia: `docs/respaldos/panel-admin-publicado-2026-10-15.json`.
- Respaldo previo: `docs/respaldos/firestore-antes-panel-admin-2026-10-15.rules` y archivos JSON de reglas y Hosting de la misma fecha.

La publicación incluye los seis ajustes administrativos anteriores. Las versiones antiguas del panel sin motivo ni vínculo de auditoría no pueden regularizar con las reglas nuevas: recargar la página e iniciar sesión nuevamente cuando corresponda.

No se hicieron cambios de prueba sobre trabajadores ni asistencias reales durante la publicación. La verificación remota confirma la versión desplegada, no sustituye las pruebas manuales con una cuenta administrativa.
