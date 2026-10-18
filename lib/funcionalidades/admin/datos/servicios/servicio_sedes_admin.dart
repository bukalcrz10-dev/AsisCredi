import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../nucleo/servicios/sesion_administrativa.dart';

Future<void> guardarSedeAdministrativa({
  required String id,
  required Map<String, dynamic> datos,
  FirebaseFirestore? firestore,
  String? Function()? usuarioActual,
}) async {
  exigirSesionAdministrativa(usuarioActual: usuarioActual);
  final db = firestore ?? FirebaseFirestore.instance;
  await db.runTransaction((tx) async {
    tx.set(db.collection('sedes').doc(id), datos);
  });
}
