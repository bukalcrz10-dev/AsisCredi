import '../entidades/asistencia.dart';
import '../repositorios/repositorio_asistencias.dart';

// Caso de uso que representa la accion principal del sistema:
// registrar una marcacion de asistencia.
// Se mantiene en dominio para concentrar la regla de negocio
// y no dejar que la interfaz hable directo con Firebase.
class RegistrarAsistencia {
  const RegistrarAsistencia(this._repositorioAsistencias);

  final RepositorioAsistencias _repositorioAsistencias;

  Future<String> ejecutar(Asistencia asistencia) {
    return _repositorioAsistencias.registrarAsistencia(asistencia);
  }
}
