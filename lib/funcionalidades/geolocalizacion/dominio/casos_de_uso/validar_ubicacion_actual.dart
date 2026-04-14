import '../entidades/resultado_validacion_ubicacion.dart';
import '../repositorios/repositorio_geolocalizacion.dart';

// Caso de uso que consulta el GPS y determina si el trabajador
// esta dentro del radio de su sede.
class ValidarUbicacionActual {
  const ValidarUbicacionActual(this._repositorioGeolocalizacion);

  final RepositorioGeolocalizacion _repositorioGeolocalizacion;

  Future<ResultadoValidacionUbicacion> ejecutar({
    required double latitudSede,
    required double longitudSede,
    required double radioPermitidoMetros,
  }) {
    return _repositorioGeolocalizacion.validarUbicacionActual(
      latitudSede: latitudSede,
      longitudSede: longitudSede,
      radioPermitidoMetros: radioPermitidoMetros,
    );
  }
}
