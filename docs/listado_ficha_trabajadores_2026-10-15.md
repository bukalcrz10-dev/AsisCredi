# Vigentes: listado y ficha individual

## Acceso a asistencia desde la ficha

Se retira Asistencias del menú principal y su selección en `PaginaPanelAdmin`. La consulta queda accesible en Trabajadores → Vigentes → ficha → Asistencia. Se conserva el componente compartido para las fichas y sus indicadores; no se eliminan registros ni se cambian cálculos, horarios o permisos.

## Listado más compacto

Filas de 56 píxeles a escala normal, encabezados destacados, tabla con borde redondeado y etiquetas de estado con texto y color. Las columnas distribuyen su ancho proporcionalmente, dando más espacio al correo; los valores de las celdas se muestran en una línea con tooltip completo. Los nombres conservan hasta dos líneas y su acceso a la ficha. Los filtros se ajustan al ancho disponible y la tabla permite desplazamiento horizontal cuando hace falta. Se mantienen búsqueda, orden, paginación y selección.

Verificación: cinco pruebas aprobadas de listado y ficha, con ventanas de 320, 768 y 1280 píxeles y escalas de texto de 100 % y 200 %. Análisis sin incidencias.

## Asistencia sin datos repetidos de identidad

En la asistencia de una ficha individual se ocultan el buscador y la columna Trabajador, tanto en la presentación amplia como en la compacta. Se conserva la consulta por ID, los filtros de estado y fechas, el detalle y la regularización. El módulo general conserva el buscador y los nombres. La tabla compacta individual reduce su ancho mínimo al quitar esa columna.

Verificación: 13 pruebas de ficha y asistencia aprobadas, incluida la ausencia de ambos elementos en la ficha y su presencia en el módulo general, y el alcance por ID al cambiar de trabajador y abrir la regularización.

## Indicadores trasladados a Resumen

En la ficha, Marcaciones cargadas, Jornadas correctas, Jornadas observadas y Pendientes se muestran en Resumen, junto con Actualizar resumen. Comprenden el historial completo del trabajador seleccionado. Asistencia conserva filtros, tablas, detalle y regularización sin repetir estas tarjetas. El módulo general mantiene su presentación completa.

Se reutilizan las mismas consultas, agrupación y evaluación mediante las vistas completa, registros y resumen de `ModuloAsistenciasAdmin`, sin duplicar cálculos. Al volver a Resumen desde otra pestaña se consulta nuevamente el historial del trabajador, por lo que recoge las regularizaciones confirmadas; el botón permite actualizarlo expresamente. No se escriben datos al consultar.

Verificación: 13 pruebas aprobadas de ficha, pestañas y asistencia por trabajador, incluida ubicación de tarjetas y consulta por ID al actualizar. Análisis de componentes y pruebas sin incidencias.

## Presentación según el horario de la jornada

La tabla y el detalle usan el indicador `esJornadaContinua` del resumen existente, sin recalcular horarios ni deducirlos del cargo actual. Asesor muestra Entrada y Salida. Auxiliar de operaciones muestra Entrada/Salida de mañana y Entrada/Salida de tarde en las jornadas partidas; el sábado, continuo para ambos, muestra Entrada y Salida.

Si el historial contiene ambos tipos, se presentan tablas de jornada continua y partida, cada una con las columnas correspondientes. La tabla continua tiene menor ancho mínimo. El detalle continuo muestra solo ubicación de entrada y salida; el partido conserva las cuatro ubicaciones. Los campos de regularización siguen usando las ventanas del modelo original: dos en jornada continua y cuatro en partida.

Verificación: 32 pruebas aprobadas de columnas, horas mostradas, detalle y cantidad de campos de regularización para Asesor, Auxiliar entre semana y Auxiliar en sábado; historial mixto con cargo actual de Asesor; alcance por ID; evaluación, regularización y paginación existentes. Análisis sin incidencias. No se alteraron horarios, cálculos ni datos guardados.

## Asistencia del trabajador seleccionado

Las pestañas quedan en este orden: Resumen, Asistencia, Rostro y celular y Recuperar contraseña. Asistencia reutiliza `ModuloAsistenciasAdmin` con un identificador fijo del trabajador; se crea al seleccionar la pestaña.

El módulo acepta opcionalmente `trabajadorId`. Sin ese argumento conserva la consulta general paginada. Con el argumento usa el método existente `obtenerAsistenciasPorUsuario`, que consulta por ID y ordena localmente, sin nuevos índices compuestos. Se consulta solo el perfil de ese trabajador. El historial completo recuperado permite conservar jornadas completas y aplicar fechas y estados; no se consulta la asistencia general ni se permite cargar páginas generales desde la ficha.

Los registros se vuelven a comprobar por ID antes de agruparlos y las acciones de detalle y regularización también comprueban el alcance. Un ID vacío produce un error de consulta y nunca se interpreta como Todos. Al cambiar de ID se limpia la consulta anterior y se mantiene la protección de versiones para descartar respuestas antiguas.

Se conservan indicadores, búsqueda dentro de las asistencias, fechas, estado, detalle y regularización con motivo/auditoría del módulo anterior. La ficha pasa la clave por ID para evitar compartir estado entre trabajadores. No se modificaron horarios, cálculos, reglas ni escrituras.

Verificación: 22 pruebas aprobadas de asistencia individual, ficha/pestañas, paginación de jornadas y regularización. Las pruebas individuales verifican consulta y recarga por ID, exclusión defensiva de registros ajenos, cambio de persona, apertura de detalle y regularización del trabajador, continuidad del módulo general y rechazo de ID vacío. No se guardaron cambios reales ni se enviaron correos. Análisis de los componentes modificados y pruebas sin incidencias.

## Nombre y cargo en la cabecera de la tarjeta

Los nombres se muestran encima de los apellidos y el cargo sustituye a Cuenta vigente/inactiva bajo el nombre. No se modifica el valor guardado en `nombreCompleto`. Dado que el modelo no almacena nombres y apellidos por separado, la separación es visual y supone que las dos últimas palabras son los apellidos para nombres de tres o más palabras. Con dos palabras se muestra una en cada línea y con una no se añade una línea vacía. Esta convención no identifica con certeza los apellidos compuestos; para ello se necesitarían campos explícitos.

Se verificaron Armando Fernandez Huaman, Julio Cesar Quispe Zarate y un nombre de una sola palabra, además de las pruebas existentes de tabla, pestañas y adaptación. Cinco pruebas aprobadas y análisis sin incidencias.

## Pestañas de la ficha

La ficha dispone de Resumen, Rostro y celular y Recuperar contraseña. La tarjeta de información general y el lápiz de edición permanecen al cambiar de pestaña.

- Resumen conserva los datos laborales. La acción de activar/desactivar aparece como un icono junto al lápiz en la tarjeta de información general, con su confirmación existente y un tooltip que indica la acción según el estado de la cuenta.
- Rostro y celular integra el contenido de `DialogoBiometriaAdmin` dentro de la ficha. Se conservan sus consultas, aprobación, verificación de identidad/código, retiro con confirmación y actualización. El contenido se consulta al visitar la pestaña, no al abrir Resumen. El diálogo sigue disponible para los usos anteriores.
- Recuperar contraseña muestra el correo del trabajador y el botón para solicitar un enlace. Seleccionar la pestaña no envía correos; el botón llama al flujo anterior que pide confirmación y muestra el resultado del envío.

Las pestañas admiten desplazamiento horizontal si falta espacio. Las pruebas verifican la selección efectiva de las tres entre 320 y 1280 px, incluso con texto al 200 %, y que abrir recuperación no ejecute su callback. Las pruebas no envían correos ni escriben en Firebase. Pruebas anteriores del panel y prueba adicional de pestañas aprobadas; análisis de los componentes modificados y pruebas sin incidencias. No se modificaron los servicios ni las reglas.

Se utiliza únicamente la estructura de las capturas de referencia. No se añadieron datos de identificación, contratos, sueldos, documentos, vacaciones ni otros campos ajenos al proyecto.

## Listado

- Tabla de nombre, correo institucional, cargo, sede y estado. Se puede abrir la ficha desde el nombre o la fila.
- Se carga la colección completa mediante el método existente `obtenerUsuarios`, que recorre páginas de Firestore de 100 documentos. El listado visible usa páginas locales de 10, 25 o 50 filas. Así la búsqueda y los filtros comprenden todas las cuentas recuperadas, sin limitarse a la antigua primera página de 30.
- Vigentes es el filtro inicial; se mantienen Inactivos y Todos. Orden ascendente o descendente por nombre.
- Conteo de coincidencias, rango mostrado y navegación anterior/siguiente. Tabla con desplazamiento horizontal si el espacio no basta.
- La búsqueda, el filtro, el orden y la página se conservan mientras se visita una ficha. Al actualizar datos se recalcula el rango para no mostrar páginas inexistentes.

## Ficha

- Panel lateral de identidad e información general: nombre, estado, correo, teléfono e identificador existentes.
- A petición del usuario, el panel de Información general también muestra cargo, área, sede asignada y rol de acceso, conservándolos en el resumen.
- Resumen laboral: cargo, sede, área y rol.
- Acciones conectadas a las funciones anteriores: editar, recuperar contraseña, activar/desactivar y rostro/celular. No se ofrece eliminación.
- La ficha se obtiene del listado actualizado por identificador; tras editar o cambiar el estado se muestran los datos recargados. Las acciones se deshabilitan durante el guardado o recarga. Se conservan las confirmaciones y las auditorías de los servicios existentes.
- Distribución de dos paneles en ventanas amplias y vertical cuando falta espacio o el texto está ampliado.

## Verificación

Doce pruebas de widgets aprobadas. Las nuevas pruebas utilizan 61 cuentas de ejemplo sin acceso a Firebase para comprobar paginación, búsqueda fuera de la primera página, filtro de inactivos, apertura de ficha y conservación de búsqueda al volver. Tabla y ficha verificadas en 320, 768 y 1280 px con texto al 100 % y 200 %. Se corrigió un desbordamiento de los filtros detectado por estas pruebas.

No se modificaron campos de la base de datos, reglas, autenticación, horarios ni servicios de escritura. La carga completa aumenta las lecturas respecto a la antigua carga inicial de 30 cuentas; se realiza al abrir o actualizar el módulo y después de las operaciones que ya recargaban el listado, no por cada búsqueda o cambio de página.
