import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/local/comparacion.dart';

void main() {
  List<double> eje(int posicion, [double escala = 1]) =>
      List.generate(128, (i) => i == posicion ? escala : 0);
  test('comparación normalizada: mismo vector y distinta magnitud', () {
    expect(comparar(eje(0), eje(0, 3)).similitud, closeTo(1, 1e-12));
    expect(comparar(eje(0), eje(0, 3)).coincide, isTrue);
  });
  test('vectores ortogonales u opuestos no coinciden', () {
    expect(comparar(eje(0), eje(1)).coincide, isFalse);
    expect(comparar(eje(0), eje(0, -1)).similitud, closeTo(-1, 1e-12));
  });
  test('datos incompletos o no finitos no producen coincidencia', () {
    for (final invalido in [
      <double>[],
      List.filled(128, 0.0),
      List.filled(128, double.nan),
      List.filled(128, double.infinity),
      [1.0],
    ]) {
      expect(() => comparar(eje(0), invalido), throwsFormatException);
    }
  });
}
