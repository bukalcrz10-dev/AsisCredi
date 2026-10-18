# Perfil vigente y GPS reciente al confirmar asistencia

Antes de enviar una marcación, el controlador vuelve a consultar el perfil activo
y la sede en Firestore. Las fuentes usadas por el módulo de asistencia exigen
respuesta del servidor; el resto de consumidores mantiene su configuración anterior.
Si falla la consulta, no se guarda usando el perfil anterior.

Después se consulta el historial del servidor, se comprueba el rostro y se solicita
otra lectura GPS contra las coordenadas y el radio de la sede recién consultada.
La ubicación de la pantalla previa se descarta. Un fallo del GPS, un permiso
denegado o una ubicación fuera del radio impiden el envío. El GPS tiene un límite
de consulta de 20 segundos; se rechazan lecturas de más de 30 segundos o con una
fecha superior en más de 5 segundos al reloj del dispositivo.

El horario guardado en una jornada iniciada prevalece sobre el cargo actualizado.
Sin jornada iniciada se usa el cargo nuevo. Tras esperar al GPS se vuelven a
comprobar la fecha, la ventana permitida y la secuencia. Un segundo toque no
inicia otra operación mientras se está confirmando.

No se cambió el diseño, los horarios ni los cálculos. No se modificaron las reglas
publicadas de Firestore, la facturación ni los registros reales. El cambio de la
app requiere instalar una compilación nueva; no se aplica al APK ya instalado.

## Verificación

- Suite Flutter completa: 115 pruebas aprobadas.
- `flutter analyze --no-pub`: sin incidencias.
- `flutter build apk --debug --no-pub`: compilación correcta;
  APK en `build/app/outputs/flutter-apk/app-debug.apk`.
- Pruebas nuevas del controlador: cambio de sede, GPS anterior, fallo GPS,
  fallo de red, perfil retirado/inactivo, sede inactiva, cargo nuevo,
  horario original de jornada iniciada, cierre de ventana y doble confirmación.
- Pruebas de la fuente GPS: rechaza timestamps antiguos/futuros y acepta
  una posición reciente con tiempo de consulta limitado.
- No se realizó una marcación real ni se instaló automáticamente en un celular.

## Límites y prueba manual

La actualización sucede al cargar/actualizar el perfil y al confirmar la marca;
no se añadió una suscripción continua a cambios de cargo o sede. Los cambios
remotos posteriores a la consulta no son atómicos con el GPS: las reglas de
Firestore siguen siendo la autoridad al escribir. El GPS sigue dependiendo
del dispositivo; no se añadió detección de ubicación simulada ni reconocimiento
de identidad facial.

Con cuentas de prueba y dentro de una ventana válida, comprobar que salir del
radio después de la primera validación impide confirmar, y que cambiar la sede
desde el administrador hace que la confirmación evalúe la nueva ubicación.
Probar también GPS apagado o internet desconectado: no debe reutilizar la
validación anterior. Si el cambio de cargo ocurre tras la primera marca del día,
debe conservarse el horario de esa jornada.
