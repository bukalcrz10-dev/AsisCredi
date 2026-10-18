import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/local/formato_camara.dart';

void main() {
  PlanoYuv p(List<int> datos, int fila, int pixel) =>
      PlanoYuv(Uint8List.fromList(datos), fila, pixel);
  test('YUV planar se convierte a NV21 con V antes de U', () {
    expect(
      convertirYuv420(4, 2, [
        p([1, 2, 3, 4, 5, 6, 7, 8], 4, 1),
        p([10, 11], 2, 1),
        p([20, 21], 2, 1),
      ]),
      [1, 2, 3, 4, 5, 6, 7, 8, 20, 10, 21, 11],
    );
  });
  test('padding de filas y croma intercalado con último padding ausente', () {
    expect(
      convertirYuv420(4, 4, [
        p(
          [
            1,
            2,
            3,
            4,
            99,
            99,
            5,
            6,
            7,
            8,
            99,
            99,
            9,
            10,
            11,
            12,
            99,
            99,
            13,
            14,
            15,
            16,
          ],
          6,
          1,
        ),
        p([30, 99, 31, 99, 99, 99, 32, 99, 33], 6, 2),
        p([40, 99, 41, 99, 99, 99, 42, 99, 43], 6, 2),
      ]),
      [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        40,
        30,
        41,
        31,
        42,
        32,
        43,
        33,
      ],
    );
  });
  test('rechaza planos truncados, strides inválidos y dimensiones impares', () {
    expect(
      () => convertirYuv420(2, 2, [
        p([1], 2, 1),
        p([1], 1, 1),
        p([1], 1, 1),
      ]),
      throwsFormatException,
    );
    expect(
      () => convertirYuv420(2, 2, [
        p([1, 2, 3, 4], 1, 1),
        p([1], 1, 1),
        p([1], 1, 1),
      ]),
      throwsFormatException,
    );
    expect(() => convertirYuv420(3, 2, []), throwsFormatException);
  });
}
