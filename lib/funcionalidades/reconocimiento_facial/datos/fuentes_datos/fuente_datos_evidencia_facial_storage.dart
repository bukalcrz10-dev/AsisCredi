import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../asistencias/dominio/entidades/tipo_marcacion.dart';

// Fuente de datos encargada de subir la foto facial a Firebase Storage.
// Mantiene aislado el detalle del proveedor para que el controlador
// solo reciba una URL utilizable dentro de la asistencia.
class FuenteDatosEvidenciaFacialStorage {
  FuenteDatosEvidenciaFacialStorage({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> subirEvidenciaFacial({
    required String usuarioId,
    required String rutaImagenLocal,
    required DateTime fechaHora,
    required TipoMarcacion tipoMarcacion,
  }) async {
    final archivo = File(rutaImagenLocal);
    final fechaCompacta = fechaHora.toIso8601String().replaceAll(':', '-');

    // Organizamos las evidencias por usuario y fecha para que
    // luego el panel administrativo pueda encontrarlas con facilidad.
    final referencia = _storage.ref(
      'evidencias_faciales/$usuarioId/${tipoMarcacion.name}_$fechaCompacta.jpg',
    );

    await referencia.putFile(
      archivo,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'usuarioId': usuarioId,
          'tipoMarcacion': tipoMarcacion.name,
          'fechaHora': fechaHora.toIso8601String(),
        },
      ),
    );

    return referencia.getDownloadURL();
  }
}
