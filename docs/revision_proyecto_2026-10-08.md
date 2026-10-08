# Revisión del proyecto — 8 de octubre de 2026

## Alcance y límites

Revisión estática de los flujos de autenticación, sesión, asistencia, calendario, GPS, detección facial, historial, exportación, administración de trabajadores y sedes, regularización, reglas locales de Firestore y configuración Android. No se cambiaron reglas ni datos de Firebase ni se realizaron marcaciones reales. Este informe no certifica el estado del servicio remoto ni que sus reglas coincidan con el archivo local.

La última ejecución general registrada en esta conversación aprobó 88 pruebas antes de los últimos ajustes visuales. No se ejecutó nuevamente la suite en esta revisión. El intento de analizar los últimos colores fue bloqueado porque el sistema de aprobación alcanzó su límite de uso; no fue un diagnóstico de error en el código. Las compilaciones previas del APK no validan el estado actual de todos los archivos.

## Hallazgos prioritarios

### 1. Alta: las reglas no validan la integridad de una marcación

`firestore.rules:28`: un usuario activo puede crear una asistencia si `usuarioId` coincide con su UID. No se exige una estructura de campos, ID único por evento, horario válido, sede asignada ni secuencia entrada/salida. Las comprobaciones de GPS y rostro son datos enviados por el cliente. Un cliente modificado podría saltarse controles aunque la interfaz normal los cumpla. Los IDs deterministas del cliente actualizado y la prohibición de modificar marcas para trabajadores ayudan contra duplicados normales, pero la regla permite crear otro documento con otro ID.

Acción: diseñar reglas que validen campos, tipos, pertenencia a sede y unicidad/secuencia usando un esquema verificable; probarlas con emulador antes de publicar. Las reglas por sí solas no pueden acreditar que una foto o una coordenada enviada sea auténtica. No es necesario reintroducir Cloud Functions para mejorar estas comprobaciones.

### 2. Alta si se exige identidad: hay detección facial, no reconocimiento del trabajador

`fuente_datos_detector_rostro_mlkit.dart` solo comprueba que haya exactamente un rostro. No compara con una plantilla del usuario ni verifica que sea una persona presente frente a la cámara. `rostroValidado` puede inducir a pensar que la identidad fue confirmada. La nueva asistencia guarda `urlEvidenciaFacial: null` (`controlador_asistencia.dart:659`).

Acción: nombrar correctamente esta función y definir por separado el requisito de reconocimiento de identidad y prueba de presencia. No considerar la detección actual una verificación biométrica de identidad.

### 3. Alta: reportes administrativos incompletos al superar 300 marcas

`fuente_datos_asistencias_firestore.dart:103` limita la consulta general a 300 documentos. Tanto el dashboard como el módulo administrativo consumen esa consulta y luego agrupan/filtran localmente. El límite puede cortar una jornada y mostrarla como incompleta, además de excluir registros anteriores del rango buscado. No es pérdida de datos en Firestore; es una lectura parcial.

Acción: consultar por rango y paginar, con una estrategia que no corte jornadas en resúmenes o informes completos. El historial personal descarga todos los documentos del usuario; necesita paginación a futuro para evitar que el costo de lectura y tiempo de carga crezcan sin límite.

### 4. Alta: las notas normales producen falsas observaciones

`controlador_asistencia.dart:658` asigna siempre «Marcacion generada desde la pantalla del trabajador». En `modulo_asistencias_admin.dart:1206` y `modulo_dashboard_admin.dart:525`, cualquier observación no vacía convierte una jornada completa en «Observada». Así, una jornada normal con todas sus verificaciones puede quedar observada únicamente por esta nota.

Acción: separar la procedencia del registro de las incidencias reales y unificar los estados. El historial personal sí evalúa tardanza y salida anticipada; el administrador no usa esos criterios de la misma forma. No basta con borrar la nota sin revisar también esa diferencia.

### 5. Alta: el dashboard no evalúa la jornada por bloques

`modulo_dashboard_admin.dart:516` considera completa una jornada con cualquier entrada y cualquier salida. Para Plataforma, tener solo 08:30 y 13:00 ya satisface esa condición aunque falte toda la tarde. El módulo administrativo de asistencias sí usa `resumen.tramos.every(...)`, por lo que los dos módulos pueden discrepar.

Acción: reutilizar el mismo resumen de jornada para dashboard, historial y administración, incluyendo sábado y domingo. Los indicadores agrupan días con registros; no representan automáticamente ausencias de quienes no marcaron nada.

### 6. Media: GPS sin control de antigüedad o precisión

Al abrir el proceso se solicita ubicación. Al confirmar, `controlador_asistencia.dart:507` solo vuelve a solicitarla si el resultado es nulo. Si el usuario espera o se desplaza con la ventana abierta, puede confirmar con una ubicación anterior. La fuente GPS solicita alta precisión, pero no evalúa el margen de error real, antigüedad ni señal de ubicación simulada; tampoco fija un tiempo máximo de espera.

Acción: guardar instante y precisión de la lectura, volver a validar si caducó y manejar demoras. Estas comprobaciones reducen errores; no garantizan por sí solas que el dispositivo sea confiable.

### 7. Media: cargo y sede pueden quedar desactualizados durante una sesión

La compuerta escucha el estado activo del usuario, pero el controlador carga cargo y sede como una instantánea. Registrar vuelve a leer el historial, no el perfil laboral ni la configuración actual de la sede. Si el administrador cambia la asignación mientras la app está abierta, puede seguir usando los datos previos hasta refrescar/cargar el perfil. Las reglas actuales tampoco verifican esa asignación al crear la marca.

Acción: refrescar la información autorizante antes de marcar o escuchar sus cambios; conservar el horario histórico de las marcas ya registradas.

### 8. Media: «En línea» es un texto fijo

`cabecera_trabajador_panel.dart:86` muestra siempre ese estado. No está conectado al estado de red ni a una comprobación de Firebase.

Acción: informar conectividad comprobada o sustituir el mensaje por un estado que no prometa conexión. Actualmente sí se consulta el historial con `Source.server` antes de registrar, pero perder conexión después de esa lectura puede dejar una escritura esperando confirmación. No hay un plazo de recuperación explícito para esa espera; también se pospone el cierre por inactividad mientras la operación siga pendiente.

### 9. Media: un documento sin fecha válida se interpreta como actual

`modelo_asistencia.dart:80` reemplaza una fecha ausente o de tipo incorrecto por `DateTime.now()`. Un registro defectuoso podría aparecer como de hoy y afectar resúmenes o validaciones. Otros tipos incorrectos pueden lanzar excepciones durante la lectura.

Acción: detectar y aislar documentos inválidos, sin inventar una fecha; reforzar el esquema al escribir.

## Decisiones actuales que deben conocerse

- **Hora del dispositivo:** las ventanas, fecha, tardanza y cierre por inactividad usan el reloj local. No se fuerza la hora de Perú ni se confirma hora en servidor. Es la limitación que el usuario decidió mantener; no se alteró.
- **Asesor, lunes a viernes:** entrada programada 08:30, visible 08:00–18:19; salida programada 18:30, visible 18:30–19:30. Sin descuento de receso en el cálculo actual: 08:30–18:30 suma 10 horas.
- **Plataforma, lunes a viernes:** entradas 08:00–12:59 y 14:50–18:19; salida a receso 12:50–14:59 y final 18:30–19:30. Programación 08:30, 13:00, 15:00 y 18:30. El receso 13:00–15:00 no suma tiempo laborado.
- **Sábado, ambos cargos:** un bloque 08:30–15:00, sin receso. Entrada 08:00–14:59 y salida 15:00–16:00. Una jornada exacta suma 6 h 30 min.
- **Domingo:** sin ventanas para horarios reconocidos. El nuevo calendario rige desde 08/10/2026; los días anteriores y registros clasificados como históricos conservan su interpretación previa.
- **Sin entrada:** no se habilita la salida de ese bloque. Si Plataforma tiene entrada mañana sin salida a receso, no puede iniciar tarde; si no tiene ninguna marca de mañana, sí puede registrar tarde dentro de su ventana.
- **Sin marcas de todo el día:** no se genera automáticamente una ausencia ni tardanza acumulada. Esa función no está implementada y el usuario pospuso el cambio.
- **Correo institucional:** el formulario comprueba campos vacíos y Firebase valida las credenciales/formato. No hay restricción por dominio institucional. No cambiar esto sin definir los correos permitidos.
- **Sesión móvil:** casilla de mantener sesión; sin marcar, límite de 15 minutos, incluido tiempo en segundo plano. El panel web no comparte esa política de inactividad.
- **PDF/Excel:** generan datos filtrados; mantienen columnas fijas de receso y tarde aunque una jornada continua no las use. El texto «--:-- indica un dato pendiente» resulta impreciso para columnas que no aplican. Los valores horarios de salida continua sí se colocan en salida final.
- **Textos administrativos:** persisten referencias a «cuatro marcaciones», «dos bloques» y «sede principal» que no aplican a todos los cargos, sábados o sedes.

## Aspectos correctamente contemplados en el código

- Firebase Authentication identifica la cuenta y Firestore almacena el perfil y sus permisos. No se guardan contraseñas en el perfil.
- La compuerta del trabajador distingue caché, espera de servidor, perfil inactivo y perfil inexistente; permite reintentar.
- La interfaz evita envíos simultáneos al iniciar sesión y al registrar. Las reglas locales impiden al trabajador modificar asistencias existentes.
- El alta usa una instancia auxiliar de Auth para preservar la sesión del administrador y contempla recuperación de un alta incompleta sin eliminar una cuenta ante resultados ambiguos.
- Editar el trabajador conserva campos ajenos al cambio, impide cambiar solo el correo de Firestore y evita quitarse el acceso desde el formulario administrativo.
- La regularización conserva metadatos de las marcas existentes, comprueba orden cronológico y actualiza la jornada mediante una transacción con detección de conflictos.
- Hay soporte de sedes con coordenadas, radio y estado activo; el cliente comprueba los datos antes de marcar. No se verificaron las coordenadas reales de Huancayo o Satipo.
- No se encontraron dependencias o llamadas activas a Cloud Functions o Firebase Storage en `lib` y `pubspec.yaml`. Eso no demuestra que no queden funciones remotas antiguas.
- Los colores del acceso y del interior están separados mediante constantes; los cambios recientes de color no son cambios de horario ni permisos.

## Publicación y pruebas pendientes

- `android/app/build.gradle.kts:40` sigue firmando release con la clave de depuración; los APK generados en esta conversación son de prueba. Preparar firma definitiva y estrategia de versionado antes de distribución formal.
- El manifiesto principal no declara INTERNET; sí aparece en debug y profile. Solo hay un manifiesto fusionado debug disponible. Revisar el manifiesto release resultante antes de afirmar que tendrá o no conectividad, ya que también intervienen dependencias.
- Verificar en emulador las reglas efectivas: trabajador creando documento con ID arbitrario, secuencia inválida, sede distinta y fecha fuera de ventana. No realizar estos intentos en producción.
- Probar sin conexión antes de marcar y con pérdida de conexión entre consulta y escritura; verificar que nunca se anuncie éxito sin confirmación y que exista recuperación clara.
- Probar dashboard con Plataforma a mediodía, jornada completa, sábado, domingo y más de 300 marcas.
- Probar cambio de sede/cargo/activo con la app abierta, GPS lento o impreciso y cámara cancelada.
- Repetir análisis, suite Flutter y pruebas visuales cuando esté disponible la ejecución autorizada. Revisar contraste de los acentos turquesa claros en texto pequeño y estados seleccionados.

## Orden propuesto

Primero cerrar las validaciones de Firestore y corregir los estados administrativos (hallazgos 1, 4 y 5). Después corregir consultas incompletas y actualización de perfil/GPS (3, 6 y 7). Continuar con recuperación de red, datos inválidos, textos e informes (8 y 9). El reconocimiento de identidad es un proyecto separado si se exige esa garantía; la detección actual no la proporciona.
