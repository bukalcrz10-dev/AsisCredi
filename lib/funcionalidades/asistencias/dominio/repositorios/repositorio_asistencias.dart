import '../entidades/asistencia.dart';

// Contrato principal del modulo de asistencias.
// Vive en dominio porque define que operaciones necesita el negocio,
// sin imponer todavia si los datos vienen de Firebase, una API o memoria local.
abstract class RepositorioAsistencias {
  // Registra una asistencia y devuelve el id final del documento creado.
  // El id permite identificar la marcacion guardada en el historial.
  Future<String> registrarAsistencia(Asistencia asistencia);

  // Recupera el historial real del trabajador desde la base de datos.
  Future<List<Asistencia>> obtenerAsistenciasPorUsuario(String usuarioId);

  // Recupera las marcaciones recientes para consulta administrativa.
  Future<List<Asistencia>> obtenerAsistencias();

  // Elimina una marcacion puntual cuando se necesita regularizar o limpiar
  // duplicados administrativos del mismo bloque.
  Future<void> eliminarAsistencia(String id);
}
