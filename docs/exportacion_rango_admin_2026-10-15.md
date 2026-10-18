# Exportación de las asistencias mostradas

## Cabecera y total final

El reporte identifica al trabajador y presenta los filtros de fecha y estado arriba. Se retiran los indicadores de tardanza de la cabecera. Al final de la última tabla se agrega una única fila destacada «TOTAL TARDANZA», con la suma de todas las jornadas exportadas alineada bajo Tardanza. También suma jornadas de secciones anteriores cuando cambian los horarios. Se aplica a Excel y PDF; los informes del historial del trabajador conservan su presentación anterior.

Verificación: 23 pruebas aprobadas; Excel decodificado confirma una sola fila de total al final, su columna según jornada continua/partida, formato destacado y total de un historial mixto. PDF sintético revisado visualmente.

Sustituye la exportación mensual anterior por petición del usuario. En la ficha, Exportar permite elegir Excel o PDF directamente. El archivo es una instantánea de las jornadas que cumplen los filtros actuales de fecha y estado; si no hay filtros de fecha, incluye todo lo mostrado. No se realiza una consulta independiente que pueda ignorar los filtros.

Se usan las marcaciones originales de las filas filtradas, con defensa adicional por ID del trabajador y fechas inclusivas. El reporte incluye filtros aplicados, fechas con registros, tardanza por jornada, total acumulado y días con tardanza. Las jornadas conservan sus horarios y columnas de dos o cuatro marcas. Las duraciones mantienen segundos y totales mayores de 24 horas.

La fecha de inicio de labores permanece como información editable del trabajador, pero no bloquea ni recorta esta exportación: el archivo debe coincidir con lo mostrado. No se genera un archivo si no hay filas. Se eliminaron el selector mensual, su componente y el modelo exclusivos del mes, reemplazados por componentes de exportación de asistencias.

Pruebas: rango inclusivo, una sola fecha, límites abiertos, varios meses, identidad, filtros de estado reales en la pantalla, ausencia del selector mensual, ausencia de requisito de ingreso, botón deshabilitado sin datos, precisión de segundos, Excel decodificado y PDF sintético. Continúan las pruebas de ficha e historial.
