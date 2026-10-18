import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Administración compatible con Spark. Firestore siempre usa la sesión admin.
class ServicioTrabajadoresFirebase {
  ServicioTrabajadoresFirebase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Future<SesionAltaTrabajador> Function()? abrirSesionAlta,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _abrirSesionAlta = abrirSesionAlta;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Future<SesionAltaTrabajador> Function()? _abrirSesionAlta;
  Future<SesionAltaTrabajador> _crearSesionAlta() async {
    final app = await Firebase.initializeApp(
      name: 'alta-trabajador-${DateTime.now().microsecondsSinceEpoch}',
      options: _auth.app.options,
    );
    return SesionAltaTrabajador(FirebaseAuth.instanceFor(app: app), app.delete);
  }

  Future<void> _exigirAdministrador() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'Inicia sesión como administrador.',
      );
    }
    final perfil = await _firestore
        .collection('usuarios')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (perfil.data()?['activo'] != true ||
        perfil.data()?['rol'] != 'administrador') {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'Se requiere un administrador activo.',
      );
    }
  }

  Future<String> crearTrabajadorConAcceso({
    required String nombreCompleto,
    required String correo,
    required String telefono,
    required String area,
    required String cargo,
    required String rol,
    required bool activo,
    required String sedeAsignadaId,
    required String password,
    DateTime? fechaInicioLabores,
  }) async {
    await _exigirAdministrador();
    final sesion = await (_abrirSesionAlta?.call() ?? _crearSesionAlta());
    final secundaria = sesion.auth;
    String? uid;
    try {
      if (kIsWeb) await secundaria.setPersistence(Persistence.NONE);
      UserCredential credencial;
      try {
        credencial = await secundaria.createUserWithEmailAndPassword(
          email: correo.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        // Recupera un alta incompleta únicamente demostrando acceso a esa cuenta.
        credencial = await secundaria.signInWithEmailAndPassword(
          email: correo.trim(),
          password: password,
        );
      }
      uid = credencial.user!.uid;
      final referencia = _firestore.collection('usuarios').doc(uid);
      await _firestore.runTransaction((transaccion) async {
        final existente = await transaccion.get(referencia);
        if (existente.exists) {
          throw FirebaseAuthException(
            code: 'profile-already-exists',
            message:
                'Este trabajador ya tiene perfil. Actualiza la lista y usa Editar.',
          );
        }
        final datos = <String, dynamic>{
          'nombreCompleto': nombreCompleto.trim(),
          'correo': credencial.user!.email,
          'telefono': telefono.trim(),
          'area': area.trim(),
          'cargo': cargo.trim(),
          'rol': rol.toLowerCase(),
          'activo': activo,
          'sedeAsignadaId': sedeAsignadaId,
          'creadoEn': FieldValue.serverTimestamp(),
          if (fechaInicioLabores != null)
            'fechaInicioLabores': fechaInicioLabores
                .toIso8601String()
                .substring(0, 10),
        };
        transaccion.set(referencia, datos);
      });
      return uid;
    } catch (error) {
      if (uid != null &&
          !(error is FirebaseAuthException &&
              error.code == 'profile-already-exists')) {
        // Auth y Firestore no son atómicos: nunca borrar una cuenta ante un
        // resultado ambiguo. El mismo correo/contraseña permite completar el alta.
        throw FirebaseAuthException(
          code: 'profile-save-unconfirmed',
          message:
              'La cuenta de acceso existe, pero no se confirmó el perfil. Actualiza la lista. '
              'Si no aparece, repite el alta con el mismo correo y contraseña.',
        );
      }
      rethrow;
    } finally {
      // Una falla de limpieza no debe convertir un alta confirmada en un error.
      try {
        await secundaria.signOut();
      } catch (_) {
        debugPrint('No se pudo cerrar la sesión auxiliar de alta.');
      } finally {
        try {
          await sesion.cerrar();
        } catch (_) {
          debugPrint('No se pudo liberar la instancia auxiliar de alta.');
        }
      }
    }
  }

  Future<void> actualizarTrabajador({
    required String uid,
    required String nombreCompleto,
    required String correo,
    required String telefono,
    required String area,
    required String cargo,
    required String rol,
    required bool activo,
    required String sedeAsignadaId,
    DateTime? fechaInicioLabores,
  }) async {
    await _exigirAdministrador();
    final referencia = _firestore.collection('usuarios').doc(uid);
    await _firestore.runTransaction((transaccion) async {
      final anterior = await transaccion.get(referencia);
      if (!anterior.exists) throw StateError('El perfil ya no existe.');
      if ((anterior.data()?['correo'] as String? ?? '').trim().toLowerCase() !=
          correo.trim().toLowerCase()) {
        throw FirebaseAuthException(
          code: 'email-change-not-supported',
          message: 'El correo de acceso no se puede cambiar desde este panel.',
        );
      }
      if (uid == _auth.currentUser?.uid &&
          (!activo || rol.toLowerCase() != 'administrador')) {
        throw FirebaseAuthException(
          code: 'self-access-change',
          message:
              'No puedes desactivar tu propia cuenta ni quitarte el rol de administrador.',
        );
      }
      final datos = <String, dynamic>{
        'nombreCompleto': nombreCompleto.trim(),
        'telefono': telefono.trim(),
        'area': area.trim(),
        'cargo': cargo.trim(),
        'rol': rol.toLowerCase(),
        'activo': activo,
        'sedeAsignadaId': sedeAsignadaId,
        if (fechaInicioLabores != null)
          'fechaInicioLabores': fechaInicioLabores.toIso8601String().substring(
            0,
            10,
          ),
      };
      transaccion.update(referencia, datos);
    });
  }

  Future<void> restablecerContrasenaTrabajador({required String uid}) async {
    await _exigirAdministrador();
    final perfil = await _firestore
        .collection('usuarios')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    final correo = perfil.data()?['correo'] as String?;
    if (correo == null || correo.trim().isEmpty) {
      throw StateError('El trabajador no tiene correo.');
    }
    await _auth.setLanguageCode('es');
    await _auth.sendPasswordResetEmail(email: correo.trim());
  }
}

/// Sesión separada: nunca autentica al trabajador en la instancia del administrador.
class SesionAltaTrabajador {
  const SesionAltaTrabajador(this.auth, this.cerrar);
  final FirebaseAuth auth;
  final Future<void> Function() cerrar;
}
