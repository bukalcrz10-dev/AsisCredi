import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/datos/fuentes_datos/fuente_datos_geolocalizacion_dispositivo.dart';

class _GpsDispositivo extends GeolocatorPlatform {
  Duration edad = Duration.zero;
  LocationSettings? opciones;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    opciones = locationSettings;
    return Position(
      longitude: -75,
      latitude: -12,
      timestamp: DateTime.now().subtract(edad),
      accuracy: 2,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late GeolocatorPlatform original;
  late _GpsDispositivo gps;
  setUp(() {
    original = GeolocatorPlatform.instance;
    gps = _GpsDispositivo();
    GeolocatorPlatform.instance = gps;
  });
  tearDown(() => GeolocatorPlatform.instance = original);
  for (final edad in [
    const Duration(seconds: 45),
    const Duration(seconds: -10),
  ]) {
    test('rechaza timestamp GPS desactualizado o futuro: $edad', () async {
      gps.edad = edad;
      final resultado = await FuenteDatosGeolocalizacionDispositivo()
          .validarUbicacionActual(
            latitudSede: -12,
            longitudSede: -75,
            radioPermitidoMetros: 100,
          );
      expect(resultado.dentroDeZona, isFalse);
      expect(resultado.latitudActual, isNull);
      expect(resultado.mensajeEstado, contains('reciente'));
    });
  }
  test('posición reciente se evalúa con tiempo máximo de consulta', () async {
    final resultado = await FuenteDatosGeolocalizacionDispositivo()
        .validarUbicacionActual(
          latitudSede: -12,
          longitudSede: -75,
          radioPermitidoMetros: 100,
        );
    expect(resultado.dentroDeZona, isTrue);
    expect(gps.opciones!.timeLimit, const Duration(seconds: 20));
  });
}
