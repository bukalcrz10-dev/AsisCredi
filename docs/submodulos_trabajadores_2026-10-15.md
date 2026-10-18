# Submódulos de trabajadores

## Estructura del formulario a partir de referencia visual

Se amplió el formulario integrado al ancho útil del módulo. Los campos tienen etiquetas superiores y se distribuyen en columnas, sin incorporar información ajena al sistema:

- Datos personales y contacto: nombre completo, correo institucional, teléfono y área; hasta cuatro columnas.
- Asignación laboral: cargo, sede y rol; hasta tres columnas.
- Acceso al sistema: contraseña inicial (solo creación) y estado activo; hasta dos columnas.

Las secciones se separan mediante títulos y divisores. Las columnas se reducen según el espacio disponible y la escala de texto, hasta una columna en ventanas estrechas. Los botones permanecen al final, alineados a la derecha cuando hay espacio. Se reutiliza la estructura dentro del diálogo de edición respetando sus campos de solo lectura y la ausencia de contraseña.

Se conservaron los controladores, validaciones y operación de guardado. Las nueve pruebas de widgets resultaron aprobadas, incluida una comprobación de cuatro campos alineados en 1280 px y una columna en 320 px.

El menú Trabajadores ahora se despliega en Crear trabajador y Vigentes. El grupo no cambia de pantalla al abrirse; elegir una opción selecciona su contenido y cierra el menú en ventanas pequeñas.

Crear trabajador presenta el formulario dentro del módulo, reutilizando los mismos campos, validaciones y servicio de creación. Se mantienen los datos si falla el guardado y se limpia el formulario tras crear la cuenta correctamente. Los botones se bloquean mientras se guarda. El mismo formulario sigue funcionando como diálogo para editar trabajadores.

Vigentes filtra inicialmente las cuentas activas. Un selector permite consultar inactivos o todos, conservando edición, recuperación de contraseña, estado y gestión de rostro/celular. La búsqueda se combina con el estado sobre los registros cargados. Cargar más sigue accesible aunque la página actual no tenga coincidencias.

No se cambiaron permisos, reglas de Firestore ni servicios de creación o actualización de cuentas.

Verificación: nueve pruebas de widgets aprobadas. Incluyen navegación en 390 y 1366 px, validación del formulario vacío, entrega de datos al callback sin salir del módulo y adaptación del formulario entre 320 y 1280 px con texto hasta el 200 %. Las pruebas no crean cuentas ni escriben datos reales. Análisis estático de la presentación del administrador y sus pruebas sin incidencias.
