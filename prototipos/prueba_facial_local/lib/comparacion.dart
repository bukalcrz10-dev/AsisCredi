import 'dart:math' as math;

// Ajuste exploratorio con las primeras capturas; requiere evaluación nueva.
// No es una calibración de producción ni una probabilidad de identidad.
const umbralPrueba = 0.52;

void validarVector(List<double> vector) {
  if (vector.length != 128 ||
      vector.any((v) => !v.isFinite) ||
      vector.fold<double>(0, (s, v) => s + v * v) <= 0) {
    throw const FormatException('Vector facial inválido');
  }
}

class ResultadoComparacion {
  const ResultadoComparacion(this.similitud);
  final double similitud;
  bool get coincide => similitud >= umbralPrueba;
}

ResultadoComparacion comparar(List<double> referencia, List<double> captura) {
  validarVector(referencia);
  validarVector(captura);
  var producto = 0.0;
  var normaA = 0.0;
  var normaB = 0.0;
  for (var i = 0; i < referencia.length; i++) {
    producto += referencia[i] * captura[i];
    normaA += referencia[i] * referencia[i];
    normaB += captura[i] * captura[i];
  }
  final score = producto / math.sqrt(normaA * normaB);
  if (!score.isFinite) throw const FormatException('Similitud inválida');
  return ResultadoComparacion(score.clamp(-1.0, 1.0));
}
