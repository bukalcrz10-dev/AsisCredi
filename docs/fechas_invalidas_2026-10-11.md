# Fechas inválidas en marcaciones

Se retiró la sustitución automática de fechas inválidas por DateTime.now(). El modelo exige un Timestamp y, si falta o tiene otro tipo, lanza FechaAsistenciaInvalida con el identificador del documento. No se adivina una fecha a partir de texto o del ID ni se modifican documentos de Firebase.

La consulta falla de manera explícita en lugar de devolver una jornada parcial. El controlador del trabajador limpia el historial en memoria ante este error, muestra un aviso y bloquea la exportación de información potencialmente incompleta. La validación previa al registro tampoco continúa con ese historial. Al corregir el registro y actualizar, se puede cargar normalmente otra vez.

El administrador recibe el identificador del documento afectado en la lista de asistencias y en el error del dashboard. La reparación requiere revisar la fecha real; no se automatiza ni se elimina información.

Alcance: detecta documentos devueltos por las consultas actuales. La consulta administrativa ordenada por fecha no devuelve documentos donde falta ese campo, y mantiene su límite de 300 registros (problema separado). No constituye una auditoría de todos los documentos remotos. La consulta del trabajador sí puede devolver documentos sin fecha porque filtra por usuario.

Se añadieron pruebas de campos ausentes, nulos y tipos incorrectos, conservación del instante y metadatos válidos, bloqueo de una nueva marcación con historial inválido, recuperación después de corregir y aviso en pantalla sin exportación. No se modificaron horarios, cálculos ni reglas publicadas.
