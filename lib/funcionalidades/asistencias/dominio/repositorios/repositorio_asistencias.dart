import '../entidades/asistencia.dart';

// Contrato principal del modulo de asistencias.
// Vive en dominio porque define que operaciones necesita el negocio,
// sin imponer todavia si los datos vienen de Firebase, una API o memoria local.
abstract class RepositorioAsistencias {
  // Registra una asistencia y devuelve el id final del documento creado.
  // El retorno del id permitira luego enlazar alertas, reportes o auditorias.
  Future<String> registrarAsistencia(Asistencia asistencia);
}
