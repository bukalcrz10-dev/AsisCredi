import 'package:geolocator/geolocator.dart';

import '../../dominio/entidades/resultado_validacion_ubicacion.dart';

// Fuente de datos que habla con el GPS real del dispositivo.
// Se encarga de permisos, servicio de ubicacion y lectura de coordenadas.
class FuenteDatosGeolocalizacionDispositivo {
  Future<ResultadoValidacionUbicacion> validarUbicacionActual({
    required double latitudSede,
    required double longitudSede,
    required double radioPermitidoMetros,
  }) async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return const ResultadoValidacionUbicacion(
        servicioHabilitado: false,
        permisoConcedido: false,
        latitudActual: null,
        longitudActual: null,
        distanciaMetros: null,
        dentroDeZona: false,
        mensajeEstado: 'Activa el GPS del dispositivo para validar la asistencia.',
      );
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    final permisoConcedido = permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse;

    if (!permisoConcedido) {
      return const ResultadoValidacionUbicacion(
        servicioHabilitado: true,
        permisoConcedido: false,
        latitudActual: null,
        longitudActual: null,
        distanciaMetros: null,
        dentroDeZona: false,
        mensajeEstado:
            'La app no tiene permiso de ubicacion. Concedelo para marcar asistencia.',
      );
    }

    final posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final distanciaMetros = Geolocator.distanceBetween(
      posicion.latitude,
      posicion.longitude,
      latitudSede,
      longitudSede,
    );

    final dentroDeZona = distanciaMetros <= radioPermitidoMetros;

    return ResultadoValidacionUbicacion(
      servicioHabilitado: true,
      permisoConcedido: true,
      latitudActual: posicion.latitude,
      longitudActual: posicion.longitude,
      distanciaMetros: distanciaMetros,
      dentroDeZona: dentroDeZona,
      mensajeEstado: dentroDeZona
          ? 'Ubicacion valida dentro de la sede.'
          : 'Estas fuera del radio permitido de la sede.',
    );
  }
}
