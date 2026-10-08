# Auditoría del proyecto después de retirar Functions y Storage

Fecha: 1 de octubre de 2026. Alcance: código local actual, sin modificar lógica de producción, sin crear trabajadores reales ni publicar cambios.

## Resultado

**No está todo correcto todavía.** La limpieza de dependencias está hecha y las comprobaciones automáticas pasan, pero existen defectos funcionales y controles de integridad pendientes. Pasar las pruebas no certifica procesos que no están cubiertos por ellas.

Validación ejecutada en esta revisión:
- `flutter analyze --no-pub`: sin observaciones.
- `flutter test --no-pub`: 51 pruebas aprobadas.
- Revisión de acceso, alta/edición de trabajadores, modelos de usuario y asistencia, sedes, cálculo de horarios, controlador y proceso de marcación, fuentes de Firestore, historial, exportación, cámara, GPS y código Android de apertura de informes.
- Las compilaciones WEB y APK fueron aprobadas en la entrega inmediatamente anterior; no se repitieron en esta auditoría porque no se cambió el código.
- No se ejecutaron pruebas con cuentas reales, reglas desplegadas, GPS/cámara físicos ni entrega real del correo de recuperación. Las pruebas de administración usan dobles de Auth y Firestore, no emuladores de reglas.

## Hallazgos que requieren corrección

### 1. P1 — La regularización pierde el horario y el bloque originales

Ubicación: `lib/funcionalidades/admin/presentacion/widgets/modulo_asistencias_admin.dart`, método `_guardar`, construcción de `actualizada` y `nueva`, alrededor de líneas 809 y 835. Persistencia: `lib/funcionalidades/asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart:28`.

Al modificar una marcación se crea otra instancia de Asistencia sin copiar `tipoHorario` y `bloqueJornada`. El modelo omite esos campos y `.set(datos)` reemplaza el documento completo: se pierden los campos anteriores. Las marcas nuevas regularizadas tampoco reciben esos campos.

Ejemplo: regularizar las dos marcas de un Asesor puede dejar la jornada sin identificador de horario. Al reconstruirse como histórica, la salida de las 18:30 se clasifica en tarde y ya no se empareja con la entrada de mañana; puede desaparecer el total trabajado. Una entrada tardía de Asesor también puede pasar al bloque equivocado.

Corrección: regularizar con tipo de jornada y bloque explícitos, preservar los metadatos existentes y adaptar los campos de edición al cargo. Añadir regresiones que recorran edición, serialización y reconstrucción del resumen.

### 2. P1 — Las reglas locales no garantizan integridad de las marcaciones

Ubicación: `firestore.rules:28`.

Un trabajador activo puede crear cualquier documento de asistencia cuyo `usuarioId` coincida con su UID. Las reglas no exigen identificador determinista, estructura de campos, sede asignada, secuencia, horario ni unicidad por bloque. Un cliente modificado podría insertar un segundo documento con otro ID o datos arbitrarios para su propia cuenta.

La APP normal sí utiliza un ID por usuario/día/bloque/tipo y las reglas impiden su sobrescritura para trabajadores: eso reduce duplicados del cliente habitual, pero no es una garantía contra escrituras directas. No se comprobó que las reglas locales coincidan con las publicadas.

Corrección: definir un contrato validable de IDs/datos y reforzarlo con pruebas del emulador: usuario ajeno, perfil inactivo, doble evento, fecha/sede inválidas y permisos administrativos. La prueba de rostro real o GPS auténtico no se consigue simplemente aceptando booleanos enviados por el celular. Respetar la decisión previa de no cambiar silenciosamente el origen de la hora.

### 3. P1 — La jornada completa se evalúa de forma incompatible entre pantallas

Ubicaciones: `lib/funcionalidades/admin/presentacion/widgets/modulo_asistencias_admin.dart:1315` y `modulo_dashboard_admin.dart:509`.

Asistencias exige mañana Y tarde completas para todos. Un Asesor con entrada 08:30 y salida 18:30 tiene un único bloque válido, por lo que queda Pendiente en ese panel. El dashboard hace lo contrario: con cualquier entrada y cualquier salida considera completa la jornada, aunque un trabajador de Plataforma solo haya registrado la mañana.

Corrección: usar el mismo resumen por tipo de horario en APP, tabla administrativa, dashboard y reportes. Evaluar todos los tramos requeridos por ese horario, no un número fijo de bloques.

### 4. P2 — Marcaciones normales se presentan como observadas

Ubicaciones: `modulo_asistencias_admin.dart:1316`, `modulo_dashboard_admin.dart:510` y `controlador_asistencia.dart`, creación de asistencia.

El controlador escribe siempre la nota «Marcacion generada desde la pantalla del trabajador.». El panel convierte cualquier observación no vacía en una incidencia. Una jornada completa y normal de Plataforma puede aparecer Observada por esa nota informativa. Además, las condiciones de estado del panel no usan explícitamente tardanza/salida anticipada como sí lo hace el historial del trabajador.

Corrección: distinguir notas de origen de incidencias y centralizar también la evaluación del estado.

### 5. P2 — El panel filtra un máximo de 300 marcas, no el historial completo

Ubicación: `lib/funcionalidades/asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart:56`.

La consulta administrativa obtiene las últimas 300 marcaciones globales. Después se aplican filtros en memoria. Buscar un período anterior puede producir una lista vacía o jornadas incompletas aunque existan datos. Por ejemplo, 100 trabajadores de Plataforma pueden producir 400 marcas en un día y superar ese límite.

Corrección: consultar por rango de fechas y paginar; los resúmenes deben usar el conjunto completo requerido, no una lista global truncada.

### 6. P2 — El filtro móvil admite inicio posterior al fin

Ubicación: `lib/funcionalidades/asistencias/presentacion/paginas/pagina_inicio.dart:132`.

Los selectores son independientes. Al buscar se construye `DateTimeRange(start: inicio, end: fin)` sin comprobar el orden. Inicio 10/10 y fin 01/10 dispara una aserción en debug; en release puede dejar un rango sin resultados y sin explicación.

Corrección: validar el orden antes de construir el rango y mostrar un mensaje concreto. La prueba actual solo comprueba que se llaman los callbacks, no este caso.

### 7. P2 — GPS válido al abrir la hoja puede quedar desactualizado al confirmar

Ubicaciones: `pagina_inicio.dart`, `_abrirProcesoMarcacion`, y `controlador_asistencia.dart:497`.

La apertura de la hoja sí solicita una ubicación nueva. Sin embargo, al confirmar, el controlador solo la vuelve a pedir si el resultado es nulo. Un trabajador puede abrir la hoja dentro de la sede, desplazarse y confirmar después con el resultado anterior. El resultado no incluye antigüedad ni precisión; la fuente tampoco considera la precisión reportada antes de aceptar el radio.

Corrección: renovar ubicación al confirmar y definir un criterio de precisión/antigüedad. Verificar en un dispositivo real el radio de cada oficina y los permisos denegados.

### 8. P2 — Cambios de cargo y sede no se aplican automáticamente a una APP abierta

Ubicaciones: `compuerta_autenticacion.dart:58`, `pagina_inicio.dart:48` y botón de actualizar alrededor de línea 212.

La suscripción transforma el documento de usuario en un booleano de acceso. Si cambia sede/cargo manteniendo `activo=true`, la pantalla conserva su controlador y el perfil previamente cargado. El usuario necesita pulsar Actualizar o volver a entrar; antes de hacerlo puede usar la configuración anterior. La comprobación de sede/horario en reglas tampoco compensa este desfase.

Corrección: recargar perfil/sede al cambiar su configuración e invalidar GPS/captura asociados al proceso anterior. Mantener por separado el horario histórico de una jornada ya iniciada, cuya preservación es intencional.

### 9. P2 — La regularización no es atómica ni valida toda la secuencia

Ubicación: `modulo_asistencias_admin.dart`, `_guardar` desde la línea 778 aproximadamente.

Guarda cada marca con un await separado. Si falla a mitad, quedan cambios parciales y el aviso invita a reintentar. Los registros nuevos usan IDs aleatorios; un reintento puede duplicar lo ya escrito si el diálogo conserva el estado anterior. Solo se valida formato de hora, no toda la cronología de la jornada. También crea marcas manuales con `dentroDeZona=true` y `rostroValidado=true` sin haber realizado esas validaciones.

Corrección: validar jornada completa, guardar en un batch/transacción con IDs consistentes y registrar quién regularizó y por qué. Representar una regularización administrativa de forma distinta a una captura comprobada por sensores.

### 10. P2 — Operaciones asíncronas pueden notificar un controlador ya destruido

Ubicación: `controlador_asistencia.dart:168`, `172`, métodos de carga y `dispose:675`.

Al cerrar sesión o recibir la desactivación durante una consulta, la pantalla puede destruir el controlador. Las consultas pendientes todavía ejecutan bloques finally que llaman a notifyListeners, sin protección de descarte. Flutter puede reportar uso de ChangeNotifier después de dispose en debug. El detector facial también puede cerrarse mientras hay trabajo en curso.

Corrección: definir cancelación/descarte de resultados y controlar la salida mientras una operación termina. Probar desactivación/cierre de sesión con consultas demoradas y con la cámara abierta.

## Mejoras y límites adicionales

- Cargo sigue siendo texto libre. Solo Asesor/Asesora/Plataforma se convierten a horarios. Un cargo «Asesor comercial» queda sin marcación disponible aunque el panel lo acepte. Conviene un selector de horario explícito o cargo controlado (`modulo_trabajadores_admin.dart:769`).
- El trabajador vuelve a descargar todo su historial antes y después de marcar; las alertas tampoco se paginan. El consumo crece con los meses. Optimizar consultas diarias y reservar el rango completo para historial/exportación.
- CompuertaAdmin usa una lectura de perfil mediante FutureBuilder, no una suscripción de revocación. Las reglas deben bloquear operaciones tras desactivación, pero el contenido ya cargado puede permanecer visible. No confundir mantener la pantalla con permiso válido en servidor.
- Las coordenadas de las oficinas reales no se verificaron. La validación numérica de sede no demuestra que representen Huancayo o Satipo.
- Detección facial no equivale a reconocimiento de identidad ni prueba de vida. Se mantiene esta limitación deliberada; no se presenta como una capacidad ya implementada.
- La hora continúa dependiendo del dispositivo por decisión anterior. No se cambió en esta revisión.
- La firma Android release todavía usa la clave debug (`android/app/build.gradle.kts`). Antes de distribuir una versión definitiva se necesita una estrategia de firma; no se alteró el identificador de aplicación ni claves.
- El botón «Ir a ubicación» utiliza el selector de documentos Android. La ubicación inicial depende del proveedor del dispositivo; falta validar el recorrido real en el celular.
- Los SDK de Functions y Storage y el servidor local fueron retirados. Las cinco funciones remotas seguían presentes en la última consulta de esta conversación: Google rechazó su eliminación con 403 por facturación. La APP nueva no las invoca. No se volvió a activar facturación ni a intentar borrados en esta auditoría.

## Qué sí tiene evidencia favorable

- Horarios y límites de ventanas Asesor/Plataforma en el motor compartido, cálculo de tardanza y separación de bloques.
- Ejemplo de Plataforma 08:30–13:00 y 15:00–18:30 produce ocho horas. Se conserva la exclusión fija de 13:00 a 15:00 decidida previamente.
- Persistencia normal de horario/bloque en marcas de la APP, uso de ID determinista para ese flujo y consulta de historial al servidor antes de guardar.
- Alta con Auth auxiliar, conservación de sesión del administrador, protección contra reemplazo de perfil existente y recuperación del alta incompleta bajo las condiciones documentadas.
- Correo de acceso protegido contra edición parcial y contraseña recuperada por enlace.
- Bloqueo de contenido móvil cuando el perfil no se confirma activo; pruebas simuladas de desactivación.
- Exportación de los días filtrados a XLSX/PDF, conservación de cuatro eventos en Plataforma y dos en Asesor, y prueba de PDF multipágina. Sin certificación de todos los proveedores de archivos de Android.

## Orden de corrección propuesto

1. Preservar metadatos y hacer segura la regularización manual.
2. Unificar resúmenes y estados de todas las vistas administrativas con la APP.
3. Endurecer reglas e incorporar pruebas de reglas antes de publicarlas.
4. Corregir rango de fechas, renovación de GPS y sincronización de cargo/sede.
5. Corregir el ciclo de vida asíncrono y paginar consultas.
6. Prueba integral real con cuentas de prueba autorizadas para ambos cargos y ambas sedes, incluyendo pérdida de internet, doble marcación simultánea, cambio de sede/cargo y desactivación durante la operación.

Esta revisión añade únicamente este informe. No declara que los defectos hayan quedado corregidos ni que los resultados locales certifiquen Firebase o una versión instalada.
