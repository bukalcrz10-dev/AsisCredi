# Diseño adaptable del panel administrador

## Retirada de encabezados generales al entrar a los módulos

A petición del usuario se retiró del layout compartido el título y la descripción del módulo que aparecían antes de su contenido (por ejemplo, Dashboard y Resumen general del sistema institucional). Se aplica a todos los módulos. Se conserva la barra global con fecha y administrador, el menú y los títulos propios de las secciones del contenido. Las siete pruebas de layout/navegación resultaron aprobadas y el análisis del layout no presentó incidencias.

## Barra superior con fecha y administrador

Ampliación posterior: la barra ahora ocupa todo el ancho de la ventana, por encima tanto del menú lateral como del contenido. El botón del extremo izquierdo muestra u oculta el menú en escritorio y abre el drawer en ventanas pequeñas. La preferencia de plegado se conserva al cambiar de módulo durante la sesión del componente. Una prueba adicional comprueba el ancho de 1280 px, el menú situado debajo y el plegado; las catorce pruebas de widgets del panel resultaron aprobadas y el análisis no presentó incidencias.

Se sustituyó la cabecera en forma de tarjeta por una barra blanca compacta que permanece visible sobre el contenido. Muestra la fecha actual a la izquierda y el nombre del administrador autenticado con icono de usuario a la derecha. El correo está disponible en el tooltip del nombre; la condición del día permanece en el tooltip de la fecha. La fecha se actualiza cada minuto con el mismo mecanismo anterior.

El título y la descripción del módulo quedan debajo de la barra, dentro del contenido desplazable. Se retiró la tarjeta de sesión del menú lateral para no duplicar el nombre y recuperar espacio para las opciones; el botón de cerrar sesión se conserva. En ventanas estrechas o con texto ampliado, la barra distribuye sus elementos en dos filas y mantiene accesible el menú.

Verificación: pruebas previas del panel aprobadas y prueba adicional de fecha y nombre visibles al desplazar el contenido, con nombre largo y texto al 200 %. Análisis de la barra, layout, menú y prueba sin incidencias. No se modificaron autenticación, datos ni permisos.

## Escala general de todos los módulos

Tras una nueva revisión del usuario, se redujo la escala de componentes del administrador: texto habitual de 14 px y secundario de 13 px; títulos de 18–20 px; botones, iconos, etiquetas y campos con menor altura y márgenes. Se aplica densidad compacta desde 600 px, manteniendo objetivos táctiles mayores en ventanas pequeñas. Se respeta la escala de texto del sistema y del navegador.

El menú pasa a 216 px. Las fichas de trabajadores distribuyen correo, teléfono, área y cargo en líneas según el espacio disponible, conservando todos los datos. Las filas y cabecera de asistencias, los filtros de fecha y las tarjetas de resumen también reducen su espacio. El inicio de sesión y la app del trabajador no reciben este tema.

Verificación: cinco pruebas de widgets aprobadas, incluidos contenido, formulario y navegación con varias ventanas y texto hasta el 200 %. Análisis estático de todos los widgets del administrador y pruebas sin incidencias.

## Rediseño compacto posterior a la revisión del usuario

El primer ajuste de columnas resultó insuficiente visualmente. Se rediseñó la presentación para reducir el esfuerzo de lectura, manteniendo la tipografía y las funciones:

- Menú de 232 px, fondo oscuro uniforme y selección turquesa. Opciones de menor altura. Menú desplegable cuando el ancho es inferior a 1200 px.
- Cabecera con menos altura, sin sombra y con esquinas de 12 px. Márgenes generales de 16 px en escritorio.
- Indicadores de menor altura, con valor destacado, título y descripción accesible al pasar el puntero o mediante accesibilidad. Ancho mínimo de 180 px, ampliado proporcionalmente con el texto.
- Explicación de los indicadores en un desplegable. La lista de trabajadores sin marcaciones conserva su acceso independiente.
- Contenedores de módulos más compactos y menos espacio antes de su contenido.
- Pruebas con el componente real de indicadores en la matriz de tamaños y escalas; comprobación de cinco indicadores en una fila a 1280×720, incluyendo menú y márgenes. Cinco pruebas aprobadas y análisis de widgets y pruebas sin incidencias.

No se modificaron operaciones de datos ni reglas de negocio. La sesión del navegador disponible estaba en la pantalla de acceso; las verificaciones de contenido se realizaron con pruebas de widgets, sin credenciales ni datos reales.

## Ajustes visuales

- Tema propio del administrador: texto de lectura de 15–16 px, texto secundario de 14 px y etiquetas de 13–14 px. El acceso y el tema de la app del trabajador conservan sus estilos.
- Menú lateral de 248 px en ventanas amplias; menú desplegable por debajo de 1440 px. Al elegir un módulo, el desplegable se cierra.
- Navegación más compacta, con títulos e iconos y un fondo azul/turquesa oscuro para mejorar el contraste del texto blanco.
- La tarjeta de sesión y las opciones del menú se desplazan cuando la ventana tiene poca altura.
- Cabecera compacta con fecha y jornada, sin repetir la tarjeta de sesión. El contenido completo se puede desplazar verticalmente; la cabecera no consume un bloque fijo de altura en ventanas bajas.
- Barra de desplazamiento visible y un ancho de lectura máximo de 1760 px.
- Indicadores distribuidos en columnas según el ancho disponible y la ampliación del texto, con igual altura en cada fila. Se eliminaron los anchos fijos de las tarjetas y se compactaron los indicadores del dashboard.
- Tabla de asistencias con ancho mínimo legible y desplazamiento horizontal visible cuando haga falta. Las columnas no reducen la letra para entrar a la fuerza.
- Filtros que se distribuyen por filas según el ancho y la escala del texto; en ventanas pequeñas ocupan el ancho disponible.
- Los nombres de los trabajadores se ajustan al espacio real y muestran el nombre completo al pasar el puntero.
- Tarjetas de trabajadores con acciones y estado en filas separadas cuando falta espacio.
- Indicadores de estado con tonos más oscuros para facilitar la lectura.

## Verificación previa a la publicación

- Prueba de cabecera en 13 anchos entre 320 y 1920 px.
- Prueba de contenido y formulario de sedes con ventanas de 320×480, 768×400, 1366×768 y 1920×1080; escala de texto 100 %, 125 %, 150 % y 200 %.
- Prueba de acceso al final del contenido mediante desplazamiento.
- Prueba de cierre del menú al seleccionar un módulo.
- Prueba de consulta de auditorías antiguas y nuevas.
- Cuatro pruebas de widgets aprobadas y análisis estático sin incidencias.

No se modificaron horarios, cálculos, permisos, escrituras de datos ni reglas de Firestore en este ajuste visual.

### Ajuste para monitores con escala de pantalla

La captura en localhost mostraba los cinco indicadores en dos filas. Se ajustó el ancho mínimo de columna de 230 a 220 px, conservando la tipografía y el crecimiento de las tarjetas con texto ampliado. Se añadió el ancho de 1536 px a la matriz y una prueba específica que comprueba cinco indicadores en una fila con el menú lateral y los márgenes del dashboard. Las cinco pruebas de widgets del panel resultaron aprobadas.

## Revisión en navegador y carga de actualizaciones

- Revisión visual del dashboard publicado en 1920×1080 y 390×844, y de la tabla de asistencias en 1366×768.
- Se detectó que un navegador con archivos antiguos conservaba una versión anterior, incluso tras recargar. Se incrustó el arranque generado por Flutter en el HTML y se agregó a la entrada JavaScript un identificador distinto por compilación.
- Cabeceras `no-cache` para HTML, programa principal, arranque y service worker. Esto no borra datos de sesión ni preferencias.
- Se comprobó en la sesión del navegador que finalmente aparecieron el módulo Sedes, la nueva tipografía, la cabecera compacta y las tarjetas adaptables.
- Captura de escritorio: `docs/capturas/panel-escritorio-2026-10-15.png`.

## Publicación

Versión final compilada y publicada en Firebase Hosting el 15/10/2026. Los cuatro archivos principales coinciden por SHA-256 con la compilación; las cabeceras `no-cache` se comprobaron en los archivos de arranque y programa principal. Evidencia: `docs/respaldos/diseno-panel-publicado-2026-10-15.json`.
