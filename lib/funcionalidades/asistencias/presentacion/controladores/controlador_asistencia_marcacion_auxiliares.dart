import '../../../alertas/dominio/entidades/tipo_alerta.dart';
import '../../../geolocalizacion/dominio/entidades/resultado_validacion_ubicacion.dart';
import '../../../reconocimiento_facial/dominio/entidades/resultado_validacion_facial.dart';
import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/perfil_trabajador_actual.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import 'controlador_asistencia_auxiliares.dart';

class RechazoMarcacion {
  const RechazoMarcacion({required this.tipoAlerta, required this.mensaje});

  final TipoAlerta tipoAlerta;
  final String mensaje;
}

RechazoMarcacion? obtenerRechazoContextoBasicoMarcacion({
  required PerfilTrabajadorActual? perfil,
  required bool validandoUbicacion,
}) {
  if (perfil == null) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'Tu perfil aun no esta listo. Espera unos segundos y vuelve a intentarlo.',
    );
  }

  if (perfil.sedeId.isEmpty) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'Tu cuenta no tiene una sede institucional asignada. El administrador debe completar tu perfil antes de registrar asistencia.',
    );
  }

  if (perfil.sede == null) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'La sede asignada a tu cuenta no existe en la coleccion de sedes. El administrador debe revisarla antes de registrar asistencia.',
    );
  }

  if (!perfil.sede!.activa) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje: 'Tu sede está inactiva. Solicita revisión al administrador.',
    );
  }

  if (!perfil.radioPermitidoMetros.isFinite ||
      perfil.radioPermitidoMetros <= 0) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'La sede asignada no tiene un radio permitido configurado. El administrador debe completar ese dato antes de registrar asistencia.',
    );
  }

  if (!perfil.latitudSede.isFinite ||
      !perfil.longitudSede.isFinite ||
      perfil.latitudSede.abs() > 90 ||
      perfil.longitudSede.abs() > 180 ||
      (perfil.latitudSede == 0 && perfil.longitudSede == 0)) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'La sede asignada no tiene coordenadas validas configuradas. El administrador debe registrar latitud y longitud antes de marcar asistencia.',
    );
  }

  if (validandoUbicacion) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'Estamos terminando de validar tu ubicacion. Espera unos segundos antes de confirmar.',
    );
  }

  return null;
}

RechazoMarcacion? obtenerRechazoUbicacionMarcacion({
  required ResultadoValidacionUbicacion? ubicacion,
  required TipoMarcacion tipoMarcacion,
}) {
  if (ubicacion == null) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'No pudimos validar tu ubicacion antes de registrar la asistencia.',
    );
  }

  if (!ubicacion.dentroDeZona) {
    return RechazoMarcacion(
      tipoAlerta: TipoAlerta.fueraDeZona,
      mensaje:
          'No pudimos registrar tu ${tipoMarcacion.name} porque estas fuera del radio permitido de la sede.',
    );
  }

  return null;
}

RechazoMarcacion? obtenerRechazoRostroMarcacion({
  required ResultadoValidacionFacial? resultadoFacial,
  required bool rostroValidado,
  required TipoMarcacion tipoMarcacion,
}) {
  if (resultadoFacial == null) {
    return RechazoMarcacion(
      tipoAlerta: TipoAlerta.rostroNoValido,
      mensaje:
          'Antes de registrar tu ${tipoMarcacion.name}, primero valida tu rostro.',
    );
  }

  if (!rostroValidado) {
    return RechazoMarcacion(
      tipoAlerta: TipoAlerta.rostroNoValido,
      mensaje:
          'No pudimos registrar tu ${tipoMarcacion.name} porque la validacion facial no fue correcta.',
    );
  }

  final rutaImagenFacial = resultadoFacial.rutaImagenCapturada;
  if (rutaImagenFacial == null || rutaImagenFacial.isEmpty) {
    return RechazoMarcacion(
      tipoAlerta: TipoAlerta.rostroNoValido,
      mensaje:
          'La validacion facial quedo incompleta. Toma nuevamente la foto antes de marcar.',
    );
  }

  return null;
}

RechazoMarcacion? obtenerRechazoReglaDiariaMarcacion({
  required List<Asistencia> marcacionesHoy,
  required TipoMarcacion tipoMarcacion,
  DateTime? ahora,
  TipoHorarioPersonal? tipoHorario,
}) {
  final instante = ahora ?? DateTime.now();
  final resumen = construirResumenJornadaTrabajador(
    filtrarMarcacionesPorDia(marcacionesHoy, instante),
    instante,
    tipoHorario: tipoHorario,
  );
  final mensaje = resumen.rechazoMarcacionPara(tipoMarcacion, instante);
  return mensaje == null
      ? null
      : RechazoMarcacion(
          tipoAlerta: TipoAlerta.marcacionRechazada,
          mensaje: mensaje,
        );
}

Asistencia crearAsistenciaTrabajador({
  required PerfilTrabajadorActual perfil,
  required TipoMarcacion tipoMarcacion,
  required DateTime fechaHora,
  required ResultadoValidacionUbicacion? ubicacion,
  required bool dentroDeZona,
  required bool rostroValidado,
  required String observacion,
  required String? urlEvidenciaFacial,
  String? tipoHorario,
  String? bloqueJornada,
}) {
  return Asistencia(
    id: '',
    tipoHorario: tipoHorario,
    bloqueJornada: bloqueJornada,
    usuarioId: perfil.usuarioId,
    nombreUsuario: perfil.nombreCompleto,
    sedeId: perfil.sedeId,
    tipoMarcacion: tipoMarcacion,
    fechaHora: fechaHora,
    latitud: ubicacion?.latitudActual ?? perfil.latitudSede,
    longitud: ubicacion?.longitudActual ?? perfil.longitudSede,
    dentroDeZona: dentroDeZona,
    rostroValidado: rostroValidado,
    observacion: observacion,
    correoNotificacion: perfil.correoNotificacion,
    urlEvidenciaFacial: urlEvidenciaFacial,
  );
}

Asistencia clonarAsistenciaConId(Asistencia asistencia, String idGenerado) {
  return Asistencia(
    id: idGenerado,
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
}

String construirMensajeRegistroExitoso({
  required TipoMarcacion tipoMarcacion,
  required DateTime fechaHora,
}) {
  final horaFormateada = formatearHoraControlAsistencia(fechaHora);
  return 'Tu ${tipoMarcacion.name} se registro correctamente a las $horaFormateada.';
}
