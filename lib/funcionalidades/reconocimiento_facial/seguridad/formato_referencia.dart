import 'dart:typed_data';
import '../local/comparacion.dart';

// 128 doubles IEEE-754: tamaño fijo y sin pérdida de precisión.
Uint8List codificarReferencia(List<double> vector) {
  validarVector(vector);
  final datos = ByteData(128 * 8);
  for (var i = 0; i < 128; i++) {
    datos.setFloat64(i * 8, vector[i], Endian.little);
  }
  return datos.buffer.asUint8List();
}

List<double> decodificarReferencia(Uint8List bytes) {
  if (bytes.length != 128 * 8) {
    throw const FormatException('Referencia facial incompleta');
  }
  final datos = ByteData.sublistView(bytes);
  final vector = List.generate(
    128,
    (i) => datos.getFloat64(i * 8, Endian.little),
  );
  validarVector(vector);
  return vector;
}
