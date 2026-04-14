import '../entidades/alerta.dart';
import '../repositorios/repositorio_alertas.dart';

// Caso de uso para consultar las incidencias recientes del trabajador.
// Esto permite que la app explique con contexto por que una marcacion
// fue rechazada o quedo observada.
class ObtenerAlertasPorUsuario {
  const ObtenerAlertasPorUsuario(this._repositorioAlertas);

  final RepositorioAlertas _repositorioAlertas;

  Future<List<Alerta>> ejecutar(String usuarioId) {
    return _repositorioAlertas.obtenerAlertasPorUsuario(usuarioId);
  }
}
