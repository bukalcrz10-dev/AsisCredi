# AsisCredi — CREDIASCIENDE

Aplicación Flutter con panel administrador web y aplicación de asistencia para trabajadores. Usa Firebase Authentication (correo y contraseña) y Cloud Firestore. No requiere Cloud Functions ni subida de fotos a Cloud Storage.

## Funcionamiento actual

- WEB: administración de trabajadores, sedes, asistencias y reportes.
- APP móvil: acceso con perfil activo, marcación según cargo, GPS, detección local de rostro, historial y exportación Excel/PDF.
- Asesor: entrada y salida final. Plataforma: entrada mañana, salida a receso, entrada tarde y salida final.
- Cada trabajador tiene una sede asignada; configurar coordenadas y radio reales en el panel.
- Altas con una sesión auxiliar de Auth: no cierran la sesión del administrador. Perfiles, cargos, sedes y estado se guardan en Firestore.
- Contraseñas: recuperación por enlace enviado al correo del trabajador. El correo de acceso existente no se edita desde el panel.
- Cuenta inactiva: las reglas y la APP bloquean el acceso institucional. No equivale a deshabilitar la cuenta en Authentication.
- La validación facial móvil compara la referencia enrolada con SFace y comprueba parpadeos. Requiere rostro y dispositivo aprobados por el administrador. No guarda fotos nuevas en la nube.

## Configuración

Consulta [requisitos, recuperación de altas incompletas y límites](docs/modo_sin_facturacion.md).
Se necesita un administrador activo ya registrado, el proveedor correo/contraseña habilitado y reglas de Firestore que protejan los perfiles y datos institucionales. Spark tiene cuotas; no es ilimitado.

## Ejecución y validación

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter run -d <id-del-dispositivo>
```

## Compilaciones

```sh
flutter build web
flutter build apk --debug
```

El panel se genera en `build/web`; la APK de pruebas en `build/app/outputs/flutter-apk/app-debug.apk`.
Compilar no publica la WEB ni instala la APP. Actualizar ambas para sustituir versiones anteriores.

## Estructura

- `lib/funcionalidades/admin`: panel y administración con Auth/Firestore.
- `lib/funcionalidades/autenticacion`: inicio de sesión y control de acceso.
- `lib/funcionalidades/asistencias`: horarios, marcas, historial y exportaciones.
- `lib/funcionalidades/geolocalizacion`: permisos, GPS y distancia a la sede.
- `lib/funcionalidades/reconocimiento_facial`: cámara, detección local ML Kit, comparación facial y autorización biométrica.
- `lib/funcionalidades/usuarios`, `sedes`: perfiles y sedes. Los errores de marcación se muestran en pantalla sin guardarse en una colección de alertas.
- `firestore.rules`: reglas locales; su publicación es una operación separada.

No hay servidor Functions ni dependencias de Functions/Storage en el código actual.
Los campos históricos de URL y la configuración generada de Firebase se conservan para compatibilidad; no realizan cargas de archivos.
