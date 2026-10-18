# Revisión del proyecto — 11 de octubre de 2026

Revisión de la app, administración web, autenticación, sesiones, marcaciones, GPS, detección facial, historial, exportación, regularización, reglas y configuración Android. No se modificó código de funcionamiento ni datos de usuarios durante esta revisión. Los cambios anteriores siguen pendientes en el árbol de trabajo; este informe no equivale a publicarlos ni instalarlos en celulares.

## Problemas pendientes por prioridad

### 1. Consultas administrativas limitadas a 300 marcaciones

`lib/funcionalidades/asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart`, método `obtenerAsistencias`, aplica `limit(300)` antes de que las pantallas agrupen las jornadas y apliquen filtros. Puede ocultar días anteriores e incluso cortar una jornada, produciendo estados pendientes con información parcial. No elimina datos de Firestore.

Recomendación: consultar por intervalo de fechas y paginar sin evaluar una jornada con un conjunto incompleto. No basta aumentar arbitrariamente el límite.

### 2. Una jornada puede dividirse al cambiar de sede

`modulo_asistencias_admin.dart` agrupa por trabajador, fecha y sede. `modulo_dashboard_admin.dart` agrupa por trabajador y fecha. Si el administrador cambia la sede durante una jornada y las marcas posteriores usan la nueva sede, la lista puede mostrar dos jornadas incompletas y el dashboard una completa.

Recomendación: unificar la unidad de evaluación diaria y conservar la sede de cada marca para mostrarla. Confirmar cómo se desean presentar los traslados antes de cambiar esta política.

### 3. Pérdida de conexión durante el guardado

La fuente de asistencias devuelve directamente el Future de `.set(datos)`. El controlador mantiene `guardando` hasta que termina, y la sesión protege la operación en curso. Aunque se exige consultar el servidor antes de registrar, la red puede caer después de esa consulta. Existe riesgo de espera prolongada y confirmación posterior de una escritura pendiente.

Hallazgo de código; no reproducido en un teléfono durante esta revisión. La solución debe distinguir pendiente, confirmado y rechazado, y consultar el ID determinista antes de ofrecer reintentos. Un timeout aislado no cancela una escritura ya enviada.

### 4. Fecha inválida sustituida por la fecha actual

`ModeloAsistencia.desdeMapa` usa `DateTime.now()` cuando `fechaHora` no es Timestamp. Un documento antiguo o modificado incorrectamente puede aparecer como una marcación de hoy. Las reglas actuales protegen nuevas marcas del trabajador, pero este lector también procesa registros históricos y administrativos.

Recomendación: identificar y reportar el documento inválido, sin inventar su fecha ni borrar datos. No se constató que existan documentos reales afectados.

### 5. Cargo retirado durante una jornada

El controlador permite conservar el horario de una jornada ya iniciada aunque el cargo actual no corresponda a un horario reconocido. Sin embargo, `modulo_asistencia_trabajador.dart` condiciona el botón y los horarios a que `horarioAsignado` no sea nulo. Puede impedir desde la interfaz una continuación que el controlador contempla.

No afecta necesariamente a cambios entre dos cargos reconocidos. Acordar el comportamiento para cargos retirados o inválidos y aplicarlo de forma consistente.

## Limitaciones que conviene distinguir de errores

- **Rostro:** ML Kit comprueba que exista exactamente un rostro; no compara la identidad con el trabajador ni implementa prueba de vida. No debe describirse como reconocimiento de identidad ya terminado.
- **GPS:** se solicita una lectura nueva, con límite de espera y control de antigüedad. No se rechazan explícitamente lecturas por su precisión reportada ni por la bandera de ubicación simulada. Las reglas no convierten los indicadores enviados por el cliente en prueba física de presencia.
- **Hora:** se mantiene la hora del dispositivo por la decisión previa. Las reglas validan ventanas con la fecha enviada, no garantizan que corresponda al reloj del servidor.
- **Conexión:** el indicador comprueba acceso al servidor periódicamente, aproximadamente cada minuto; no detecta cada cambio de red al instante. Un fallo de acceso también puede mostrarse como falta de conexión.
- **Perfil:** se renueva al cargar y antes de marcar; esto no implica que cualquier cambio administrativo se refleje instantáneamente en una pantalla inmóvil.
- **Ausencias:** no se incorporó la propuesta de convertir automáticamente entradas no marcadas en tardanza.

## Otros puntos de mantenimiento

- El historial del trabajador carga todos sus registros desde el servidor. Aumentará el trabajo y las lecturas conforme crezca el historial; conviene separar consulta del día y consulta histórica paginada.
- Algunos textos del dashboard dicen siempre “sede principal” o “salida pendiente”, aunque la sede o la marca faltante sean otras.
- La compuerta administrativa no tiene el mismo seguimiento continuo de perfil que la app. Las reglas siguen siendo la autoridad para el acceso remoto; ver una pantalla abierta no demuestra que se puedan ejecutar operaciones después de revocar permisos.
- Android release usa la firma debug. Para distribución formal hace falta configurar una firma propia y su custodia. No cambiar el identificador de aplicación sin revisar Firebase y la actualización de instalaciones existentes.
- La compilación web JavaScript funciona; la comprobación opcional de WebAssembly advierte incompatibilidades en `image 4.3.0`. Gradle también informa de APIs obsoletas y advertencias de manifiestos de dependencias. No se actualizaron dependencias automáticamente.

## Correcciones anteriores que siguen presentes

- La evaluación administrativa compartida requiere los bloques de la jornada: una mañana de Plataforma no basta para declarar el día completo.
- Una observación escrita no convierte por sí sola una jornada en incidencia.
- La regularización conserva metadatos de marcas existentes y comprueba modificaciones concurrentes mediante transacción.
- Asesor y Plataforma tienen estructuras distintas en historial y exportación; el sábado continuo y el domingo no laborable están contemplados en el calendario vigente.
- Antes de guardar se renuevan perfil, sede, historial y GPS; se vuelve a comprobar la ventana de marcación.
- El aviso de conexión dejó de ser un texto fijo.
- Las reglas incluyen validaciones de propietario, perfil activo, sede, estructura, identificadores, ventanas y secuencia. No requieren Cloud Functions.

## Verificaciones y alcance de la evidencia

| Comprobación | Resultado |
| --- | --- |
| Compilación web `flutter build web --no-pub`, ejecutada en esta revisión | Correcta; advertencia opcional de Wasm indicada arriba |
| Procesamiento del manifiesto Android release, ejecutado en esta revisión | Correcto; el manifiesto combinado sí contiene permiso INTERNET |
| Comparación remota de reglas, ejecutada en esta revisión | Las reglas publicadas coinciden con `firestore.rules` local |
| `git diff --check`, ejecutado en esta revisión | Sin errores de espacios; avisos de normalización LF/CRLF |
| Última ejecución completa Flutter sobre el código revisado, inmediatamente anterior a esta auditoría | 122 pruebas aprobadas; análisis estático sin incidencias; APK debug compilado |
| Última ejecución de reglas en emulador, con las reglas actuales | 105 pruebas aprobadas |

Reglas activas verificadas: `e082a2dc-9d04-4818-858d-43d3018f2194`, publicadas el 11 de octubre de 2026 a las 11:39:13, hora de Perú, proyecto `asistenciageolocalizacio-368fc`.

No se repitieron innecesariamente las suites ya aprobadas sin cambios posteriores de código. No se compiló una versión release completa: se verificó su manifiesto. No se probaron en un celular real los cortes de red, GPS, cámara, guardado nativo de documentos ni todos los recorridos de usuario en esta auditoría. No se activó facturación, no se desplegaron funciones ni se alteraron datos reales. La comparación de reglas no verifica la existencia o eliminación de funciones remotas antiguas.

## Orden recomendado

1. Corregir consultas administrativas incompletas y unificar evaluación de jornadas entre sedes.
2. Resolver confirmación de guardados ante cortes de red y lectura de fechas inválidas.
3. Alinear la interfaz con la política de cambios de cargo durante el día.
4. Probar manualmente app y exportaciones en dispositivos reales.
5. Tratar por separado identidad facial, controles adicionales de GPS y preparación para distribución formal.
