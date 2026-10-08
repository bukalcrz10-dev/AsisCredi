import 'dart:convert';

import '../../dominio/entidades/asistencia.dart';
import '../../dominio/repositorios/repositorio_asistencias.dart';
import '../fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../modelos/modelo_asistencia.dart';

// Implementacion concreta del contrato de asistencias.
// Su trabajo es traducir entre el negocio y la persistencia,
// dejando la UI aislada de los detalles de Firestore.
class RepositorioAsistenciasImpl implements RepositorioAsistencias {
  RepositorioAsistenciasImpl(
    this._fuenteDatos, {
    this.marcacionUnicaPorBloque = false,
  });

  final bool marcacionUnicaPorBloque;

  final FuenteDatosAsistenciasFirestore _fuenteDatos;

  @override
  Future<String> registrarAsistencia(Asistencia asistencia) async {
    final idFinal = asistencia.id.isNotEmpty
        ? asistencia.id
        : marcacionUnicaPorBloque
        ? idMarcacionPorBloque(asistencia)
        : _fuenteDatos.crearId();

    final asistenciaConId = Asistencia(
      id: idFinal,
      tipoHorario: asistencia.tipoHorario,
      bloqueJornada: asistencia.bloqueJornada,
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

    await _fuenteDatos.guardarAsistencia(id: idFinal, datos: modelo.aMapa());

    return idFinal;
  }

  @override
  Future<List<Asistencia>> obtenerAsistenciasPorUsuario(
    String usuarioId,
  ) async {
    final documentos = await _fuenteDatos.obtenerAsistenciasPorUsuario(
      usuarioId,
    );

    final asistencias = documentos
        .map(
          (documento) => ModeloAsistencia.desdeMapa(
            documento.value,
            documento.key,
          ).aEntidad(),
        )
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
        .map(
          (documento) => ModeloAsistencia.desdeMapa(
            documento.value,
            documento.key,
          ).aEntidad(),
        )
        .toList();

    asistencias.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return asistencias;
  }

  Future<void> regularizarJornada({
    required List<Asistencia> originales,
    required List<Asistencia> actualizadas,
  }) async {
    if (actualizadas.isEmpty) return;
    final esperados = {
      for (final a in originales)
        a.id: ModeloAsistencia.desdeEntidad(a).aMapa(),
    };
    final cambios = <String, Map<String, dynamic>>{};
    for (final a in actualizadas) {
      final id = a.id.isEmpty ? idMarcacionPorBloque(a) : a.id;
      cambios[id] = a.id.isEmpty
          ? ModeloAsistencia.desdeEntidad(a).aMapa()
          : {
              'fechaHora': ModeloAsistencia.desdeEntidad(
                a,
              ).aMapa()['fechaHora'],
              'observacion': a.observacion,
            };
    }
    await _fuenteDatos.regularizarJornada(
      esperados: esperados,
      cambios: cambios,
    );
  }

  @override
  Future<void> eliminarAsistencia(String id) {
    return _fuenteDatos.eliminarAsistencia(id);
  }
}

// Los clientes actualizados escriben el mismo documento para el mismo evento.
// Las reglas existentes permiten crear al trabajador, pero no sobrescribir.
String idMarcacionPorBloque(Asistencia asistencia) {
  final fecha = asistencia.fechaHora;
  final dia =
      '${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}';
  final limite = asistencia.tipoMarcacion.name == 'entrada' ? 13 : 14;
  final bloque =
      asistencia.bloqueJornada ?? (fecha.hour < limite ? 'manana' : 'tarde');
  final usuario = base64Url.encode(utf8.encode(asistencia.usuarioId));
  return 'marcacion_${usuario}_${dia}_${bloque}_${asistencia.tipoMarcacion.name}';
}
