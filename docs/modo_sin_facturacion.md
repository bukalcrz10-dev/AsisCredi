# Funcionamiento con Firebase Spark

Implementación local, 1 de octubre de 2026. No activa ni cancela facturación, no despliega reglas y no borra funciones o datos remotos.

## Cambios

- El panel usa Authentication correo/contraseña y Firestore. Ya no llama a endpoints Cloud Functions.
- El alta usa una instancia Firebase auxiliar; la sesión principal del administrador se conserva. El perfil se escribe con sus permisos, en usuarios/{uid}, mediante una transacción que no reemplaza documentos existentes.
- Si Auth crea una cuenta y falla Firestore, no se elimina la cuenta: actualizar la lista y, si no aparece, repetir el alta con el mismo correo y contraseña. El alta recupera exclusivamente cuentas cuya contraseña se demuestra y cuyo perfil aún no existe. Si se perdió la contraseña, recuperar acceso desde Firebase Authentication antes de repetir.
- Correo de acceso de trabajadores existentes: solo lectura. Cambiarlo únicamente en Firestore rompería la correspondencia con Authentication. Un cambio excepcional exige mantenimiento coordinado en la consola Auth y en el perfil.
- Recuperación: el panel envía un enlace al correo del perfil; el trabajador escoge su contraseña. La solicitud aceptada no garantiza entrega del correo; revisar spam y límites del servicio.
- Cargo, sede, rol y estado se guardan en Firestore. El administrador no puede quitarse su propio acceso desde este servicio.
- Inactivo significa acceso institucional bloqueado por perfil/reglas; no es el indicador disabled de Authentication. Si una cuenta antigua fue deshabilitada en Auth, reactivarla en la consola Auth además del perfil.
- La APP escucha el estado activo confirmado por el servidor y oculta la pantalla del trabajador cuando no puede confirmar acceso. Las reglas son la autoridad para impedir lectura/escritura. No elimina datos ya descargados del dispositivo.
- La fábrica de asistencia no configura ningún cargador de fotos: no llama a Storage ni indica fotos pendientes. Se mantiene la detección local de rostro; no identifica personas ni comprueba vida. Se retiraron los adaptadores y el paquete de Storage; se conservan los campos de URL para leer datos antiguos.
- Se retiró el paquete cloud_functions y el destino functions de firebase.json para evitar despliegues accidentales. Se eliminó el directorio local functions y sus dependencias. Esto no elimina funciones remotas.

## Requisitos de puesta en uso

1. Proyecto en Spark y Authentication con proveedor correo/contraseña habilitado. No crear una cuenta de facturación para este flujo. El código no comprueba ni cambia el plan de la consola.
2. Administrador ya existente, autenticado, con usuarios/{uid}.rol = administrador y activo = true.
3. Reglas publicadas equivalentes a firestore.rules: trabajadores solo leen su perfil; únicamente un administrador activo crea/edita perfiles; datos institucionales requieren un perfil activo. No usar reglas abiertas. No se modificaron ni publicaron reglas en esta entrega.
4. Configurar sedes reales y asignar cargo Asesor/Plataforma a cada trabajador. Correo válido y accesible para recuperación.
5. Publicar la nueva compilación WEB por el canal de hosting habitual e instalar la nueva APK. Una pestaña o instalación anterior seguirá ejecutando el flujo antiguo hasta actualizarse.
6. Verificar con una cuenta de prueba autorizada: alta, sesión admin conservada, ingreso móvil, cambio de sede/cargo, desactivación mientras APP está abierta, reactivación y enlace de contraseña. No se crearon cuentas reales en las pruebas automáticas.

## Límites

Auth y Firestore no comparten una transacción. Las pruebas unitarias simulan ambos servicios; no certifican permisos del proyecto remoto ni entrega de correo. La API pública de registro Auth puede crear cuentas sin pasar por el panel: solo un perfil aprobado por el administrador da acceso institucional. Este modo no equivale a altas Auth restringidas exclusivamente al administrador.

Spark mantiene cuotas; no es capacidad ilimitada. No se añade almacenamiento central de fotos ni reconocimiento de identidad. La hora conserva el comportamiento del dispositivo acordado previamente.

Si ya se aceptó una autorización de tarjeta o se vinculó facturación durante la configuración, estos cambios no revierten esa operación. Revisar ese estado por separado en la consola.

## Verificación local

- Pruebas de administración: alta aislada, permisos, perfil existente, fallo parcial y recuperación, contraseña incorrecta, edición, bloqueo de cambio de correo, prevención de auto-desactivación y recuperación por correo.
- Prueba de acceso: el contenido se retira cuando el perfil pierde permiso o la consulta falla.
- Se corrigieron los dos fallos anteriores de pruebas de interfaz: login usa un controlador simulado y el test de historial libera su temporizador.
- Compilación Android debug: build/app/outputs/flutter-apk/app-debug.apk. Compilación web: build/web.
- Las comprobaciones locales no sustituyen la prueba de alta con los permisos reales de Firebase tras actualizar el panel.

Resultado final: flutter analyze sin observaciones; suite completa 51/51 pruebas aprobadas; compilaciones WEB y APK debug completadas correctamente.

## Limpieza posterior del proyecto

Se retiró por completo el servidor local `functions` (incluyendo node_modules), el paquete firebase_storage, las cuatro capas de subida de evidencia y los mensajes de fotografías pendientes. No se modificaron las URLs históricas almacenadas ni las opciones generadas de Firebase.

El usuario autorizó eliminar las cinco funciones remotas de administración. El intento mediante Firebase CLI recibió HTTP 403 para todas: Google denegó acceso de escritura y pidió revisar la cuenta de facturación. La herramienta hizo DELETE directamente; el texto "failed to update" es su etiqueta genérica de error, no un paso previo. No se activó facturación ni se eliminaron datos de Auth/Firestore. La eliminación remota queda pendiente por este bloqueo de Google.
