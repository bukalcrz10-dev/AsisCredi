# Corrección de regularización manual

Se corrige el punto 1 de la auditoría: el panel ya no reemplaza el documento completo al cambiar una hora. Actualiza únicamente fechaHora y observacion. Conserva tipoHorario, bloqueJornada, usuario, sede, sensores, evidencia histórica, notificaciones y campos adicionales.

El formulario usa el horario almacenado en las marcas de esa jornada: dos campos para Asesor, cuatro para Plataforma. No depende del cargo actual del trabajador. Las marcas nuevas reciben horario y bloque explícitos e ID determinista. Sus indicadores de GPS/rostro se guardan en falso, pues son altas administrativas sin comprobación de sensores.

Una transacción comprueba que los registros no cambiaron desde que se abrió la lista y guarda todos los cambios juntos. Si una marca nueva ya existe o cambió una de las originales, rechaza la operación y solicita actualizar la lista; no sobrescribe a otro operador. Conserva los segundos de las horas no editadas. Exige formato de 24 horas y orden cronológico.

Jornadas antiguas sin horario identificado: permite correcciones de marcas existentes que no cambien su bloque inferido, conserva sus etiquetas ausentes y bloquea altas nuevas. No migra ni deduce el horario histórico a partir del cargo actual. Jornadas duplicadas o con horarios incompatibles requieren revisión previa. No se repararon documentos remotos antiguos automáticamente.

Pruebas nuevas: corrección de Asesor y recálculo de tardanza; ocho horas de Plataforma; metadatos; segundos sin editar; formato y secuencia; datos históricos; duplicados; conservación de campos desconocidos; conflicto concurrente; altas con ID determinista y reintentos.

Los demás hallazgos de la auditoría, incluidos los estados de jornada en las tablas administrativas, no se consideran resueltos por esta corrección. No se activó facturación ni se publicaron cambios en Firebase.
