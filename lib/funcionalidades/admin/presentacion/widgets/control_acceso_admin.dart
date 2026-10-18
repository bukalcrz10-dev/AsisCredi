import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Se ubica sobre el navegador para bloquear también diálogos ya abiertos.
class ControlAccesoAdmin extends StatefulWidget {
  const ControlAccesoAdmin({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.sesiones,
    this.permisos,
    this.cerrarSesion,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final Stream<String?>? sesiones;
  // null: esperando confirmación del servidor; false: acceso retirado.
  final Stream<bool?> Function(String uid)? permisos;
  final Future<void> Function()? cerrarSesion;
  @override
  State<ControlAccesoAdmin> createState() => _ControlAccesoAdminState();
}

class _ControlAccesoAdminState extends State<ControlAccesoAdmin> {
  StreamSubscription<String?>? _auth;
  StreamSubscription<bool?>? _perfil;
  bool _permitido = false;
  bool _cerrando = false;
  bool _revocado = false;
  int _revision = 0;
  String? _uid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _auth =
        (widget.sesiones ??
                FirebaseAuth.instance.authStateChanges().map((u) => u?.uid))
            .listen(_cambiarUsuario, onError: (Object _) => _revocar());
  }

  Stream<bool?> _permisos(String uid) => FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map((doc) {
        if (doc.metadata.isFromCache || doc.metadata.hasPendingWrites) {
          return null;
        }
        return doc.data()?['activo'] == true &&
            doc.data()?['rol'] == 'administrador';
      });

  void _cambiarUsuario(String? uid) {
    final revision = ++_revision;
    _perfil?.cancel();
    _perfil = null;
    setState(() {
      _uid = uid;
      _permitido = uid == null;
      _revocado = false;
      _error = null;
    });
    if (uid == null) return;
    _perfil = (widget.permisos?.call(uid) ?? _permisos(uid)).listen(
      (permiso) {
        if (!mounted || revision != _revision || _revocado) return;
        if (permiso == false) {
          _revocar();
        } else {
          setState(() => _permitido = permiso == true);
        }
      },
      onError: (Object _) {
        if (mounted && revision == _revision) _revocar();
      },
    );
  }

  Future<void> _revocar() async {
    if (!mounted || _cerrando) return;
    final revision = _revision;
    setState(() {
      _permitido = false;
      _revocado = true;
      _cerrando = true;
      _error = null;
    });
    try {
      await (widget.cerrarSesion?.call() ?? FirebaseAuth.instance.signOut())
          .timeout(const Duration(seconds: 20));
      if (mounted) {
        widget.navigatorKey.currentState?.popUntil((ruta) => ruta.isFirst);
      }
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(
          () => _error =
              'No se pudo cerrar la sesión. El panel permanece bloqueado.',
        );
      }
    } finally {
      if (mounted) setState(() => _cerrando = false);
    }
  }

  @override
  void dispose() {
    _revision++;
    _auth?.cancel();
    _perfil?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ExcludeFocus(
        excluding: !_permitido,
        child: Offstage(offstage: !_permitido, child: widget.child),
      ),
      if (!_permitido)
        Positioned.fill(
          child: Material(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error == null) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _error ??
                        (_revocado
                            ? 'Cerrando sesión: no se pudo confirmar el acceso administrativo.'
                            : 'Verificando acceso administrativo con el servidor…'),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null)
                    TextButton(
                      onPressed: _cerrando ? null : _revocar,
                      child: const Text('Reintentar cierre'),
                    ),
                  if (_uid != null && !_revocado)
                    TextButton(
                      onPressed: _revocar,
                      child: const Text('Cerrar sesión'),
                    ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
