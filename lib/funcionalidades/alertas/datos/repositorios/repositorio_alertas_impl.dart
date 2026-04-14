import '../../dominio/entidades/alerta.dart';
import '../../dominio/repositorios/repositorio_alertas.dart';
import '../fuentes_datos/fuente_datos_alertas_firestore.dart';
import '../modelos/modelo_alerta.dart';

// Implementacion del repositorio de alertas usando Firestore.
class RepositorioAlertasImpl implements RepositorioAlertas {
  RepositorioAlertasImpl(this._fuenteDatos);

  final FuenteDatosAlertasFirestore _fuenteDatos;

  @override
  Future<String> registrarAlerta(Alerta alerta) async {
    final idFinal = alerta.id.isNotEmpty ? alerta.id : _fuenteDatos.crearId();

    final alertaConId = Alerta(
      id: idFinal,
      usuarioId: alerta.usuarioId,
      nombreUsuario: alerta.nombreUsuario,
      tipo: alerta.tipo,
      mensaje: alerta.mensaje,
      fechaHora: alerta.fechaHora,
      asistenciaId: alerta.asistenciaId,
      atendida: alerta.atendida,
    );

    final modelo = ModeloAlerta.desdeEntidad(alertaConId);

    await _fuenteDatos.guardarAlerta(
      id: idFinal,
      datos: modelo.aMapa(),
    );

    return idFinal;
  }

  @override
  Future<List<Alerta>> obtenerAlertasPorUsuario(String usuarioId) async {
    final documentos = await _fuenteDatos.obtenerAlertasPorUsuario(usuarioId);

    final alertas = documentos
        .map((documento) => ModeloAlerta.desdeMapa(
              documento.value,
              documento.key,
            ).aEntidad())
        .toList();

    alertas.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return alertas.take(10).toList();
  }
}
