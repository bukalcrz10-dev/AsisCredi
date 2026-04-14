import '../entidades/alerta.dart';

// Contrato del modulo de alertas.
// Permite guardar incidencias del sistema sin acoplar el dominio a Firestore.
abstract class RepositorioAlertas {
  Future<String> registrarAlerta(Alerta alerta);

  // Devuelve las alertas recientes del trabajador para mostrarlas
  // dentro de su propia pantalla de asistencia.
  Future<List<Alerta>> obtenerAlertasPorUsuario(String usuarioId);
}
