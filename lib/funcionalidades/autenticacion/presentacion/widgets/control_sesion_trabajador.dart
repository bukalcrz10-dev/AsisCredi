import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controladores/sesion_trabajador.dart';

/// Envuelve el navegador para cubrir tambien camara, dialogos y otras rutas.
class ControlSesionTrabajador extends StatefulWidget {
  const ControlSesionTrabajador({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.sesion,
    this.sesiones,
    this.usuarioActual,
    this.cerrarSesion,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final SesionTrabajador? sesion;
  final Stream<String?>? sesiones;
  final String? Function()? usuarioActual;
  final Future<void> Function()? cerrarSesion;
  @override
  State<ControlSesionTrabajador> createState() =>
      _ControlSesionTrabajadorState();
}

class _ControlSesionTrabajadorState extends State<ControlSesionTrabajador>
    with WidgetsBindingObserver {
  late final _sesion = widget.sesion ?? SesionTrabajador.instancia;
  StreamSubscription<String?>? _suscripcion;
  String? get _usuarioActual => widget.usuarioActual != null
      ? widget.usuarioActual!()
      : FirebaseAuth.instance.currentUser?.uid;
  Timer? _timer;
  bool _listo = false;
  bool _cerrando = false;
  String? _uid;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_tecla);
    _suscripcion =
        (widget.sesiones ??
                FirebaseAuth.instance.authStateChanges().map(
                  (usuario) => usuario?.uid,
                ))
            .listen(_cambio);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _comprobar());
  }

  Future<void> _cambio(String? usuario) async {
    final revision = ++_revision;
    if (mounted) setState(() => _listo = false);
    try {
      await _sesion.cargar();
      await _sesion.accesoEnCurso;
      if (!mounted || revision != _revision) return;
      // El usuario pudo cambiar mientras finalizaba el ingreso.
      _uid = _usuarioActual;
      if (_uid == null) {
        await _sesion.limpiar();
      } else if (_sesion.vencida(_uid!)) {
        await _cerrar();
        return;
      }
      if (mounted && revision == _revision) setState(() => _listo = true);
    } catch (_) {
      if (mounted) await _cerrar();
    }
  }

  void _comprobar() {
    if (!_listo || _uid == null || _cerrando) return;
    if (_sesion.vencida(_uid!) && !_sesion.operacionEnCurso) {
      unawaited(_cerrar());
    }
  }

  Future<void> _cerrar() async {
    if (_cerrando) return;
    _cerrando = true;
    if (mounted) setState(() => _listo = false);
    try {
      await (widget.cerrarSesion?.call() ?? FirebaseAuth.instance.signOut());
      if (!mounted) return;
      widget.navigatorKey.currentState?.popUntil((ruta) => ruta.isFirst);
    } catch (_) {
      // Mantener bloqueada la vista y reintentar sin exponer una sesion vencida.
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) unawaited(_cerrar());
      });
    } finally {
      _cerrando = false;
    }
  }

  void _actividad() {
    _comprobar();
    if (_listo && !_cerrando && _uid != null) _sesion.actividad(_uid!);
  }

  bool _tecla(KeyEvent evento) {
    if (evento is KeyDownEvent) _actividad();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _comprobar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_tecla);
    _suscripcion?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _actividad(),
    onPointerMove: (_) => _actividad(),
    onPointerHover: (_) => _actividad(),
    onPointerSignal: (_) => _actividad(),
    child: Stack(
      children: [
        Offstage(offstage: !_listo, child: widget.child),
        if (!_listo)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );
}
