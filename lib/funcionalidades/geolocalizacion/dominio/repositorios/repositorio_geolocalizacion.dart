import '../entidades/resultado_validacion_ubicacion.dart';

// Contrato del modulo de geolocalizacion.
// Expone la operacion que el sistema necesita para validar
// si el trabajador se encuentra dentro de la sede autorizada.
abstract class RepositorioGeolocalizacion {
  Future<ResultadoValidacionUbicacion> validarUbicacionActual({
    required double latitudSede,
    required double longitudSede,
    required double radioPermitidoMetros,
  });
}
