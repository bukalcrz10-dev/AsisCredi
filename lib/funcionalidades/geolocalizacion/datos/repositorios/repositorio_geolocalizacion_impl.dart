import '../../dominio/entidades/resultado_validacion_ubicacion.dart';
import '../../dominio/repositorios/repositorio_geolocalizacion.dart';
import '../fuentes_datos/fuente_datos_geolocalizacion_dispositivo.dart';

// Implementacion del repositorio de geolocalizacion usando el GPS del dispositivo.
class RepositorioGeolocalizacionImpl implements RepositorioGeolocalizacion {
  RepositorioGeolocalizacionImpl(this._fuenteDatos);

  final FuenteDatosGeolocalizacionDispositivo _fuenteDatos;

  @override
  Future<ResultadoValidacionUbicacion> validarUbicacionActual({
    required double latitudSede,
    required double longitudSede,
    required double radioPermitidoMetros,
  }) {
    return _fuenteDatos.validarUbicacionActual(
      latitudSede: latitudSede,
      longitudSede: longitudSede,
      radioPermitidoMetros: radioPermitidoMetros,
    );
  }
}
