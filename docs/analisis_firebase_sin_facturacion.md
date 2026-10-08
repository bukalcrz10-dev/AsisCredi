> Documento histórico de diagnóstico previo a la adaptación. Los problemas y rutas citados describen aquella revisión, no el estado actual. Consulta [modo sin facturación](modo_sin_facturacion.md) para la implementación vigente.

# Análisis del proyecto: Firebase sin habilitar facturación

Fecha: 1 de octubre de 2026. Revisión del código local, dependencias, reglas de Firestore, flujos de la app y panel web, y suite de pruebas. No se han desplegado cambios, creado cuentas ni modificado datos reales durante este análisis.

**Conclusión:** conservar Flutter, Firebase Authentication con correo/contraseña y Cloud Firestore. Eliminar la dependencia operativa de Cloud Functions y Cloud Storage. Esto permite el núcleo de asistencia dentro de las cuotas gratuitas, pero exige cambiar algunas funciones administrativas y renunciar al archivo centralizado de fotos si se quiere usar exclusivamente Firebase sin facturación. No equivale a conservar todas las prestaciones actuales sin modificaciones.

## Hallazgos y solución

| Prioridad | Hallazgo comprobado | Efecto y solución |
|---|---|---|
| Alta | `ServicioTrabajadoresAuthFunctions` llama a tres endpoints HTTP para crear cuentas, actualizar acceso y restablecer contraseñas. Los registros remotos consultados en esta conversación indican que la facturación está deshabilitada. | Crear cuentas con el SDK de Authentication en una instancia secundaria; guardar el perfil con la sesión administrativa principal. Reemplazar las otras operaciones como se detalla abajo. |
| Alta | El controlador intenta subir una foto a Storage antes de guardar cada asistencia; al fallar continúa con una observación de evidencia pendiente. | Cloud Storage requiere Blaze según la documentación actual. En modalidad sin facturación, retirar el intento de subida y la promesa de evidencia pendiente. Conservar la captura/detección local si se desea, sin prometer foto disponible en la web. |
| Alta | `firestore.rules` permite al usuario activo crear una asistencia si `usuarioId` coincide con su UID, pero no exige el identificador único, la sede asignada, el tipo de horario ni el esquema esperado. | Los controles de interfaz no bastan para proteger los datos. Validar campos, propietario, sede, tipos y unicidad en reglas; probarlas en emulador antes de publicar. La información de GPS/rostro enviada por un teléfono sigue sin ser una prueba independiente de identidad o presencia. |
| Alta | El modelo `PerfilTrabajadorActual` no transporta `activo`; la compuerta móvil solo comprueba sesión Auth. | Para desactivar sin Admin SDK, guardar `activo=false` en el perfil, bloquear la interfaz y denegar nuevas operaciones en reglas. Esto bloquea el uso del sistema; no deshabilita técnicamente la cuenta de Authentication ni borra datos ya almacenados en caché. |
| Alta | `modulo_asistencias_admin.dart` exige mañana y tarde completas, incluso para un Asesor; el dashboard solo exige una entrada y una salida. | Un Asesor completo puede aparecer pendiente y una jornada de Plataforma cerrada solo por la mañana puede aparecer completa en el dashboard. Compartir un único cálculo de jornada entre app, dashboard, tabla administrativa y exportaciones. |
| Media | El controlador coloca texto rutinario en `observacion`; el panel considera cualquier observación como incidencia. | Una asistencia normal puede aparecer observada. Separar comentarios informativos de incidencias reales y evaluar tardanza, salida anticipada e incompletitud explícitamente. |
| Media | El historial personal descarga todos los registros y filtra fechas localmente; se recarga antes y después de marcar. El panel consulta solo los últimos 300 registros globales. | El consumo crece con el historial y los informes administrativos pueden ser incompletos. Consultar únicamente el día para validar una marca, paginar historial y filtrar fechas en Firestore; no calcular totales completos sobre una muestra de 300. |
| Media | El cargo es texto libre y determina el horario solo si coincide con Asesor, Asesora o Plataforma. | Usar un selector de horario y guardar un valor estable, separado del nombre libre del cargo. Migrar explícitamente usuarios antiguos sin adivinar su clasificación. |
| Media | La validación GPS previa puede reutilizarse: al guardar se obtiene de nuevo solo si no existe resultado. | Renovar la ubicación cerca de la confirmación, registrar fecha y precisión y rechazar lecturas demasiado antiguas o imprecisas. No prometer protección absoluta frente a GPS manipulado. |
| Media | El detector ML Kit cuenta rostros, pero no compara identidad ni comprueba prueba de vida. | Denominarlo “detección de rostro”. El proyecto no implementa reconocimiento biométrico del trabajador. No vender esa capacidad como existente. |
| Media | La hora de las marcas y la evaluación se obtienen del dispositivo. | Mantenerlo conforme a la decisión del usuario; documentar que cambiar el reloj o zona puede afectar el resultado. No introducir aquí una migración de reloj sin acordarla. |
| Media | Hay código reciente para configurar y seleccionar sedes, pero esta revisión no acredita configuración GPS real de Huancayo/Satipo en producción. | Confirmar coordenadas, radio y correspondencia de Sede Principal. Asignar por ID, no por nombre. Conservar la sede registrada en cada asistencia al trasladar trabajadores. |
| Baja | El README afirma que no hay panel administrativo activo, pero `Aplicacion` abre dicho panel en web. | Actualizar documentación, requisitos y pasos de arranque cuando termine la migración. |

## Flujo recomendado para las cuentas

1. El administrador autenticado introduce los datos y selecciona cargo/horario y sede.
2. El panel valida su perfil administrativo activo y crea una cuenta de correo/contraseña mediante una instancia secundaria de Firebase Auth. No reemplaza la sesión principal del administrador.
3. Con la sesión principal, guarda `usuarios/{uid}` con nombre, correo, cargo/horario, sede, rol y estado. Las reglas permiten esta escritura únicamente al administrador. No guardar contraseñas en Firestore, registros ni archivos.
4. Cierra y elimina la instancia secundaria al terminar. Prueba explícita de que la sesión administrativa no cambió.
5. Si falla una operación, distinguir cuenta existente, contraseña inválida, cuota y fallo de perfil. Authentication y Firestore no comparten una transacción: comprobar si el perfil se guardó antes de intentar eliminar una cuenta recién creada; disponer de recuperación para cuentas sin perfil. Nunca borrar cuentas preexistentes al reintentar.

El endpoint público de registro de Authentication no queda restringido al administrador simplemente por ocultar el formulario. La garantía de acceso al sistema debe estar en el perfil y las reglas: una cuenta sin perfil autorizado no puede leer información institucional ni marcar. Si se exige que ni siquiera puedan existir cuentas Auth creadas fuera del panel, la propuesta de SDK cliente por sí sola no cumple esa condición.

| Operación | Diseño sin Cloud Functions |
|---|---|
| Crear trabajador | SDK Auth secundario y perfil Firestore escrito por el administrador. |
| Editar nombre, teléfono, área, sede y horario | Actualización parcial del perfil; conservar UID, fotografía y campos no editados. |
| Activar/inactivar acceso a la aplicación | Perfil `activo` y reglas de acceso, con reacción de la interfaz al cambio. |
| Recuperar contraseña | Enviar correo de recuperación con Firebase Auth; el trabajador elige su contraseña. |
| Administrador impone una contraseña nueva a otra cuenta | No reproducirlo con SDK cliente. Sustituir por recuperación por correo; operaciones excepcionales requieren una herramienta administrativa de confianza. |
| Cambiar correo de acceso | Flujo autenticado del propio trabajador con verificación/reautenticación, o mantenimiento autorizado desde Firebase Console. No cambiar solo el correo del perfil, porque quedaría distinto de Auth. |
| Cuentas antiguas realmente deshabilitadas en Auth | Revisarlas en Firebase Console. Cambiar `activo` en Firestore no las reactiva. |

## App, sedes e informes

Mantener dos jornadas: Asesor con dos marcaciones y Plataforma con cuatro, incluyendo tardanza sin tolerancia y salida anticipada. Cada marca nueva ya transporta tipo de horario y bloque. Para futuros cambios de horarios conviene guardar además una versión de la programación, evitando recalcular el pasado con reglas futuras.

El código actual excluye el intervalo fijo de 13:00 a 15:00 del tiempo laborado de Plataforma. Esto es distinto de limitarse a sumar dos diferencias de marcas si alguien sale a receso tarde o vuelve antes: el intervalo fijo continúa descontándose. Mantener esta decisión explícita. Para Asesor se computa entrada a salida sin un descanso definido; 08:30 a 18:30 son diez horas, no ocho.

Huancayo y Satipo son independientes del horario. Las coordenadas de los tests son sintéticas y no configuran oficinas reales. La interfaz nueva permite guardar nombre, latitud, longitud, radio y estado de cada sede; después se selecciona el ID en el trabajador. Un traslado afecta las marcas posteriores y no debería reescribir las sedes anteriores.

Excel, PDF e impresión se generan localmente. Pueden mantenerse sin servidor de informes. El panel web y la app deben usar los mismos datos filtrados y reglas. La detección facial actual está orientada al móvil; que exista un panel web no significa que todo el flujo de captura móvil esté implementado en navegador.

## Consumo y límites

Firestore ofrece cuotas gratuitas de 1 GiB almacenado, 50 000 lecturas diarias y 20 000 escrituras diarias para el uso gratuito descrito en su documentación. Las consultas y comprobaciones adicionales también deben contabilizarse. Por ejemplo, descargar 1 000 marcas ocho veces al día para diez personas supone aproximadamente 80 000 lecturas de esos documentos: más que la cuota gratuita diaria, antes de otros accesos. Es un ejemplo de riesgo de diseño, no una medición de este proyecto.

Sin facturación no hay crecimiento ilimitado: al agotar cuotas pueden fallar operaciones. La solución es paginación, consultas acotadas y seguimiento de uso; no trasladar fotos en base64 a Firestore, porque consumiría rápidamente almacenamiento y transferencia.

## Orden propuesto de implementación

1. Sustituir alta de trabajadores y recuperación de contraseña; definir el comportamiento de correo y cuentas deshabilitadas.
2. Retirar la dependencia de Storage y decidir explícitamente que no habrá archivo remoto de fotos en esta modalidad.
3. Completar estado activo, permisos y reglas de asistencias; verificar cuentas sin perfil y trabajadores inactivos con emuladores.
4. Unificar evaluación de jornadas e incidencias, corregir el dashboard y reemplazar cargo escrito libremente por una selección estable de horario.
5. Completar configuración real de sedes y renovación de GPS al marcar.
6. Paginar consultas y corregir informes parciales; hacer coincidir app, web y exportaciones.
7. Corregir pruebas de interfaz, probar errores/reintentos y generar versiones actualizadas de web y Android. Revisar despliegues por separado: editar un archivo local de reglas no cambia las reglas publicadas.

## Verificación de esta revisión

El análisis estático `flutter analyze --no-pub` terminó sin errores ni advertencias.

La suite completa ejecutada con `flutter test --no-pub` terminó con **39 pruebas aprobadas y 2 fallidas**. Los fallos están en `test/widget_test.dart`: la pantalla de inicio de sesión intenta usar Firebase sin inicializar un doble de prueba, y el test de historial deja un temporizador periódico activo. No son evidencia de que todo el producto falle, pero impiden afirmar que todas las pruebas pasan. Las pruebas de sedes, edición de perfil, horarios y generación de informes sí pasaron.

No se crearon trabajadores reales ni se probaron todos los flujos en teléfono/navegador. Las reglas analizadas son las del repositorio; su equivalencia con producción necesita una verificación específica. La prohibición de facturación se mantiene; no se habilitó ni solicitó un despliegue facturable.

## Referencias oficiales consultadas

- [Cloud Storage exige Blaze](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).
- [Creación con correo y contraseña en Flutter](https://firebase.google.com/docs/auth/flutter/password-auth).
- [Gestión de usuarios y recuperación de contraseña](https://firebase.google.com/docs/auth/flutter/manage-users).
- [Cuotas gratuitas y límites de Firestore](https://firebase.google.com/docs/firestore/quotas).
- [Planes de Firebase](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans).

Archivos clave: `lib/funcionalidades/admin/datos/servicios/servicio_trabajadores_auth_functions.dart`, `lib/funcionalidades/admin/presentacion/widgets/modulo_trabajadores_admin.dart`, `modulo_asistencias_admin.dart`, `modulo_dashboard_admin.dart`, `lib/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia.dart`, `controlador_asistencia_auxiliares.dart`, `lib/funcionalidades/asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart`, `lib/funcionalidades/reconocimiento_facial/datos/fuentes_datos/`, `firestore.rules`, `firebase.json` y `pubspec.yaml`.
