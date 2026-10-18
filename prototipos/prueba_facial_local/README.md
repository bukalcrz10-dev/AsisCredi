# Prueba facial local — CREDIASCIENDE

Prototipo Android independiente para evaluar comparación 1:1 de rostros. No inicia sesión, no usa Firebase, no registra asistencias y no tiene permiso INTERNET en su manifiesto release. Su identificador `pe.crediasciende.prueba_facial_local` permite instalarlo junto a la app existente.

## Cómo probar

1. Instalar el APK del prototipo y abrir **Prueba facial local**.
2. Activar modo avión. Aceptar participar y permitir la cámara.
3. Pulsar **Tomar referencia**, pulsar **Iniciar** y parpadear dos veces despacio mirando de frente. La imagen se captura automáticamente después de abrir los ojos.
4. Pulsar **Tomar foto y comparar** y repetir los dos parpadeos con la misma persona.
5. Repetir varias veces con diferentes condiciones razonables de iluminación y pequeños cambios de postura.
6. Mantener la referencia y comparar con otra persona que acepte participar: debe quedar por debajo del umbral.
7. Probar sin cara y con dos caras: debe pedir una nueva captura.
8. Pulsar **Borrar referencia**. Comparar queda deshabilitado hasta registrar una nueva.

No basta con una coincidencia para validar el sistema. Registrar resultados sin nombres: caso A/B, misma/distinta persona, luz, gafas, similitud, resultado esperado, resultado obtenido y tiempo. Como prueba inicial, realizar al menos 10 capturas por participante y varias comparaciones entre participantes. Esto no sustituye una evaluación representativa de falsos positivos y falsos negativos.

## Alcance y costos

- Motor OpenCV 4.12.0, YuNet para detección y alineación con cinco puntos, SFace para obtener 128 características y comparación por similitud coseno.
- Los modelos se incluyen en el APK; no se descargan al tomar fotos ni se consulta ninguna API.
- No hay suscripciones ni cobros por comparación. No se activa Blaze ni Cloud Functions.
- La referencia es un vector temporal en memoria, no una cuenta de trabajador ni un enrolamiento administrativo real. No se guarda en preferencias, archivos o servidor.
- Los fotogramas y la captura final se procesan en memoria. La referencia no se guarda. Versiones anteriores pueden haber dejado caché ante cierres inesperados.
- Se desactiva el respaldo Android y se usa FLAG_SECURE para impedir capturas de pantalla convencionales. No constituye protección contra dispositivos manipulados.
- **Incluye dos parpadeos experimentales.** No garantiza bloquear videos o fotografías manipuladas, ni constituye detección de suplantación certificada. No autoriza asistencias.
- Umbral de comparación **0.52** conservado en la versión **0.3.0+5**. Reemplaza el inicial 0.363 del ejemplo SFace/LFW. Es provisional, no está calibrado para esta empresa. La puntuación no es porcentaje de certeza.

### Antecedente: versión 0.2.1 — retorno a captura simple

Por solicitud del usuario se retiraron los gestos, su analizador nativo, sus pruebas específicas y la dependencia ML Kit del prototipo. Se conserva la comparación local y el umbral 0.52. La versión aumenta para instalarse como actualización sobre la prueba de gestos.

### Segunda ronda — 12 de octubre de 2026

Se eligió 0.52 para explorar nuevas capturas después de observar otras personas entre 0.207 y 0.487 (7 capturas) y la persona de referencia entre 0.646 y 0.819 (5 capturas). Estos datos sirvieron para ajustar el umbral: no constituyen validación independiente ni garantizan precisión.

Instalar el APK actualizado y comprobar que el resultado muestre `Umbral: 0.52`. Mantener fijo este umbral durante la ronda. Tomar una referencia nueva de A, obtener 10 capturas nuevas de A y 10 de otras personas participantes, sin reemplazar la referencia entre comparaciones. Repetir cambiando la referencia a B y, si es posible, C. Mantener anotados también los errores y las capturas rechazadas por calidad, sin descartar resultados desfavorables ni reemplazarlos por reintentos exitosos.

Anotar por intento: código de referencia, código de persona capturada, luz/gafas, similitud, coincidencia esperada/obtenida y tiempo. No hacen falta nombres ni fotografías para informar los resultados. No usarlo para registrar asistencias.

## Procedencia

Los modelos proceden del repositorio oficial OpenCV Zoo, revisión fijada en `modelos.json`. Sus SHA-256 se verificaron contra los punteros Git LFS oficiales antes de usarlos. Se incluyen las licencias de cada modelo y de OpenCV en `licencias/`, accesibles también desde la pantalla de información.

- [SFace y licencia Apache 2.0](https://github.com/opencv/opencv_zoo/tree/47534e27c9851bb1128ccc0102f1145e27f23f98/models/face_recognition_sface)
- [YuNet y licencia MIT](https://github.com/opencv/opencv_zoo/tree/47534e27c9851bb1128ccc0102f1145e27f23f98/models/face_detection_yunet)
- [Ejemplo de alineación y comparación](https://docs.opencv.org/4.13.0/d0/dd4/tutorial_dnn_face.html)
- [OpenCV en Android mediante Maven](https://docs.opencv.org/4.13.0/d5/df8/tutorial_dev_with_OCV_on_Android.html)

## Compilación

Desde esta carpeta: `flutter pub get`, `flutter test`, `flutter analyze` y `flutter build apk --release`. Es un APK de prueba firmado con la clave debug local, aunque se compila en modo release para medir mejor el rendimiento. No publicarlo en una tienda como producto final.

El código Kotlin realiza la inferencia en un hilo de trabajo; valida imagen, orientación EXIF, número de caras, tamaño mínimo y vector finito. Dart calcula la similitud. No se conecta el resultado al módulo de asistencia.

## Evidencia de prueba inicial

Compilación release Android correcta (APK universal de unos 172.5 MB, firmado para pruebas). El manifiesto combinado incluye cámara y no incluye INTERNET. Cuatro pruebas Flutter aprobadas y análisis del prototipo sin incidencias. No se instaló automáticamente en ningún teléfono.

Se ejecutaron los modelos reales con OpenCV 4.12.0 en escritorio, usando dos imágenes del repositorio oficial de muestras de OpenCV (no datos de trabajadores). Resultado de humo:

| Caso | Resultado |
| --- | --- |
| Vector de salida | 128 valores finitos |
| Misma imagen con luz modificada | Similitud 0.989557 |
| Imágenes de personas distintas | Similitud 0.130308 |
| Imagen sin rostro | Cero caras |
| Imagen con dos caras | Dos caras |

Estos casos prueban carga y ejecución básica, **no precisión biométrica ni funcionamiento de cámara Android**. No había dispositivo conectado. La prueba en un teléfono real sigue siendo necesaria.

El script `tools/validar_modelos.py` reproduce la prueba de escritorio cuando se dispone de OpenCV 4.12.0 y las muestras locales indicadas. Las muestras y los paquetes Python de prueba quedan en `.dart_tool` del proyecto principal y no forman parte del APK.


## Verificación histórica del retorno a captura simple

Versión 0.2.1+4: cuatro pruebas Flutter aprobadas y análisis estático sin incidencias. Se retiró la dependencia del detector de gestos. La cámara y la captura deben comprobarse en el teléfono al instalar la actualización.
Compilación Android release correcta: APK universal de 172.5 MB. No se instaló automáticamente en un teléfono.

## Versión actual 0.3.0+5 — dos parpadeos

Solo en el prototipo. No cambia asistencia, Firebase ni vincula un celular.
Tanto referencia como comparación requieren dos ciclos abierto-cerrado-abierto.
Se exige una cara frontal con seguimiento continuo; la pérdida/cambio de cara,
pausa de la app, fotogramas repetidos o interrupción de imágenes invalidan el intento.
Límite de 20 segundos, cierre máximo de 1.5 segundos y dos observaciones de
ojos abiertos para confirmar cada reapertura. La captura proviene del mismo
fotograma analizado al completar el segundo parpadeo, sin captura libre posterior.

Detector ML Kit 16.1.7 incluido en el APK, sin descarga en el celular:
https://developers.google.com/ml-kit/vision/face-detection/android
Su seguimiento no demuestra identidad; SFace realiza después la comparación.
Los parpadeos predecibles pueden reproducirse en video. No se afirma resistencia
certificada a ataques. Sus licencias/términos son distintos de los modelos OpenCV.

Pruebas manuales: modo avión, dos parpadeos despacio con buena luz, ojos quietos,
un solo parpadeo, otra persona, gafas, pérdida del encuadre, dos caras, cancelar,
salir y regresar, foto estática y video. Anotar errores sin descartar intentos
fallidos. La velocidad real y la detección de parpadeos requieren probar en el
teléfono; las pruebas simuladas no validan resistencia a suplantación.

Verificación 0.3.0: diez pruebas aprobadas, análisis sin incidencias y compilación release correcta (199.4 MB). Pendiente prueba física en celular.

## Actualización 0.3.1+6 — diagnóstico del conteo

El usuario informó que la cámara abre pero no cuenta los parpadeos. No se reprodujo en un teléfono local. Se inicia automáticamente al abrir la cámara y se muestran instrucciones según el estado y probabilidades de apertura de ambos ojos. Se quita el descarte adicional de frames por 60 ms (se mantiene una sola inferencia simultánea). Solo se solicita JPEG al confirmar la reapertura final, evitando comprimir cada fotograma después del primer parpadeo. Umbrales oculares y de comparación conservados. Pendiente confirmar con el dispositivo afectado; no se afirma una causa definitiva.
Verificación 0.3.1: diez pruebas aprobadas, análisis sin incidencias y APK release compilado correctamente.

## Actualización 0.3.2+7 — compatibilidad de cámara

El dispositivo informó Formato de cámara incompatible. La captura ahora solicita YUV420 y convierte sus tres planos Y/U/V a NV21 respetando bytesPerRow y bytesPerPixel, incluyendo padding y último byte sin padding. Se conserva compatibilidad con NV21 compacto de un plano cuando el formato lo identifica. Se rechazan buffers truncados antes de procesarlos. Pruebas con muestras sintéticas de YUV planar e intercalado; pendiente validar cámara física afectada. No cambia umbral ni número de parpadeos.
Verificación 0.3.2: trece pruebas aprobadas, análisis sin incidencias y APK release compilado correctamente.

## Actualización 0.3.3+8 — procesamiento sin respuesta

Reporte: tres minutos en Procesando en el celular. No se reprodujo en hardware local ni se conoce todavía la etapa nativa bloqueada. Se añade timeout de 45 segundos, progreso por etapas, liberación de ML Kit antes de OpenCV, límite de dos hilos OpenCV y exclusión de extracciones simultáneas. Un timeout no cancela una inferencia nativa; si sigue ocupada, se pide cerrar completamente la app. Los resultados tardíos no guardan referencias. Prueba automatizada de timeout y respuesta tardía aprobada, junto a las otras trece pruebas. Análisis sin incidencias. Pendiente validación en celular real.
APK 0.3.3 release compilado correctamente. Instalación y prueba en el dispositivo afectado pendientes.

## Actualización 0.3.4+9 — inferencia CPU con un hilo

Reporte en Xiaomi 13: la comparación simple funcionaba antes de los parpadeos; ahora se detiene en Calculando las características del rostro. Se conserva SFace, pero se configura explícitamente backend OpenCV/CPU y un único hilo interno. Se valida recorte 112×112 BGR de 8 bits antes de inferencia y se distingue la etapa posterior de validación del vector. Es una mitigación que requiere prueba en el teléfono, no una causa confirmada. Se mantiene el timeout de 45 segundos. API de configuración: https://docs.opencv.org/4.13.0/javadoc/org/opencv/objdetect/FaceRecognizerSF.html . Catorce pruebas Flutter aprobadas y análisis sin incidencias. La prueba de modelos en escritorio no pudo ejecutarse porque cv2 ya no está disponible en el entorno local de pruebas; no se reinstalaron dependencias.
APK 0.3.4 compilado correctamente. Verificación física en Xiaomi 13 pendiente.

## Versión 0.3.5+10 — diagnóstico de respuesta y pantalla

El usuario informa indicador activo por más de un minuto pese al timeout Dart. La causa real sigue sin reproducirse en hardware. Se muestra versión fija 0.3.5 y contador en la cabecera, con errores arriba para evitar mensajes fuera de vista. Se agrega respuesta única nativa con límite 40 s mediante Handler del hilo principal y se conserva timeout Dart 45 s. Estos límites requieren que los respectivos bucles de eventos respondan; no cancelan una inferencia nativa ni garantizan recuperar un proceso entero congelado. Se desglosan lectura, comprobación del vector y liberación de imágenes. Si se congela también el contador, obtener logcat del dispositivo en vez de seguir ajustando umbrales. No cambia la comparación ni integra asistencia.
Verificación 0.3.5: dieciséis pruebas aprobadas, análisis sin incidencias y APK release compilado. Pendiente diagnóstico en teléfono real.

## Versión 0.3.6+11 — referencia lista con botones deshabilitados

Se reprodujo el fallo con Uint8List.asUnmodifiableView en la captura devuelta: fillRange lanzaba UnsupportedError dentro del finally antes de restablecer _ocupado. La prueba mostraba Referencia lista pero Comparar y Reemplazar referencia seguían deshabilitados. Ahora se crea una copia mutable propia antes de limpiar, y un finally interior garantiza liberar la interfaz. Se aplica la misma propiedad de buffers a imágenes del canal en la cámara. La regresión verifica explícitamente los botones con captura de solo lectura tanto en éxito como en error. No modifica SFace, los parpadeos ni los umbrales.
Verificación 0.3.6: dieciséis pruebas aprobadas, análisis sin incidencias y APK release generado; manifiesto comprobado con versión 0.3.6 y código 11.
