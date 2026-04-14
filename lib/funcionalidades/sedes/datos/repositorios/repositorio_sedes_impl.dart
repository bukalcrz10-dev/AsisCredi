import '../../dominio/entidades/sede.dart';
import '../../dominio/repositorios/repositorio_sedes.dart';
import '../fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../modelos/modelo_sede.dart';

// Implementacion del repositorio de sedes usando Firestore.
class RepositorioSedesImpl implements RepositorioSedes {
  RepositorioSedesImpl(this._fuenteDatos);

  final FuenteDatosSedesFirestore _fuenteDatos;

  @override
  Future<Sede?> obtenerSedePorId(String id) async {
    final mapa = await _fuenteDatos.obtenerSedePorId(id);
    if (mapa == null) {
      return null;
    }

    return ModeloSede.desdeMapa(mapa, id).aEntidad();
  }

  @override
  Future<void> guardarSede(Sede sede) {
    final modelo = ModeloSede.desdeEntidad(sede);
    return _fuenteDatos.guardarSede(
      id: sede.id,
      datos: modelo.aMapa(),
    );
  }
}
