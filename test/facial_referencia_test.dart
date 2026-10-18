import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/seguridad/formato_referencia.dart';

void main() {
  test('referencia binaria conserva exactamente las 128 características', () {
    final original = List.generate(128, (i) => (i - 64) / 13.0);
    final bytes = codificarReferencia(original);
    expect(bytes.length, 1024);
    expect(decodificarReferencia(bytes.asUnmodifiableView()), original);
  });
  test('rechaza referencia truncada, vacía, no finita o de norma cero', () {
    for (final bytes in [Uint8List(0), Uint8List(1023), Uint8List(1024)]) {
      expect(() => decodificarReferencia(bytes), throwsFormatException);
    }
    final datos = ByteData(1024)..setFloat64(0, double.nan, Endian.little);
    expect(
      () => decodificarReferencia(datos.buffer.asUint8List()),
      throwsFormatException,
    );
    expect(
      () => codificarReferencia(List.filled(128, double.infinity)),
      throwsFormatException,
    );
  });
}
