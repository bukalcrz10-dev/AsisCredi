import '../entidades/alerta.dart';
import '../repositorios/repositorio_alertas.dart';

// Caso de uso para persistir una alerta detectada por el sistema.
class RegistrarAlerta {
  const RegistrarAlerta(this._repositorioAlertas);

  final RepositorioAlertas _repositorioAlertas;

  Future<String> ejecutar(Alerta alerta) {
    return _repositorioAlertas.registrarAlerta(alerta);
  }
}
