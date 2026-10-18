# Pruebas de reglas Firestore

Estas pruebas usan exclusivamente `demo-asiscredi-reglas` en el emulador local
`127.0.0.1:8185`. No necesitan credenciales ni escriben datos en producción.
El test rechaza otro host antes de inicializar Firebase. Las dependencias Node
son herramientas de desarrollo separadas de las dependencias Flutter.

## Ejecución

Requisitos: Node.js 20 o posterior, Firebase CLI y Java 21. En Windows, configurar
`JAVA_HOME` con un JDK compatible (por ejemplo el JBR de Android Studio) y añadir
su carpeta `bin` al `PATH` de la terminal.

Desde la raíz del repositorio:

```powershell
npm --prefix test/firestore ci --ignore-scripts
firebase emulators:exec --only firestore --project demo-asiscredi-reglas --config firebase.emulators.json "npm --prefix test/firestore test"
```

Se carga `firestore.rules`. Antes de cada caso se vacía únicamente el proyecto
demo del emulador y se crean perfiles/sedes ficticios con las reglas desactivadas.
Las operaciones que se prueban sí pasan por las reglas. Ningún comando anterior
publica reglas ni activa Cloud Functions o facturación.

## Cobertura y resultado

El 9 de octubre de 2026: **105 pruebas aprobadas, 0 fallidas**.

- Autenticación, perfil activo, propiedad de datos, lectura filtrada y permisos administrativos.
- Contrato del mapa que escribe `ModeloAsistencia.aMapa`, tipos inválidos y campos ausentes/adicionales.
- IDs deterministas compatibles con Dart, incluidos padding y caracteres UTF-8.
- Duplicados con igual/distinto ID y dos dispositivos escribiendo simultáneamente.
- Todas las ventanas horarias, con el segundo anterior, inicio, último segundo permitido y siguiente minuto.
- Lunes a viernes, sábado continuo y domingo no laborable para ambos cargos.
- El cargo Auxiliar de operaciones conserva la validación del horario partido de Plataforma.
- Secuencia, salida sin entrada, mañana abierta y tarde sin marcas de mañana.
- Cambio de cargo durante una jornada y conservación del horario original.
- Cambio de sede, sede inexistente y alias de sede principal.
- Regularización del administrador y continuación de marcas canónicas regularizadas con GPS/rostro falsos.
- Calendario previo al 8/10/2026, horario histórico y conservación de la decisión de usar el reloj del dispositivo.
- Compatibilidad pendiente documentada para entradas antiguas con identificadores aleatorios.

## Límites que no deben confundirse con garantías

Las pruebas verifican autorizaciones, no reconocimiento facial ni autenticidad
del GPS. Los horarios se comparan con el timestamp enviado, interpretado en Perú
(UTC-5), no con `request.time`. La hora puede seguir siendo manipulada por un
cliente que cambie el reloj o envíe datos directamente.

Un registro con ID antiguo sigue siendo legible y editable por el administrador.
Si se pretende continuar esa misma jornada desde la app, la regla no puede
buscar entradas por ID aleatorio: requiere revisar esa jornada antes de publicar.
No se incorpora una excepción abierta para saltarse esta verificación.

Las pruebas y los fixtures no se incluyen en el APK ni en la compilación web.
