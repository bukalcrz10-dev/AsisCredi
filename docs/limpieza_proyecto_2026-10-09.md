# Limpieza conservadora del proyecto — 9 de octubre de 2026

## Alcance

Revisión de referencias Dart en `lib` y `test`, dependencias declaradas y utilizadas, recursos Android, archivos versionados/generados y organización de carpetas. Solo se aplicaron eliminaciones sin consumidores y un cambio de nomenclatura interna. No se modificaron datos de usuarios, Firebase, rutas, permisos, autenticación, horarios, reglas, cálculos ni valores visuales.

## Archivos retirados

Se eliminaron los cinco recursos antiguos `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (43 919 bytes en total) y sus carpetas, al quedar vacías. El manifiesto utiliza `@drawable/ic_crediasciende_circular`, no esos recursos. Se conservaron el ícono circular actual, su variante Android 8+, el PNG nativo y el logo Flutter; estas dos copias del logo pertenecen a mecanismos de carga diferentes y ambas se utilizan.

No se borraron capturas locales, documentos de auditoría, registros de diagnóstico, configuraciones del IDE, cachés ni compilaciones existentes. Ya están ignorados cuando corresponde y no hay necesidad de borrarlos para limpiar el código versionado. Se conservaron archivos de registro de plugins generados por Flutter y recursos de otras plataformas: no son seguros de eliminar únicamente por ser generados.

## Código retirado

Sin referencias en la app o pruebas:

- `ControladorAsistencia.ultimaEntrada` y `ultimaSalida`.
- `obtenerUltimaMarcacionPorTipo`, usado únicamente por esos dos getters.
- `formatearFechaControlAsistencia`.
- Getters `siguienteEtiquetaAccion`, `siguienteAccionHabilitada` y `mensajeEsperaSiguienteAccion`.

Se conservaron las versiones parametrizadas utilizadas, las validaciones y los auxiliares históricos cubiertos por pruebas. Se aplicó formato Dart a los archivos modificados. No se hicieron cambios de comportamiento para resolver los problemas funcionales de la auditoría anterior.

## Organización

`trabajador_admin_demo.dart` pasó a `trabajador_admin.dart` y `TrabajadorAdminDemo` a `TrabajadorAdmin`: el modelo representa trabajadores reales. Se actualizaron el módulo administrativo y su prueba. No cambian sus propiedades ni métodos. La comprobación de imports no encontró archivos Dart sin referencias salvo `main.dart`, que es el punto de entrada. No se detectaron carpetas vacías en `lib`, `assets` o `test`.

## Dependencias y optimización

- Conservado `cupertino_icons`: la búsqueda no encontró usos directos, pero la compilación web detectó una referencia indirecta de Flutter a esa fuente al probar su retirada. Se restauró para preservar los íconos predeterminados.
- Retirado `http` de dependencias directas: no se importa desde el código; permanece como dependencia transitiva de otras bibliotecas.
- Se resolvió con `pub get --offline`, conservando las versiones de las demás dependencias. No se ejecutó una actualización general.
- No se alteraron consultas ni se introdujeron cachés que pudieran cambiar la actualización de los datos. La mejora consiste en reducir recursos, código y dependencias directas sin uso; no se afirma una aceleración medida del sistema.

## Verificación

- Suite completa: **91 pruebas aprobadas**, sin retirar pruebas.
- Compilación Android debug: **correcta**, APK en `build/app/outputs/flutter-apk/app-debug.apk`.
- Resolución offline de dependencias: correcta; sin actualización de versiones ajenas a la limpieza.
- `git diff --check`: correcto, sin errores de espacios o conflictos.
- Revisión de referencias antiguas: sin usos residuales del modelo renombrado ni de los recursos retirados.
- Análisis final: **sin problemas**.
- Compilación web estándar final: **correcta**, salida en `build/web`, sin advertencia de fuente Cupertino faltante.
- Android se volvió a compilar correctamente tras conservar Cupertino; el APK final incluye el estado definitivo de la limpieza.

Las pruebas de PDF muestran la advertencia ya existente sobre soporte Unicode de Helvetica. Se conservó la fuente para no modificar el aspecto de los informes. Las comprobaciones automáticas no sustituyen una prueba real de cámara, GPS y Firebase en el dispositivo; no se hicieron marcaciones reales ni se verificó el servicio remoto durante esta limpieza.

La comprobación preliminar de WebAssembly informó incompatibilidades en la dependencia `image 4.3.0`. La compilación web estándar JavaScript sí funciona. No se actualizaron bibliotecas ni se cambió la modalidad de compilación para esta limpieza.

## Recomendaciones fuera del alcance

Los hallazgos funcionales del [diagnóstico previo](revision_proyecto_2026-10-08.md), como la consulta administrativa limitada a 300 marcas, estados de observación, identidad facial y validaciones de Firestore, requieren cambios de comportamiento. No se tocaron. Deben autorizarse como tareas separadas.

No cambiar nombres de campos de Firestore, identificadores de la aplicación, firma Android ni clases/rutas de acceso como parte de una limpieza. La descripción del paquete y algunos identificadores internos históricos conservan nombres anteriores; modificarlos no es necesario para esta tarea y se evita ampliar su alcance.

No se publicó esta limpieza en GitHub ni se instaló en el celular durante la revisión.
