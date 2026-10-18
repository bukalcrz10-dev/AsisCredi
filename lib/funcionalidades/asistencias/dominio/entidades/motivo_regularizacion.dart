String validarMotivoRegularizacion(String motivo) {
  final texto = motivo.trim();
  if (texto.isEmpty || texto.length > 500) {
    throw const FormatException(
      'Escribe el motivo de la corrección (máximo 500 caracteres).',
    );
  }
  return texto;
}
