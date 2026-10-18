# Indicador de conexión del trabajador

La cabecera dejó de mostrar permanentemente el punto verde y «En linea».
Ahora muestra tres estados: «Verificando conexión…» (ámbar), «En línea» (verde)
y «Sin conexión» (rojo). El texto se ajusta al ancho disponible de la cabecera.

Se comprueba la comunicación con Firestore mediante una consulta del perfil
autenticado con `Source.server`, usando la fuente existente de asistencia.
Una lectura desde caché o solo tener Wi-Fi activado no confirman el estado.
Si la consulta falla o tarda más de cinco segundos, no se confirma acceso al
servidor y aparece «Sin conexión». Esto describe el acceso a Firebase, no un
diagnóstico de todas las conexiones o servicios de internet del dispositivo.

La comprobación ocurre al entrar, al volver del segundo plano y al pulsar
actualizar/reintentar. Mientras la pantalla permanece activa, se repite un minuto
después de finalizar la consulta anterior. En segundo plano se suspende y al
cerrar la pantalla se liberan temporizadores y listeners. Las respuestas tardías
de una comprobación anterior no sobrescriben el estado nuevo.

La detección no es instantánea: un corte con la app visible puede tardar
aproximadamente un minuto más el tiempo de comprobación. Se puede pulsar
actualizar para verificar antes. Cada comprobación consulta un documento y
consume la cuota normal de lecturas de Firestore; no se agregaron servicios,
dependencias de red, Cloud Functions ni facturación.

El indicador es informativo y no sustituye las validaciones al marcar ni las
reglas de Firestore. No se cambiaron los horarios, GPS, reconocimiento facial,
autenticación ni el guardado de asistencias.

Pruebas nuevas: transición entre estados, timeout, respuestas tardías, pausa y
reanudación, cierre durante una consulta y los tres textos en una pantalla de
320 píxeles sin desbordamientos. Los tests no consultan Firebase real.

Para comprobarlo en el celular, instalar el APK actualizado, abrir la asistencia,
desconectar internet y pulsar actualizar o esperar la siguiente comprobación.
Al reconectar y actualizar, debe volver a confirmar «En línea» si Firebase
responde. No se realizó esta prueba en un dispositivo físico desde aquí.

Verificación final: 122 pruebas Flutter aprobadas, análisis estático sin
incidencias y compilación Android debug correcta. APK disponible en
`build/app/outputs/flutter-apk/app-debug.apk`.
