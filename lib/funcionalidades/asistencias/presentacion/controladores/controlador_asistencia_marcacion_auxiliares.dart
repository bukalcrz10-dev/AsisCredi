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

  if (perfil.radioPermitidoMetros <= 0) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'La sede asignada no tiene un radio permitido configurado. El administrador debe completar ese dato antes de registrar asistencia.',
    );
  }

  if (perfil.latitudSede == 0 && perfil.longitudSede == 0) {
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
}) {
  final instanteActual = ahora ?? DateTime.now();
  final fechaBase = marcacionesHoy.isNotEmpty
      ? marcacionesHoy.first.fechaHora
      : instanteActual;
  final resumen = construirResumenJornadaTrabajador(marcacionesHoy, fechaBase);
  final totalEntradas = marcacionesHoy
      .where((marcacion) => marcacion.tipoMarcacion == TipoMarcacion.entrada)
      .length;
  final totalSalidas = marcacionesHoy
      .where((marcacion) => marcacion.tipoMarcacion == TipoMarcacion.salida)
      .length;

  if (tipoMarcacion == TipoMarcacion.entrada) {
    if (totalEntradas >= 2) {
      return const RechazoMarcacion(
        tipoAlerta: TipoAlerta.marcacionRechazada,
        mensaje:
            'Ya registraste las dos entradas correspondientes a la jornada de hoy.',
      );
    }

    if (resumen.manana.entradaMarcada == null) {
      final inicioPermitido = resumen.manana.entradaProgramada.subtract(
        const Duration(minutes: 30),
      );
      if (instanteActual.isBefore(inicioPermitido)) {
        return const RechazoMarcacion(
          tipoAlerta: TipoAlerta.marcacionRechazada,
          mensaje:
              'La entrada de la manana solo puede registrarse desde las 8:00 AM.',
        );
      }
      return null;
    }

    if (resumen.manana.salidaMarcada == null) {
      return const RechazoMarcacion(
        tipoAlerta: TipoAlerta.marcacionRechazada,
        mensaje:
            'Primero debes registrar la salida del turno de la mañana antes de marcar una nueva entrada.',
      );
    }

    if (resumen.tarde.entradaMarcada != null) {
      return const RechazoMarcacion(
        tipoAlerta: TipoAlerta.marcacionRechazada,
        mensaje:
            'Ya registraste tus dos entradas de hoy. No necesitas volver a marcar otra entrada.',
      );
    }

    final inicioPermitidoEntradaTarde = resumen.tarde.entradaProgramada
        .subtract(const Duration(minutes: 30));
    if (instanteActual.isBefore(inicioPermitidoEntradaTarde)) {
      return const RechazoMarcacion(
        tipoAlerta: TipoAlerta.marcacionRechazada,
        mensaje:
            'La entrada del turno de la tarde solo puede registrarse desde 30 minutos antes del horario oficial.',
      );
    }

    return null;
  }

  if (totalSalidas >= 2) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'Ya registraste las dos salidas correspondientes a la jornada de hoy.',
    );
  }

  if (resumen.manana.entradaMarcada == null) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'Primero necesitas registrar la entrada del turno de la mañana antes de marcar una salida.',
    );
  }

  if (resumen.manana.salidaMarcada == null) {
    if (resumen.tarde.entradaMarcada != null &&
        resumen.tarde.salidaMarcada == null) {
      final inicioPermitidoSalidaTarde = resumen.tarde.salidaProgramada
          .subtract(const Duration(minutes: 30));
      if (instanteActual.isBefore(inicioPermitidoSalidaTarde)) {
        return const RechazoMarcacion(
          tipoAlerta: TipoAlerta.marcacionRechazada,
          mensaje:
              'La salida de la tarde solo puede registrarse desde 30 minutos antes del horario oficial.',
        );
      }
      return null;
    }

    final inicioPermitidoSalidaManana = resumen.manana.salidaProgramada
        .subtract(const Duration(minutes: 10));
    if (instanteActual.isBefore(inicioPermitidoSalidaManana)) {
      return const RechazoMarcacion(
        tipoAlerta: TipoAlerta.marcacionRechazada,
        mensaje:
            'La salida de la manana solo puede registrarse desde 10 minutos antes del horario oficial.',
      );
    }
    return null;
  }

  if (resumen.tarde.entradaMarcada == null) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'Primero debes registrar la entrada del turno de la tarde antes de marcar la salida final.',
    );
  }

  if (resumen.tarde.salidaMarcada != null) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'Ya registraste tus dos salidas de hoy. No necesitas volver a marcar otra salida.',
    );
  }

  final inicioPermitidoSalidaTarde = resumen.tarde.salidaProgramada.subtract(
    const Duration(minutes: 30),
  );
  if (instanteActual.isBefore(inicioPermitidoSalidaTarde)) {
    return const RechazoMarcacion(
      tipoAlerta: TipoAlerta.marcacionRechazada,
      mensaje:
          'La salida de la tarde solo puede registrarse desde 30 minutos antes del horario oficial.',
    );
  }

  return null;
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
}) {
  return Asistencia(
    id: '',
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
  required bool evidenciaPendiente,
}) {
  final horaFormateada = formatearHoraControlAsistencia(fechaHora);
  if (evidenciaPendiente) {
    return 'Tu ${tipoMarcacion.name} se registro correctamente a las $horaFormateada. La evidencia facial quedo pendiente porque Storage aun no esta disponible.';
  }

  return 'Tu ${tipoMarcacion.name} se registro correctamente a las $horaFormateada.';
}
