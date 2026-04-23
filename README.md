# Asistencia App UNACHU

Aplicacion Flutter para control de asistencia institucional con autenticacion,
validacion de ubicacion, captura facial e historial personal del trabajador.

## Estado actual

El proyecto se encuentra enfocado en el flujo del trabajador:

- inicio de sesion institucional
- registro de entrada y salida
- validacion por GPS
- validacion facial por captura
- historial personal de asistencias
- perfil del trabajador

Por ahora no se mantiene codigo activo del panel administrador dentro de la
aplicacion principal. La prioridad actual es consolidar y limpiar el flujo del
trabajador antes de abrir la siguiente fase del sistema.

## Estructura principal

- `lib/app/`
  contiene tema, rutas y configuracion visual general
- `lib/funcionalidades/autenticacion/`
  modulo de acceso y compuerta de sesion
- `lib/funcionalidades/asistencias/`
  modulo principal del trabajador
- `lib/funcionalidades/geolocalizacion/`
  validacion de GPS y distancia a la sede
- `lib/funcionalidades/reconocimiento_facial/`
  captura de imagen y deteccion facial
- `lib/funcionalidades/usuarios/`
  lectura de perfil institucional
- `lib/funcionalidades/sedes/`
  datos de sede y radio permitido
- `lib/funcionalidades/alertas/`
  registro de incidencias del flujo

## Requisitos funcionales

- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- permisos de camara
- permisos de ubicacion
- GPS activo en el dispositivo para validar asistencia

## Observaciones tecnicas

- La validacion facial actual detecta si hay un rostro valido en la imagen.
  Todavia no compara identidad biometrica contra un patron del trabajador.
- El historial personal se consulta desde Firestore y se ordena localmente.
- El proyecto sigue en proceso de limpieza tecnica y modularizacion.

## Ejecucion

```bash
flutter pub get
flutter run
```

## Pendientes recomendados

- completar limpieza tecnica del proyecto
- agregar pruebas de reglas de marcacion
- documentar colecciones de Firestore
- definir la siguiente fase del panel administrador
