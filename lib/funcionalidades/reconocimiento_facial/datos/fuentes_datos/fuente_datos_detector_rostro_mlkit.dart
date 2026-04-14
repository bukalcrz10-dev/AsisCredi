import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../dominio/entidades/resultado_validacion_facial.dart';

// Fuente de datos basada en ML Kit.
// Traduce la imagen capturada por la camara a un InputImage
// y consulta cuantos rostros reconoce el detector.
class FuenteDatosDetectorRostroMlkit {
  FuenteDatosDetectorRostroMlkit()
      : _detectorRostros = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: false,
            enableClassification: false,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  final FaceDetector _detectorRostros;

  Future<ResultadoValidacionFacial> validarRostroEnImagen({
    required String rutaImagen,
  }) async {
    final imagen = InputImage.fromFilePath(rutaImagen);
    final rostros = await _detectorRostros.processImage(imagen);

    if (rostros.isEmpty) {
      return ResultadoValidacionFacial(
        permisoCamaraConcedido: true,
        rostroDetectado: false,
        cantidadRostros: 0,
        rutaImagenCapturada: rutaImagen,
        mensajeEstado:
            'No se detecto un rostro en la foto. Intenta nuevamente centrando tu cara.',
      );
    }

    if (rostros.length > 1) {
      return ResultadoValidacionFacial(
        permisoCamaraConcedido: true,
        rostroDetectado: false,
        cantidadRostros: rostros.length,
        rutaImagenCapturada: rutaImagen,
        mensajeEstado:
            'Se detectaron ${rostros.length} rostros en la foto. Captura nuevamente solo tu cara.',
      );
    }

    return ResultadoValidacionFacial(
      permisoCamaraConcedido: true,
      rostroDetectado: true,
      cantidadRostros: rostros.length,
      rutaImagenCapturada: rutaImagen,
      mensajeEstado:
          'Se detecto un rostro valido para continuar con la marcacion.',
    );
  }

  Future<void> cerrar() async {
    await _detectorRostros.close();
  }
}
