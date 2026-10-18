import 'dart:typed_data';

class PlanoYuv {
  const PlanoYuv(this.bytes, this.fila, this.pixel);
  final Uint8List bytes;
  final int fila, pixel;
}

/// Convierte YUV_420_888 (Y, U, V) a NV21 (Y, VU), respetando padding.
Uint8List convertirYuv420(int ancho, int alto, List<PlanoYuv> planos) {
  if (ancho <= 0 ||
      alto <= 0 ||
      ancho.isOdd ||
      alto.isOdd ||
      planos.length != 3) {
    throw const FormatException(
      'Se necesitan tres planos YUV y dimensiones pares.',
    );
  }
  for (var i = 0; i < 3; i++) {
    final p = planos[i];
    final w = i == 0 ? ancho : ancho ~/ 2;
    final h = i == 0 ? alto : alto ~/ 2;
    if (p.pixel <= 0 ||
        p.fila < (w - 1) * p.pixel + 1 ||
        p.bytes.length <= (h - 1) * p.fila + (w - 1) * p.pixel) {
      throw const FormatException('La cámara entregó un plano YUV incompleto.');
    }
  }
  final salida = Uint8List(ancho * alto * 3 ~/ 2);
  var destino = 0;
  final y = planos[0], u = planos[1], v = planos[2];
  for (var fila = 0; fila < alto; fila++) {
    for (var col = 0; col < ancho; col++) {
      salida[destino++] = y.bytes[fila * y.fila + col * y.pixel];
    }
  }
  for (var fila = 0; fila < alto ~/ 2; fila++) {
    for (var col = 0; col < ancho ~/ 2; col++) {
      salida[destino++] = v.bytes[fila * v.fila + col * v.pixel];
      salida[destino++] = u.bytes[fila * u.fila + col * u.pixel];
    }
  }
  return salida;
}
