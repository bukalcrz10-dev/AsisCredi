import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

enum EstadoPerfilActivo { verificando, activo, inactivo, sinPerfil }

EstadoPerfilActivo evaluarPerfilActivo({
  required bool desdeCache,
  required bool existe,
  required bool activo,
}) {
  if (desdeCache) return EstadoPerfilActivo.verificando;
  if (!existe) return EstadoPerfilActivo.sinPerfil;
  return activo ? EstadoPerfilActivo.activo : EstadoPerfilActivo.inactivo;
}

/// Solo permite acceso con un perfil activo confirmado por el servidor.
class AccesoPerfilActivo extends StatefulWidget {
  const AccesoPerfilActivo({
    super.key,
    required this.permisos,
    required this.onCerrarSesion,
    required this.child,
  });
  final Stream<EstadoPerfilActivo> permisos;
  final Future<void> Function() onCerrarSesion;
  final Widget child;
  @override
  State<AccesoPerfilActivo> createState() => _AccesoPerfilActivoState();
}

class _AccesoPerfilActivoState extends State<AccesoPerfilActivo> {
  StreamSubscription<EstadoPerfilActivo>? _suscripcion;
  Timer? _espera;
  EstadoPerfilActivo _estado = EstadoPerfilActivo.verificando;
  String? _error;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _escuchar();
  }

  @override
  void didUpdateWidget(AccesoPerfilActivo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permisos != widget.permisos) _escuchar();
  }

  void _iniciarEspera() {
    _espera ??= Timer(const Duration(seconds: 20), () {
      if (!mounted || _estado != EstadoPerfilActivo.verificando) return;
      setState(
        () => _error =
            'No se pudo confirmar tu perfil con el servidor. '
            'Revisa tu conexión a internet y pulsa Reintentar.',
      );
    });
  }

  void _escuchar() {
    final revision = ++_revision;
    _suscripcion?.cancel();
    _espera?.cancel();
    _espera = null;
    _estado = EstadoPerfilActivo.verificando;
    _error = null;
    _iniciarEspera();
    _suscripcion = widget.permisos.listen(
      (estado) {
        if (!mounted || revision != _revision) return;
        setState(() {
          _estado = estado;
          if (estado == EstadoPerfilActivo.verificando) {
            _iniciarEspera();
          } else {
            _error = null;
            _espera?.cancel();
            _espera = null;
          }
        });
      },
      onError: (Object error) {
        if (!mounted || revision != _revision) return;
        _espera?.cancel();
        _espera = null;
        setState(
          () => _error =
              error is FirebaseException && error.code == 'permission-denied'
              ? 'No tienes permiso para consultar tu perfil. Contacta al administrador.'
              : 'No se pudo consultar tu perfil. Revisa tu conexión a internet y pulsa Reintentar.',
        );
      },
    );
  }

  @override
  void dispose() {
    _revision++;
    _suscripcion?.cancel();
    _espera?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null && _estado == EstadoPerfilActivo.activo) {
      return widget.child;
    }
    final esperando =
        _error == null && _estado == EstadoPerfilActivo.verificando;
    final mensaje =
        _error ??
        switch (_estado) {
          EstadoPerfilActivo.verificando =>
            'Verificando tu perfil con el servidor…',
          EstadoPerfilActivo.inactivo =>
            'Tu perfil no está habilitado. Contacta al administrador.',
          EstadoPerfilActivo.sinPerfil =>
            'Tu cuenta no tiene un perfil de trabajador registrado. Contacta al administrador.',
          EstadoPerfilActivo.activo => '',
        };
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (esperando)
                const CircularProgressIndicator()
              else
                const Icon(Icons.lock_outline, size: 40),
              const SizedBox(height: 16),
              Text(mensaje, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (_error != null)
                TextButton(
                  onPressed: () => setState(_escuchar),
                  child: const Text('Reintentar'),
                ),
              TextButton(
                onPressed: widget.onCerrarSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
