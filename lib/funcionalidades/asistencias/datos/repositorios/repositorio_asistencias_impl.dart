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
      urlEvidenciaFacial: asistencia.urlEvidenciaFacial,
      notificacionEnviada: asistencia.notificacionEnviada,
    );

    final modelo = ModeloAsistencia.desdeEntidad(asistenciaConId);

    await _fuenteDatos.guardarAsistencia(
      id: idFinal,
      datos: modelo.aMapa(),
    );

    return idFinal;
  }

  @override
  Future<List<Asistencia>> obtenerAsistenciasPorUsuario(String usuarioId) async {
    final documentos = await _fuenteDatos.obtenerAsistenciasPorUsuario(usuarioId);

    final asistencias = documentos
        .map((documento) => ModeloAsistencia.desdeMapa(
              documento.value,
              documento.key,
            ).aEntidad())
        .toList();

    // Ordenamos localmente para evitar depender de un indice compuesto
    // en Firestore durante esta etapa del proyecto.
    asistencias.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

    // Devolvemos todo el historial del trabajador para que la capa de
    // presentacion pueda aplicar filtros por dia o por rango sin perder datos.
    return asistencias;
  }

  @override
  Future<List<Asistencia>> obtenerAsistencias() async {
    final documentos = await _fuenteDatos.obtenerAsistencias();

    final asistencias = documentos
        .map((documento) => ModeloAsistencia.desdeMapa(
              documento.value,
              documento.key,
            ).aEntidad())
        .toList();

    asistencias.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return asistencias;
  }
}
