# Retiro del almacenamiento de alertas — 17 de octubre de 2026

El usuario solicitó retirar el almacenamiento de intentos fallidos, conservando
las validaciones y los mensajes de error. Solicitó dejar el APK preparado para
instalar después; no se actualizará el teléfono durante esta tarea.

## Cambios

- El controlador ya no consulta, guarda ni mantiene una lista de alertas.
- Se retiraron repositorios, fuentes, casos de uso y modelos del módulo
  `alertas`, junto con sus dependencias en la fábrica del controlador.
- Los rechazos locales conservan el mensaje original. No se retiró ninguna
  condición de ubicación, rostro, horario, secuencia, sesión o dispositivo.
- El historial y las marcaciones siguen guardándose en `asistencias`.
- Las reglas retiran el acceso a `alertas`, de modo que los clientes no pueden
  recrearla. Las reglas de asistencia, usuarios y biometría no cambian respecto
  a la versión validada en el retiro de auditorías.
- Se preparó la versión Android **1.1.3+5** para retirar también las consultas
  desde el teléfono cuando el usuario instale la actualización.

## Compatibilidad con la app anterior

El controlador anterior captura los errores al guardar una alerta. La lectura
complementaria inicial y la recarga posterior a una marcación también están
protegidas por manejo de errores. No se necesita una alerta para aceptar o
rechazar una marca ni para mostrar su motivo.

Por ello, las reglas nuevas impiden que la versión anterior vuelva a llenar la
colección. Esa versión todavía puede intentar las solicitudes que serán
denegadas; el APK nuevo elimina también esos intentos de lectura y escritura.
No se afirma que el código instalado en el teléfono ya haya sido actualizado.

## Respaldo y eliminación

Resultado remoto confirmado: se publicaron la web y las reglas, se verificó el
hash de la versión servida y se eliminaron las **46 alertas**. La colección dejó
de aparecer en la lista de Firestore. Todos los documentos de las demás
colecciones conservaron su `updateTime` en la comprobación posterior.

Los archivos privados están en
`respaldos_locales/firebase/2026-10-17/retiro_alertas/`, excluidos de Git:

- `codigo-antes/`: archivos anteriores con extensión de respaldo.
- `reglas-publicadas-antes.json`: copia de las reglas activas antes del cambio,
  comprobadas contra la base local editada.
- `firestore-antes.json`: copia inicial de las 46 alertas e inventario del resto.
- `firestore-final-antes.json`: respaldo actualizado inmediatamente antes del
  borrado, una vez comprobada la publicación de las reglas nuevas.
- `operacion.json`: rutas exactas, versiones, hash del respaldo y resultado.
- `firestore-despues.json`: inventario de verificación posterior.

El script de eliminación solo acepta documentos de `alertas` en el proyecto
`asistenciageolocalizacio-368fc`. Comprueba que no haya subcolecciones sin
respaldar y aplica precondiciones de `updateTime` para cancelar ante cambios.
Después confirma que la colección no se liste y que los demás documentos
conserven sus versiones. No borra cuentas ni asistencias.

## Pruebas

- **75 pruebas Flutter aprobadas** de marcación actualizada, horarios,
  calendario, GPS reciente, cámara, conexión y pantallas relacionadas.
- Dos casos nuevos comprueban que un rostro rechazado o un error de análisis
  mantienen el mensaje y bloquean la marca sin depender de alertas.
- **134 pruebas de reglas aprobadas** en el emulador local, incluidas la
  denegación de lectura/escritura de alertas y las protecciones biométricas.
- Análisis general sin incidencias tras evitar que el analizador interpretara
  un `pubspec.yaml` de respaldo como otro proyecto Flutter.

La web y las reglas deben publicarse antes de retirar los documentos. La firma,
el paquete y la versión del APK se verifican al finalizar la compilación.

## APK entregado

Compilación release finalizada correctamente: **1.1.3+5**, paquete
`com.example.flutter_application_1`, en
`build/app/outputs/flutter-apk/app-release.apk`.

- Firma válida, con el mismo certificado que el APK anterior disponible.
- Tres arquitecturas incluidas: ARM de 32 bits, ARM de 64 bits y x86 de 64 bits.
- Se conservaron los modelos Yunet y SFace dentro del APK.
- SHA-256: `4C8219949E14D0DBAEFB64FC613F9D4EA85C39C583C6007964A22147594E152C`.
- No se instaló en el teléfono, conforme a la indicación del usuario.

La comprobación completa quedó en `verificacion-apk.json`, junto con los
respaldos privados de esta tarea. La verificación física de cámara/GPS en el
teléfono corresponde a cuando el usuario instale la actualización.
