# Revisión de reglas Firestore — 9 de octubre de 2026

> Estado actualizado al 11/10/2026: reglas reforzadas publicadas y verificadas
> tras autorización del usuario. Las secciones del 9/10 describen la preparación
> anterior a la publicación; el resultado final aparece al final del documento.

## Alcance y resultado

Revisión de solo lectura de las reglas locales, su versión publicada y la escritura de asistencias. No se modificaron ni publicaron reglas, no se escribieron datos reales ni se activaron servicios o facturación.

Proyecto: `asistenciageolocalizacio-368fc`.

- Release consultado: `projects/asistenciageolocalizacio-368fc/releases/cloud.firestore`.
- Ruleset activo: `ed840cd7-7cf2-4130-afb3-effb9282c35e`.
- Última actualización del release: `2026-09-25T16:05:12.553368Z`.
- El archivo publicado coincide con `firestore.rules`, normalizando saltos de línea y espacios exteriores.
- La consulta utilizó la sesión existente de Firebase CLI y la API de reglas; no necesitó leer documentos de trabajadores.

## Protecciones confirmadas

- Una persona sin autenticación no puede leer ni escribir las colecciones declaradas.
- Un usuario autenticado puede consultar su propio perfil, incluso si está inactivo; esto permite que la app compruebe su estado.
- Para crear su asistencia, el trabajador debe tener un perfil activo y enviar su propio `usuarioId`.
- El trabajador solo puede leer sus asistencias y no puede actualizarlas ni borrarlas.
- La administración requiere perfil activo y rol `administrador`.
- Los trabajadores no pueden cambiar perfiles ni sedes.
- Las alertas del trabajador requieren su propio identificador y `atendida == false`.
- No existe una regla general que abra otras colecciones.

## Validaciones ausentes en la creación de asistencias

| Condición | Resultado actual |
| --- | --- |
| Campos obligatorios, tipos y campos adicionales | No se validan, salvo el valor de `usuarioId` |
| Sede asignada y existencia de sede | No se comprueban |
| Tipo de marcación, horario y bloque permitidos | No se comprueban |
| Ventana horaria, sábado y domingo | No se comprueban |
| Entrada previa para una salida y secuencia entre bloques | No se comprueban |
| Identificador único por trabajador, fecha, bloque y tipo | No se exige |
| Fecha enviada comparada con hora del servidor | No se comprueba |
| Coordenadas y resultados de las validaciones de ubicación/rostro | No se comprueban |

Estas carencias no prueban que haya ocurrido manipulación. Sí permiten que un trabajador activo envíe directamente datos inconsistentes a su nombre sin pasar por los controles de la interfaz.

### Matiz sobre duplicados

La app actual genera un identificador determinista mediante `idMarcacionPorBloque`: `marcacion_<uid en base64Url>_<AAAAMMDD>_<bloque>_<tipo>`. Como el trabajador no puede actualizar, repetir la escritura sobre ese mismo documento se rechaza. Sin embargo, las reglas permiten crear otro documento con un identificador diferente y el mismo evento. Por tanto, hay protección en el flujo actual, pero falta exigirla en la base de datos.

## Compatibilidad que debe resolverse antes de reforzar reglas

1. **Identificadores e historial:** comprobar la compatibilidad del formato base64Url actual con la validación propuesta; contemplar registros antiguos y regularizaciones con identificadores diferentes. Una regla sobre nuevos identificadores no elimina duplicados históricos.
2. **Horario de la jornada:** la app conserva el horario guardado en las marcaciones del día. Compararlo siempre contra el cargo actual puede impedir completar una jornada si el cargo cambia durante el día.
3. **Hora:** el sistema usa `DateTime.now()` del dispositivo por decisión previa. Exigir igualdad con `request.time` rompería el envío actual. Cualquier control basado en hora del servidor necesita definir antes zona horaria y tratamiento de diferencias de reloj.
4. **Sede:** comprobar el perfil actualizado al registrar para evitar rechazos inexplicables si se cambia la sede con una sesión abierta.
5. **Administrador:** conservar la regularización autorizada de fechas anteriores, metadatos originales y marcas manuales con GPS/rostro en falso. No aplicar sin distinción las restricciones del trabajador a estas operaciones.
6. **Ubicación y rostro:** exigir booleanos verdaderos solo valida lo declarado por el cliente; no demuestra ubicación física, identidad ni prueba de vida. Las reglas no ejecutan reconocimiento facial.

## Propuesta de implementación posterior

Preparar reglas y pruebas en emulador antes de publicar. Primero validar estructura, valores permitidos, pertenencia y unicidad; después incorporar horario y secuencia preservando los casos anteriores. No cambiar silenciosamente el criterio de hora del dispositivo.

Casos mínimos: acceso anónimo/inactivo, acceso a datos ajenos, entrada/salida válida de Asesor, cuatro marcas de Plataforma, sábado de ambos cargos, domingo, límites de ventanas, duplicado con el mismo y distinto ID, salida sin entrada, cambio de cargo/sede durante el día, datos incompletos o inválidos y regularización administrativa. Usar usuarios y datos sintéticos.

No se ejecutaron escrituras de prueba contra producción. No hay cambios de código que requieran recompilar la app en esta revisión. La publicación y las pruebas de reglas reforzadas quedan fuera de esta revisión.

## Referencias

- Código: `firestore.rules`, `ModeloAsistencia.aMapa`, `RepositorioAsistenciasImpl`, `idMarcacionPorBloque`, `FuenteDatosAsistenciasFirestore` y controladores de marcación/jornada.
- [Firebase: validación de datos con reglas](https://firebase.google.com/docs/rules/data-validation).
- [Firebase: introducción a las reglas de Cloud Firestore](https://firebase.google.com/docs/firestore/security/get-started).

## Implementación local posterior a la revisión

Tras la autorización del usuario, se preparó el refuerzo en `firestore.rules`.
La comparación con producción documentada arriba corresponde al estado anterior
a estos cambios. **Las reglas reforzadas no se han publicado.**

Se añadieron validaciones de estructura y tipos de las nuevas asistencias del
trabajador, sede asignada y existencia, valores de horario/bloque/tipo,
identificador canónico, ventanas horarias y secuencia. Se conserva el horario
de la primera marca canónica del día aunque cambie el cargo. La normalización
de cargo y los alias de sede principal siguen los criterios existentes en la app.

Se preservan los permisos actuales de consulta, perfiles, sedes y alertas, así
como la regularización del administrador. La edición administrativa de registros
antiguos y los valores GPS/rostro falsos de marcas manuales continúan permitidos.
No se cambiaron el código Flutter, su apariencia, los cálculos, Auth ni las horas
de las ventanas existentes.

### Verificación realizada

- Emulador Firestore, proyecto aislado `demo-asiscredi-reglas`: **105 pruebas
  aprobadas, 0 fallidas**. El emulador compiló y evaluó las reglas propuestas.
- Los errores iniciales de sintaxis y numeración del día semanal detectados
  durante la preparación se corrigieron antes de la ejecución final aprobada.
- Se consultaron en producción únicamente los metadatos necesarios de las
  marcaciones del 9/10/2026 en Perú, sin nombres, coordenadas ni imágenes.
  Resultado: **4 marcaciones, las 4 con ID canónico y metadatos de horario/bloque**.
  La consulta no alcanzó el límite de 1001 documentos. No se detectaron IDs
  antiguos en las jornadas de ese día; esto no certifica todo el historial.
- No se ejecutaron escrituras de prueba contra producción ni se publicaron reglas.
- El cambio no necesita recompilar Flutter: afecta a reglas y pruebas de desarrollo.

### Condiciones de publicación y límites

1. Las reglas ahora rechazan sedes distintas de la asignada en el perfil vigente.
   Tras un cambio de sede, una sesión que mantenga el perfil anterior deberá
   actualizarlo antes de registrar.
2. La fecha/hora enviada se interpreta en Perú (UTC-5). El dispositivo debe usar
   esa zona para que el ID que genera la app y las ventanas coincidan. No se exige
   igualdad con el reloj del servidor ni se elimina la posibilidad de falsear la
   fecha/hora desde un cliente manipulado. No se activó un servicio de hora.
3. Los IDs antiguos no se migran. El historial y la administración siguen
   funcionando, pero una jornada abierta con una entrada de ID aleatorio requiere
   revisión antes de activar la secuencia estricta. La consulta de hoy no encontró
   ese caso. La unicidad exigida a nuevas marcas no detecta automáticamente otro
   documento antiguo con el mismo evento ni limpia duplicados históricos.
4. Validar `dentroDeZona` y `rostroValidado` como verdaderos no certifica GPS,
   identidad ni prueba de vida; siguen siendo resultados declarados por la app.
5. La publicación cambia las autorizaciones reales de escritura. Revisar de nuevo
   las jornadas abiertas y la versión publicada antes de ejecutarla, para evitar
   sobrescribir cambios remotos posteriores. Mantener una copia del ruleset activo
   identificado arriba para poder restaurar las reglas anteriores si fuera necesario.

La ejecución reproducible y la cobertura están en `test/firestore/README.md`.

## Publicación autorizada — 11 de octubre de 2026

- Se confirmó que las reglas remotas seguían siendo las revisadas originalmente.
- Se guardó su contenido y la referencia del release en `docs/respaldos/`.
- Firebase validó la compilación sin errores antes de publicar.
- La consulta de metadatos del 11/10/2026 en Perú devolvió cero marcaciones;
  no había jornadas de ese día con IDs antiguos que bloquearan la publicación.
- Se ejecutó `firebase deploy --only firestore:rules --project asistenciageolocalizacio-368fc --non-interactive`.
- Firebase confirmó la publicación. Una lectura posterior verificó que el
  ruleset activo coincide con el archivo local (normalizando saltos de línea).
- Nuevo ruleset: `e082a2dc-9d04-4818-858d-43d3018f2194`.
- Actualización del release: `2026-10-11T16:39:13.836089Z` (11:39:13 de Perú).
- SHA-256 del archivo local: `13272640a1b165f6a6e0b68534be444a062c7c010a65e52d1335eb53e251c666`.
- Comprobante: `docs/respaldos/firestore-publicado-2026-10-11.json`.

Solo se publicaron reglas de Firestore. No se desplegaron Cloud Functions, no se
modificó la facturación ni se escribieron/eliminaron asistencias reales. No se
probó una marcación real en el celular. Siguen vigentes los límites documentados
sobre reloj del dispositivo, zona de Perú, IDs históricos y GPS/rostro declarados.
