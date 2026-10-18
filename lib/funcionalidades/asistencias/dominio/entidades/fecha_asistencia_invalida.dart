/// Impide evaluar una jornada inventando la fecha de un documento dañado.
class FechaAsistenciaInvalida implements Exception {
  const FechaAsistenciaInvalida(this.documentoId);

  final String documentoId;
  static const mensaje =
      'Hay una marcación sin fecha válida. El administrador debe revisar el registro antes de consultar o exportar el historial.';

  @override
  String toString() => '$mensaje Registro: $documentoId.';
}
