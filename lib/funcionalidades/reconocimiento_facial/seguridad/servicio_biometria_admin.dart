import 'package:cloud_firestore/cloud_firestore.dart';
import 'servicio_seguridad_biometrica.dart';
import 'formato_referencia.dart';
import '../../../nucleo/servicios/sesion_administrativa.dart';

class ServicioBiometriaAdmin {
  ServicioBiometriaAdmin({FirebaseFirestore? firestore, this.usuarioActual})
    : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;
  final String? Function()? usuarioActual;
  Future<void> habilitar(String uid) async {
    exigirSesionAdministrativa(usuarioActual: usuarioActual);
    await db.runTransaction((tx) async {
      final ref = db.collection('configuracionBiometrica').doc(uid);
      final actual = (await tx.get(ref)).data() ?? {};
      if (actual['estado'] == 'activo') {
        throw const ErrorBiometrico(
          'Primero retira el celular autorizado para habilitar uno nuevo.',
        );
      }
      final nueva = <String, dynamic>{
        'version': ((actual['version'] as num?)?.toInt() ?? 0) + 1,
        'estado': 'pendiente',
        'permitirEnrolamiento': true,
      };
      tx.set(ref, nueva);
      tx.delete(db.collection('vinculosBiometricosPrivados').doc(uid));
    });
    await _borrarAntiguos(uid);
  }

  Future<void> aprobar(String uid, String token) async {
    exigirSesionAdministrativa(usuarioActual: usuarioActual);
    await db.runTransaction((tx) async {
      final cfgRef = db.collection('configuracionBiometrica').doc(uid);
      final credRef = db.collection('credencialesBiometricas').doc(token);
      final cfg = (await tx.get(cfgRef)).data() ?? {};
      final cred = (await tx.get(credRef)).data() ?? {};
      if (cfg['permitirEnrolamiento'] != true ||
          cred['usuarioId'] != uid ||
          cred['estado'] != 'pendiente' ||
          cred['version'] != cfg['version']) {
        throw const ErrorBiometrico(
          'La solicitud cambió o ya no está vigente. Actualiza la lista.',
        );
      }
      final referencia = decodificarReferencia((cred['vector'] as Blob).bytes);
      referencia.fillRange(0, referencia.length, 0);
      tx.update(credRef, {
        'estado': 'aprobado',
        'aprobadoEn': FieldValue.serverTimestamp(),
      });
      tx.set(db.collection('vinculosBiometricosPrivados').doc(uid), {
        'token': token,
        'version': cfg['version'],
      });
      tx.update(cfgRef, {'estado': 'activo', 'permitirEnrolamiento': false});
    });
  }

  Future<void> revocarYEliminar(String uid) async {
    exigirSesionAdministrativa(usuarioActual: usuarioActual);
    await db.runTransaction((tx) async {
      final ref = db.collection('configuracionBiometrica').doc(uid);
      final actual = (await tx.get(ref)).data() ?? {};
      final nueva = <String, dynamic>{
        'version': ((actual['version'] as num?)?.toInt() ?? 0) + 1,
        'estado': 'revocado',
        'permitirEnrolamiento': false,
      };
      tx.set(ref, nueva);
      tx.delete(db.collection('vinculosBiometricosPrivados').doc(uid));
    });
    await _borrarAntiguos(uid);
  }

  Future<void> _borrarAntiguos(String uid) async {
    final cfg =
        (await db
                .collection('configuracionBiometrica')
                .doc(uid)
                .get(const GetOptions(source: Source.server)))
            .data() ??
        {};
    final docs = await db
        .collection('credencialesBiometricas')
        .where('usuarioId', isEqualTo: uid)
        .get(const GetOptions(source: Source.server));
    for (final doc in docs.docs) {
      final version = doc.data()['version'];
      final actual = cfg['version'];
      // Otra sesión administradora puede habilitar una versión más reciente.
      // Nunca borrar una solicitud creada después de esta consulta.
      if (version is num && actual is num && version < actual) {
        await doc.reference.delete();
      }
    }
    // Los comprobantes no contienen foto ni vector; se conservan como auditoría.
  }
}
