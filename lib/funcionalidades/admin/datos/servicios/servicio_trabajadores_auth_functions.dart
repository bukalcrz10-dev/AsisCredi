import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ServicioTrabajadoresAuthFunctions {
  ServicioTrabajadoresAuthFunctions({
    FirebaseAuth? auth,
    http.Client? client,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client();

  static const _baseUrl =
      'https://us-central1-asistenciageolocalizacio-368fc.cloudfunctions.net';

  final FirebaseAuth _auth;
  final http.Client _client;

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
  }) async {
    final usuarioActual = _auth.currentUser;
    if (usuarioActual == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'No hay una sesion administrativa activa.',
      );
    }

    final idToken = await usuarioActual.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user-token',
        message: 'No se pudo obtener el token de la sesion administrativa.',
      );
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/crearTrabajadorConAccesoHttp'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(<String, dynamic>{
        'nombreCompleto': nombreCompleto,
        'correo': correo,
        'telefono': telefono,
        'area': area,
        'cargo': cargo,
        'rol': rol.toLowerCase(),
        'activo': activo,
        'sedeAsignadaId': sedeAsignadaId,
        'password': password,
      }),
    );

    final dynamic cuerpoDecodificado = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    final Map<String, dynamic> datos = cuerpoDecodificado is Map<String, dynamic>
        ? cuerpoDecodificado
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return datos['uid'] as String? ?? '';
    }

    throw FirebaseAuthException(
      code: (datos['codigo'] as String?) ?? 'internal',
      message: (datos['mensaje'] as String?) ??
          'No se pudo crear el trabajador con acceso.',
    );
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
  }) async {
    final usuarioActual = _auth.currentUser;
    if (usuarioActual == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'No hay una sesion administrativa activa.',
      );
    }

    final idToken = await usuarioActual.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user-token',
        message: 'No se pudo obtener el token de la sesion administrativa.',
      );
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/actualizarTrabajadorHttp'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(<String, dynamic>{
        'uid': uid,
        'nombreCompleto': nombreCompleto,
        'correo': correo,
        'telefono': telefono,
        'area': area,
        'cargo': cargo,
        'rol': rol.toLowerCase(),
        'activo': activo,
        'sedeAsignadaId': sedeAsignadaId,
      }),
    );

    final dynamic cuerpoDecodificado = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    final Map<String, dynamic> datos = cuerpoDecodificado is Map<String, dynamic>
        ? cuerpoDecodificado
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw FirebaseAuthException(
      code: (datos['codigo'] as String?) ?? 'internal',
      message:
          (datos['mensaje'] as String?) ?? 'No se pudo actualizar el trabajador.',
    );
  }

  Future<void> restablecerContrasenaTrabajador({
    required String uid,
    required String password,
  }) async {
    final usuarioActual = _auth.currentUser;
    if (usuarioActual == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'No hay una sesion administrativa activa.',
      );
    }

    final idToken = await usuarioActual.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user-token',
        message: 'No se pudo obtener el token de la sesion administrativa.',
      );
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/restablecerContrasenaTrabajadorHttp'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(<String, dynamic>{
        'uid': uid,
        'password': password,
      }),
    );

    final dynamic cuerpoDecodificado = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    final Map<String, dynamic> datos = cuerpoDecodificado is Map<String, dynamic>
        ? cuerpoDecodificado
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw FirebaseAuthException(
      code: (datos['codigo'] as String?) ?? 'internal',
      message: (datos['mensaje'] as String?) ??
          'No se pudo restablecer la contrasena del trabajador.',
    );
  }
}
