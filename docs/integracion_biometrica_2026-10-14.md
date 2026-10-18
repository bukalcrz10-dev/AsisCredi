# Integración de rostro y celular autorizado

## Alcance

La app Android integra la comparación SFace del prototipo, dos parpadeos y una
credencial por cuenta e instalación. Se mantiene la geolocalización antes de la
captura y se vuelve a consultar el GPS al confirmar. No se cambian horarios,
receso, tardanzas, calendario, tipos de trabajador ni columnas del historial.
El panel de administración permite habilitar, aprobar y retirar la autorización.
No se incorporan Cloud Functions, servicios faciales de pago ni Firebase Storage.

## Uso

1. En **Administración → Trabajadores**, abrir el icono **Rostro y celular autorizado**.
2. Pulsar **Habilitar registro de rostro y celular**.
3. En el teléfono del trabajador: **Perfil → Rostro y celular**. Leer y aceptar
   el registro; pulsar **Solicitar registro de rostro y celular**.
4. Mirar a la cámara frontal y completar dos parpadeos. Se captura automáticamente.
5. Mostrar al administrador el código de seis caracteres. El administrador debe
   comprobar personalmente la identidad y que el código corresponde al teléfono
   presente; marcar la casilla de esa solicitud y aprobarla.
6. El trabajador puede pulsar **Consultar aprobación**. También muestra solicitudes
   pendientes, útil si se pierde la respuesta de envío por un corte de red.
7. En Asistencia, pulsar **Registrarse** dentro de la ventana correspondiente.
   Tras validar GPS, pulsar **Validar rostro**, completar los dos parpadeos y
   confirmar la marcación. Cada acción requiere otra captura.

Actualización Android 1.1.1 (3): al pulsar **Validar rostro** la cámara se abre
automáticamente después de comprobar la autorización, sin el paso adicional
**Capturar y verificar**. Cancelar la cámara regresa al proceso de asistencia.
Si ocurre un error se permite reintentar. El registro de referencia conserva
su consentimiento y botón de solicitud. Se verificaron tres pruebas de pantalla
y el análisis de los dos archivos modificados, sin observaciones.
APK compilado correctamente:
`build/app/outputs/flutter-apk/CREDIASCIENDE-1.1.1-camara-directa.apk`.

Una comparación inferior a 0.52 se rechaza. La validación caduca en dos minutos
medidos con Stopwatch y se consume al iniciar la escritura. No se almacena la
fotografía. La comparación se ejecuta en el teléfono; la autorización y el
guardado necesitan internet.

Para cambiar de teléfono: **Retirar celular y eliminar referencia**, habilitar
un nuevo registro y repetir la aprobación. Reinstalar o borrar datos de la app
también requiere nueva autorización. Actualizar la app conservando sus datos
mantiene la credencial. Se permite un teléfono autorizado por trabajador, no una
restricción global que impida usar ese equipo con cualquier otra cuenta.

## Datos y controles

- `configuracionBiometrica/{uid}`: estado, versión y permiso de inscripción.
  El trabajador puede consultar su configuración; solo el administrador la cambia.
- `credencialesBiometricas/{token}`: solicitud, referencia numérica, modelo del
  teléfono, consentimiento, versión y aprobación. La referencia es un Blob de
  1024 bytes: 128 valores float64 little-endian, sin pérdida de precisión.
  La app valida finitud y norma al capturar, aprobar y comparar; las reglas
  comprueban tipo y tamaño. Una solicitud no aprobada no autoriza marcaciones.
- `vinculosBiometricosPrivados/{uid}`: vínculo al token aprobado. Solo el
  administrador puede leerlo o modificarlo; no aparece en el perfil ni informes.
- `credencialesBiometricas/{token}/comprobantes/{idAsistencia}`: resultado,
  similitud, dos parpadeos y hora de recepción. Se crea junto a la asistencia en
  un mismo lote. El trabajador no puede reutilizarlo, actualizarlo ni borrarlo.
- La referencia aprobada no es modificable por el trabajador. Las consultas
  globales de referencias están prohibidas para trabajadores. Una nueva versión
  de autorización invalida la instalación anterior.
- El token aleatorio se persiste cifrado con Android Keystore. No se usa IMEI.
  La app lo utiliza como ruta privada de Firestore; el SDK puede conservar datos
  y rutas en su caché local. No hay cifrado adicional de esa caché en esta entrega.
- Retirar la autorización elimina referencias de versiones anteriores. Los
  comprobantes sin foto ni vector permanecen como auditoría; las asistencias se
  conservan. Una eliminación fallida por conexión se informa y se puede repetir.

## Activación y compatibilidad

El 14/10/2026, con autorización del usuario, se publicaron el panel y las reglas.
Los teléfonos no se actualizan automáticamente: deben instalar el APK indicado.

**Estas reglas exigen autorización biométrica a todos los trabajadores.** Las
versiones antiguas y las cuentas sin rostro/celular aprobado ya no pueden
marcar con las reglas publicadas. El administrador conserva su regularización de
asistencias. Esta entrega no migra ni aprueba automáticamente personas existentes.

Se configuró el sitio predeterminado de Firebase Hosting, que no tenía releases,
y se publicó `build/web` en https://asistenciageolocalizacio-368fc.web.app.
El APK mantiene el paquete
existente y su configuración de firma actual (debug para release); no se cambió
la firma para evitar impedir actualizaciones de instalaciones existentes.

## Límites y comprobación manual pendiente

Dos parpadeos reducen la aceptación de fotografías quietas, pero no certifican
prueba de vida ni garantizan rechazar una reproducción de video. El umbral 0.52
es el ajuste exploratorio probado por el usuario, no una precisión certificada.
Una app manipulada o un teléfono comprometido puede falsificar resultados
locales o extraer credenciales. Firestore verifica autorización y coherencia del
lote, no que se haya ejecutado realmente la cámara o el modelo.

Las comprobaciones automatizadas no sustituyen probar la integración completa
en el Xiaomi 13 y otros equipos. El prototipo funcionó en el Xiaomi según el
usuario; la nueva integración necesita instalarse y verificarse con Firebase.

Pruebas manuales: aprobar el teléfono correcto; rechazar otro teléfono con la
misma cuenta; rechazar otro rostro, una foto quieta y un solo parpadeo; comprobar
caducidad; retirar autorización entre captura y confirmación; perder internet
antes y durante el guardado; verificar una sola marca en historial; cambiar de
equipo y comprobar que el anterior queda bloqueado.

## Verificación automatizada

- Reglas: 130 pruebas aprobadas en `demo-asiscredi-reglas`, emulador local 8185.
- Flutter: 154 pruebas aprobadas de reglas de jornada, GPS, historial, exportación y sesión;
  se añaden comparación, formato YUV, dos parpadeos, referencia binaria,
  autorización al confirmar y recuperación de botones ante respuesta nativa
  de solo lectura o fallo del motor.
- Las licencias de OpenCV, YuNet y SFace se incluyen en assets y LicenseRegistry.
  Los modelos y sus hashes se documentan en `modelos_faciales.json`.
- `flutter analyze`: sin observaciones.
- Android release compilado: versión 1.1.0 (2), paquete existente
  `com.example.flutter_application_1`, nombre CREDIASCIENDE.
- APK: `build/app/outputs/flutter-apk/CREDIASCIENDE-1.1.0-biometria.apk`.
  SHA-256: `99DA5A51618DF27B5F81125A1C307781134A2314D84FCA18C68F0A53F6CA4E76`.
  Se verificaron dentro del APK ambos ONNX y las rutas de código de referencia
  binaria, consulta de solicitud y canal de autorización del dispositivo.
- Web release compilada en `build/web` con `--no-wasm-dry-run`. La comprobación
  opcional de WebAssembly detectó limitaciones de la dependencia `image 4.3.0`;
  esta entrega usa la web JavaScript normal, no WebAssembly.

## Publicación autorizada y verificada

- Se ejecutó `firebase deploy --only hosting,firestore:rules --project asistenciageolocalizacio-368fc --non-interactive` y Firebase confirmó ambos releases.
- Antes de publicar se confirmó el ruleset anterior `e082a2dc-9d04-4818-858d-43d3018f2194` y se guardó un respaldo en `docs/respaldos/firestore-antes-biometria-2026-10-14.rules`.
- Ruleset publicado: `fbd33291-95db-4c24-bb17-83a362d181e0`. Una lectura posterior confirmó igualdad con el archivo local normalizando saltos de línea y espacios finales.
- SHA-256 normalizado: `ee13d05c1050afa72ea584c263dff056cdc8ecc9da058eb29840e76ece901426`.
- El sitio respondió HTTP 200 y los hashes de `index.html`, `flutter_bootstrap.js`, `main.dart.js` y `manifest.json` coincidieron con la compilación local.
- Comprobantes en `docs/respaldos/firestore-biometria-publicado-2026-10-14.json` y `docs/respaldos/hosting-biometria-verificado-2026-10-14.json`.
- No se activó facturación, no se desplegaron Cloud Functions y no se modificaron asistencias ni se aprobaron referencias reales. Falta la prueba funcional con una cuenta real y el teléfono actualizado.
