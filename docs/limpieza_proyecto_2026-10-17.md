# Limpieza conservadora del proyecto — 17 de octubre de 2026

## Alcance

Continuación de la [limpieza del 9 de octubre](limpieza_proyecto_2026-10-09.md). Se revisaron las referencias de los archivos Dart y sus símbolos públicos en `lib` y `test`, las importaciones de paquetes, los recursos declarados y los archivos locales generados. Se conservaron los cambios anteriores del proyecto.

No se modificaron diseños, rutas, horarios, cálculos utilizados, validaciones, consultas, reglas ni datos de Firebase. No se actualizaron versiones de dependencias, no se publicó la web y no se instaló ninguna aplicación.

## Cambios

- Retirados cuatro getters sin consumidores en código ni pruebas: `InformeAsistenciasTrabajador.diasConTardanza`, `ResumenJornadaTrabajador.siguienteTipoMarcacion`, `ResumenDiaHistorial.esAsesor` y `ResumenDiaHistorial.estadoTexto`. Se retiró también el getter privado `_ahora`, cuyo único consumidor era `siguienteTipoMarcacion`. La aplicación mantiene los métodos parametrizados y estados que realmente utiliza.
- Eliminado `assets/imagenes/logo_unachu.txt`: era una guía temporal para un logo anterior, sin referencias. Se conservan el logo actual, los modelos faciales y sus licencias.
- Añadido `/.firebase/` a `.gitignore`: contiene la caché local de Hosting. No se eliminan configuraciones ni archivos remotos.
- Corregidos comentarios obsoletos sobre alertas y la fase inicial de detección facial. README describe la comparación facial y parpadeos que ya existían; no se cambia su implementación.
- Retiradas líneas vacías sobrantes al final de cuatro archivos señalados por `git diff --check`.

## Elementos conservados

Todos los archivos Dart tienen referencias. No se renombraron carpetas ni modelos que ya estaban bien organizados. Las dependencias tienen importaciones reales; `cupertino_icons` se conserva por la dependencia indirecta de Flutter ya comprobada en la limpieza anterior. No se actualizó `pubspec.lock`.

Los métodos de Flutter como `paint`, `shouldRepaint` y `updateShouldNotify` se conservan aunque una búsqueda textual no encuentre llamadas: los invoca el framework. También se conservan las pruebas, documentación histórica, respaldos, compilaciones y recursos de otras plataformas.

## Verificación

- Suite completa de Flutter: **253 pruebas aprobadas**, sin modificar ni retirar pruebas.
- Tras retirar `_ahora`: **39 pruebas de horarios y calendario aprobadas**.
- Formato Dart: correcto, sin cambios pendientes en los cinco archivos revisados.
- `git diff --check`: correcto tras retirar las líneas vacías sobrantes.
- Análisis estático final: **sin problemas**.
- Compilación web de producción final: **correcta**, salida local en `build/web` (117 segundos).

No se ejecutan pruebas remotas ni marcaciones reales. No se recompila ni instala la APK: no hay cambios funcionales ni nativos en esta limpieza (solo espacios al final de archivos Android). El APK preparado anteriormente sigue disponible.
