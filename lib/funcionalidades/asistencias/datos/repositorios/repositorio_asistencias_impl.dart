import '../../dominio/entidades/asistencia.dart';
import '../../dominio/repositorios/repositorio_asistencias.dart';
import '../fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../modelos/modelo_asistencia.dart';

// Implementacion concreta del contrato de asistencias.
// Su trabajo es traducir entre el negocio y la persistencia,
// dejando la UI aislada de los detalles de Firestore.
class RepositorioAsistenciasImpl implements RepositorioAsistencias {
  RepositorioAsistenciasImpl(this._fuenteDatos);

  final FuenteDatosAsistenciasFirestore _fuenteDatos;

  @override
  Future<String> registrarAsistencia(Asistencia asistencia) async {
    final idFinal =
        asistencia.id.isNotEmpty ? asistencia.id : _fuenteDatos.crearId();

    final asistenciaConId = Asistencia(
      id: idFinal,
      usuarioId: asistencia.usuarioId,
      nombreUsuario: asistencia.nombreUsuario,
      sedeId: asistencia.sedeId,
      tipoMarcacion: asistencia.tipoMarcacion,
      fechaHora: asistencia.fechaHora,
      latitud: asistencia.latitud,
      longitud: asistencia.longitud,
      dentroDeZona: asistencia.dentroDeZona,
      rostroValidado: asistencia.rostroValidado,
      observacion: asistencia.observacion,
      correoNotificacion: asistencia.correoNotificacion,
      notificacionEnviada: asistencia.notificacionEnviada,
    );

    final modelo = ModeloAsistencia.desdeEntidad(asistenciaConId);

    await _fuenteDatos.guardarAsistencia(
      id: idFinal,
      datos: modelo.aMapa(),
    );

    return idFinal;
  }
}
