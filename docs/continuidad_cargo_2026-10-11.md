# Continuación de jornada al retirar el cargo

La pantalla y la hoja de confirmación usan la misma condición que el controlador: existe un cargo reconocido o una marcación del día con horario reconocido guardado. El resumen conserva el horario de la primera marca válida del día.

Retirar el cargo no oculta por sí solo los horarios y botones necesarios para continuar ese día. Al día siguiente no se reutilizan marcas anteriores para habilitar una jornada nueva sin cargo. Se mantienen las ventanas horarias, GPS, validación facial, comprobación de perfil activo y sede y las reglas de Firestore.

El botón utiliza el reloj del controlador, igual que la hoja de confirmación. Se verificó mediante pruebas de interfaz la aparición del botón y su confirmación para Asesor y Plataforma, el horario conservado al guardar y el bloqueo de una nueva jornada sin cargo. Las 24 pruebas de marcación actualizada y calendario pasaron. No se cambiaron las reglas publicadas.
