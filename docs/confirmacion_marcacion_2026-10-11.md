# Confirmación de marcaciones con conexión interrumpida

La app espera hasta 20 segundos por la respuesta del guardado. Si no llega, libera el estado Guardando y avisa que se debe actualizar el historial con internet. Esto no cancela ni reenvía la escritura original.

Mientras el controlador tiene un envío pendiente, bloquea una segunda confirmación. Cuando la escritura termina, incluso después de ese plazo, atiende su resultado: si Firebase confirma, agrega la marca al historial en memoria sin duplicar el ID; si devuelve error, pide consultar el historial antes de reintentar. Un controlador destruido no actualiza la interfaz.

La fuente Firestore espera la resolución de escrituras pendientes antes de consultar el historial en el servidor. Esto también contempla la cola persistida al reabrir la app. Si no puede resolverla en 20 segundos, falla la consulta y no permite que una nueva marcación continúe con un historial que podría contener escrituras locales sin confirmar. No se interpreta la ausencia de conexión como prueba de que un registro no existe.

Las lecturas de perfil previas a marcar y del historial tienen un plazo de espera. La recarga posterior al guardado no mantiene indefinidamente ocupado el botón ni convierte una escritura confirmada en fallida.

Se conservan horarios, reglas, IDs deterministas y validaciones. No se activan servicios, facturación ni Cloud Functions. No se borran escrituras pendientes.

Verificación: suite Flutter de 125 pruebas aprobada y análisis sin incidencias. Se añadieron pruebas de confirmación tardía sin reenvío, rechazo tardío y respuesta posterior a cerrar el controlador. La simulación usa Futures controlados; todavía se requiere probar el corte real de red en un celular.

Prueba manual: iniciar una marcación válida, cortar la conexión durante el envío y esperar. Si ya había llegado la confirmación, debe mostrarse éxito; si no, debe aparecer el aviso después del plazo. Recuperar internet, actualizar el historial y comprobar que aparece una sola marca cuando Firebase acepta la escritura. Probar también cerrando y reabriendo la app antes de recuperar la conexión. No realizar estas pruebas con marcas reales de trabajadores sin coordinar su regularización.
