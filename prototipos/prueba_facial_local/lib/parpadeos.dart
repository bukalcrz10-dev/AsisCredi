/// Dos ciclos completos abierto-cerrado-abierto; no certifica prueba de vida.
class PruebaParpadeos {
  int cantidad = 0;
  int? _id, _ultimo, _cierre;
  int _abiertos = 0;
  bool _listo = false;
  String? error;
  String instruccion = 'Buscando tu rostro. Mira de frente con buena luz.';
  String lectura = 'Esperando imagen de la cámara';
  bool get esperandoCaptura =>
      cantidad == 1 && _cierre != null && _abiertos >= 1;
  bool get completada => cantidad == 2 && error == null;
  void fallar(String mensaje) => error ??= mensaje;
  void comprobarTiempo(int ms) {
    if (!completada && ms > 20000) {
      fallar('Se agotó el tiempo. Intenta nuevamente.');
    }
    if (_ultimo != null && ms - _ultimo! > 1800) {
      fallar('Se interrumpió la imagen. Intenta nuevamente.');
    }
  }

  void recibir(Map<String, dynamic> datos, int ms) {
    if (error != null || completada) return;
    comprobarTiempo(ms);
    if (error != null) return;
    if (_ultimo != null && ms <= _ultimo!) {
      fallar('Imagen fuera de secuencia.');
      return;
    }
    _ultimo = ms;
    final id = datos['id'] as int?;
    lectura = 'Rostros detectados: ${datos['caras']}';
    if (datos['caras'] != 1 || id == null) {
      instruccion = datos['caras'] == 1
          ? 'Preparando el seguimiento. Mantén el rostro de frente.'
          : 'Coloca una sola cara dentro del encuadre.';
      if (_id != null) fallar('Mantén una sola cara dentro del encuadre.');
      return;
    }
    if (_id != null && id != _id) {
      fallar('Cambió la cara seguida. Intenta nuevamente.');
      return;
    }
    _id = id;
    final izquierda = (datos['izquierda'] as num?)?.toDouble();
    final derecha = (datos['derecha'] as num?)?.toDouble();
    final giro = (datos['giro'] as num?)?.toDouble();
    final inclinacion = (datos['inclinacion'] as num?)?.toDouble();
    final ancho = (datos['anchoCara'] as num?)?.toDouble();
    lectura =
        'Ojo izquierdo: ${izquierda?.toStringAsFixed(2) ?? "--"} · '
        'Derecho: ${derecha?.toStringAsFixed(2) ?? "--"}';
    if (izquierda == null ||
        derecha == null ||
        !izquierda.isFinite ||
        !derecha.isFinite ||
        giro == null ||
        !giro.isFinite ||
        giro.abs() > 15 ||
        inclinacion == null ||
        !inclinacion.isFinite ||
        inclinacion.abs() > 15 ||
        ancho == null ||
        !ancho.isFinite ||
        ancho < .16) {
      _reiniciarCiclo();
      instruccion = ancho != null && ancho < .16
          ? 'Acércate un poco a la cámara.'
          : 'No puedo leer ambos ojos. Mira de frente y mejora la luz.';
      return;
    }
    final abiertos = izquierda > .65 && derecha > .65;
    final cerrados = izquierda < .25 && derecha < .25;
    if (_cierre != null && ms - _cierre! > 1500) {
      _reiniciarCiclo();
    }
    if (abiertos) {
      instruccion = _cierre != null
          ? 'Ojos abiertos. Confirmando el parpadeo…'
          : 'Ojos abiertos. Ahora cierra y abre los dos ojos despacio.';
      _abiertos++;
      if (_abiertos >= 2) {
        if (_cierre != null && ms - _cierre! >= 80) {
          cantidad++;
          _cierre = null;
          instruccion = completada
              ? 'Dos parpadeos completos. Capturando…'
              : 'Primer parpadeo listo. Cierra y abre los ojos una vez más.';
        }
        _listo = true;
      }
    } else {
      _abiertos = 0;
      if (cerrados && _listo && _cierre == null) {
        instruccion = 'Cierre detectado. Abre los ojos y mantenlos abiertos.';
        _cierre = ms;
        _listo = false;
      }
    }
  }

  void _reiniciarCiclo() {
    _abiertos = 0;
    _listo = false;
    _cierre = null;
  }
}
