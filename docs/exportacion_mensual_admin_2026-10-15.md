# Exportación mensual desde la ficha del trabajador

> Diseño anterior, sustituido por `exportacion_rango_admin_2026-10-15.md`. Ahora se exportan las filas mostradas con los filtros actuales y no se exige fecha de ingreso.

En Asistencia se incorpora «Exportar mes», con selección de mes, año y formato Excel/PDF. La exportación vuelve a consultar el perfil y el historial completo del trabajador; no depende de fechas, estado ni filas visibles en la tabla. No existe acceso desde un módulo general.

## Inicio de labores

El administrador puede seleccionar la fecha en Crear/Editar trabajador, en Asignación laboral. Se muestra en Información general y se guarda como `fechaInicioLabores`, una fecha civil `AAAA-MM-DD`. No se usa la fecha de creación de la cuenta ni se inventa un ingreso para perfiles existentes. El campo es opcional para conservar la edición de perfiles antiguos; debe completarse antes de exportar.

La fecha se conserva en la entidad Usuario, su modelo y la ficha administrativa. Se agrega a la actualización parcial del perfil sin reemplazar otros datos. La auditoría utiliza el campo descriptivo ya permitido para registrar el inicio anterior y nuevo. No se modifican las reglas ni los permisos publicados.

## Alcance y cálculo

El período empieza en el mayor entre el primer día del mes y el inicio de labores. Termina en el menor entre el último día del mes y la fecha actual de Perú (UTC−5). Se rechazan meses futuros o sin días transcurridos desde el ingreso. Se excluyen otras personas, otros meses y fechas anteriores al ingreso.

La tardanza diaria usa `ResumenDiaHistorial` y el constructor de jornada existente. El total suma esas duraciones, conservando segundos. El reporte mensual muestra duraciones en horas:minutos:segundos para que las filas concilien con el total; incluye además minutos completos y días con tardanza. Las jornadas continuas y partidas conservan sus columnas e historial de horarios, incluidos sábados. No se cambian tolerancias, horarios ni validaciones de marcación.

Solo aparecen días con marcaciones. No se imputan faltas ni tardanzas a días sin marcas; un mes sin registros puede exportarse con total cero y «Sin registros». No se calculan descuentos ni se presume un calendario de feriados o permisos. El mes en curso es un reporte parcial hasta la fecha indicada.

## Guardado y comprobación

En web se inicia una descarga con `FileSaver.saveFile`; se informa que debe revisarse la carpeta de descargas, sin afirmar que el navegador confirmó la escritura. En plataformas con selector de archivo se conserva `saveAs`, incluido manejo de cancelación. No se escribe ninguna asistencia al exportar y los fallos de consulta no generan un reporte parcial.

Pruebas: persistencia y compatibilidad con perfiles sin fecha, fecha inválida, alcance por usuario/mes/ingreso/corte, jornadas de ambos cargos y sábado, suma de entradas de mañana y tarde, precisión de segundos, bisiestos, totales mayores de 24 horas, mes vacío, selector y validación previa a descargar, decodificación del Excel y generación de PDF. Se mantienen las pruebas existentes de ficha, asistencia, formularios, edición e historial. Se revisó visualmente un PDF sintético mixto.
