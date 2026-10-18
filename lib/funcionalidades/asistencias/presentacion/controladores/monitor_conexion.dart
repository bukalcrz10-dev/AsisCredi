import 'dart:async';
import 'package:flutter/foundation.dart';

enum EstadoConexion { verificando, enLinea, sinConexion }

/// Indica conectividad con el servidor, nunca inferida desde datos en caché.
class MonitorConexion extends ChangeNotifier {
  MonitorConexion({
    required Future<bool> Function() comprobar,
    this.intervalo = const Duration(minutes: 1),
    this.limite = const Duration(seconds: 5),
  }) : _comprobar = comprobar;

  final Future<bool> Function() _comprobar;
  final Duration intervalo;
  final Duration limite;
  EstadoConexion estado = EstadoConexion.verificando;
  Timer? _timer;
  int _generacion = 0;
  bool _cerrado = false;

  void iniciar() {
    if (_cerrado) return;
    pausar();
    final generacion = _generacion;
    _consultar(generacion);
  }

  void pausar() {
    _generacion++;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _consultar(int generacion) async {
    if (_cerrado || generacion != _generacion) return;
    estado = EstadoConexion.verificando;
    notifyListeners();
    var disponible = false;
    try {
      disponible = await _comprobar().timeout(limite);
    } catch (_) {
      // Ni un timeout ni un error de lectura confirman acceso al servidor.
    }
    if (_cerrado || generacion != _generacion) return;
    estado = disponible ? EstadoConexion.enLinea : EstadoConexion.sinConexion;
    notifyListeners();
    _timer = Timer(intervalo, () => _consultar(generacion));
  }

  @override
  void dispose() {
    _cerrado = true;
    pausar();
    super.dispose();
  }
}
