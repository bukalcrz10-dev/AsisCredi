# Clasificación administrativa de asistencias

El listado de asistencias y el dashboard comparten `EvaluacionAsistenciaAdmin`.

- No laborable: el calendario guardado corresponde a un día no laborable.
- Pendiente: falta alguna entrada o salida de los bloques esperados. Las incidencias detectadas se muestran en el detalle aunque la jornada siga pendiente.
- Observada: la jornada está completa, pero tiene tardanza, salida anticipada, ubicación o rostro sin validar, o una inconsistencia de secuencia detectada por el resumen.
- Correcta: jornada completa sin esas incidencias.

Una nota no cambia el estado por sí sola. Se conservan las notas automáticas, manuales y demás textos existentes en el detalle; no se interpretan palabras de texto libre como reglas. Una marca manual sin validaciones continúa requiriendo revisión por sus indicadores de ubicación/rostro, no por el texto de la nota.

Se utiliza el horario almacenado en las marcas, incluidos sábados e históricos. No se modifica ningún documento de Firestore ni se recalculan o escriben horas. Los registros existentes reciben la nueva clasificación al cargarlos en esta versión del panel.

Pruebas específicas: `test/evaluacion_asistencia_admin_test.dart`.
