import '../../dominio/entidades/sede.dart';

// Modelo de datos para guardar y recuperar sedes desde Firebase.
// Se separa de la entidad porque la forma de persistencia puede cambiar
// sin afectar a la regla de negocio ni a la interfaz.
class ModeloSede {
  const ModeloSede({
    required this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.radioPermitidoMetros,
    this.descripcion,
    this.activa = true,
  });

  final String id;
  final String nombre;
  final double latitud;
  final double longitud;
  final double radioPermitidoMetros;
  final String? descripcion;
  final bool activa;

  factory ModeloSede.desdeEntidad(Sede sede) {
    return ModeloSede(
      id: sede.id,
      nombre: sede.nombre,
      latitud: sede.latitud,
      longitud: sede.longitud,
      radioPermitidoMetros: sede.radioPermitidoMetros,
      descripcion: sede.descripcion,
      activa: sede.activa,
    );
  }

  factory ModeloSede.desdeMapa(Map<String, dynamic> mapa, String id) {
    return ModeloSede(
      id: id,
      nombre: mapa['nombre'] as String? ?? '',
      latitud: (mapa['latitud'] as num?)?.toDouble() ?? 0,
      longitud: (mapa['longitud'] as num?)?.toDouble() ?? 0,
      radioPermitidoMetros:
          (mapa['radioPermitidoMetros'] as num?)?.toDouble() ?? 0,
      descripcion: mapa['descripcion'] as String?,
      activa: mapa['activa'] as bool? ?? true,
    );
  }

  Sede aEntidad() {
    return Sede(
      id: id,
      nombre: nombre,
      latitud: latitud,
      longitud: longitud,
      radioPermitidoMetros: radioPermitidoMetros,
      descripcion: descripcion,
      activa: activa,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'radioPermitidoMetros': radioPermitidoMetros,
      'descripcion': descripcion,
      'activa': activa,
    };
  }
}
