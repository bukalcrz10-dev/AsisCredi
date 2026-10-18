# Cargo reconocido en el panel, sin horario en Android

El perfil del trabajador muestra «Auxiliar de operaciones», pero la app instalada indica que el cargo no tiene horario.

## Evidencia

- Teléfono conectado: paquete `com.example.flutter_application_1`, versión 1.1.1, código 3, última actualización el 14 de octubre.
- Se inspeccionó una copia del APK instalado, sin acceder a datos privados de la cuenta. Su `kernel_blob.bin` contiene el literal `plataforma` y no contiene `auxiliar de operaciones`.
- La revisión anterior del código solo reconocía `plataforma`. El código actual también reconoce `auxiliar de operaciones`, conservando el mismo horario.
- El usuario confirmó que el cargo sí aparece correctamente en Perfil del celular. Actualizar el perfil no cambia el código del APK instalado.

## Validación y actualización

Las 34 pruebas de horarios y marcación actualizada pasaron. El análisis de los controladores y del caso de uso de perfil no encontró problemas. Se generó la versión Android 1.1.2 (4) con la compatibilidad existente en el código actual. No se modifica el cargo, las marcaciones, los horarios ni los datos en Firestore.

## Instalación verificada

- APK: `build/app/outputs/flutter-apk/app-release.apk`.
- Paquete y certificado coinciden con la app instalada. Se verificó la firma antes de actualizar.
- El literal `auxiliar de operaciones` está incluido en las tres arquitecturas del APK. Ambos modelos ONNX faciales siguen presentes.
- `adb install -r` terminó con `Success`; el dispositivo confirmó versión 1.1.2 y código 4 después de la actualización.
- Se abrió la app sin registrar asistencia. La comprobación visual queda pendiente de desbloquear el teléfono por parte del usuario.
