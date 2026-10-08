import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../asistencias/dominio/entidades/tipo_marcacion.dart';
import '../../../asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';

/// Una edición usa el horario guardado, nunca el cargo actual del trabajador.
class RegularizacionJornada {
  RegularizacionJornada(this.originales) {
    if (originales.isEmpty) {
      throw const FormatException('No hay una jornada que editar.');
    }
    final horarios = originales
        .map((a) => a.tipoHorario)
        .whereType<String>()
        .toSet();
    if (horarios.length > 1 ||
        horarios.any((h) => horarioDesdeTexto(h) == null)) {
      throw const FormatException(
        'La jornada tiene horarios incompatibles. Requiere revisión de sus registros.',
      );
    }
    resumen = construirResumenJornadaTrabajador(
      originales,
      originales.first.fechaHora,
    );
    if (resumen.totalMarcacionesRegistradas != originales.length) {
      throw const FormatException(
        'Hay marcaciones duplicadas o ambiguas. Revisa los registros antes de regularizar.',
      );
    }
  }
  final List<Asistencia> originales;
  late final ResumenJornadaTrabajador resumen;
  bool get horarioConfirmado => originales.any((a) => a.tipoHorario != null);
  List<VentanaMarcacion> get campos => resumen.ventanas;
  String clave(VentanaMarcacion campo) =>
      '${campo.bloque.name}_${campo.tipo.name}';
  Asistencia? existente(VentanaMarcacion campo) {
    final tramo = resumen.tramoPara(campo.bloque);
    return campo.tipo == TipoMarcacion.entrada
        ? tramo.entradaMarcada
        : tramo.salidaMarcada;
  }

  String texto(VentanaMarcacion campo) {
    final fecha = existente(campo)?.fechaHora;
    return fecha == null
        ? ''
        : '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  List<Asistencia> preparar(Map<String, String> horas) {
    final nuevas = <Asistencia>[];
    final resultado = <Asistencia>[];
    final fecha = originales.first.fechaHora;
    for (final campo in campos) {
      final anterior = existente(campo);
      final texto = (horas[clave(campo)] ?? '').trim();
      if (texto.isEmpty) {
        if (anterior != null) {
          throw const FormatException(
            'No borres una hora existente. Esta operación solo corrige o completa marcas.',
          );
        }
        continue;
      }
      final partes = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(texto);
      if (partes == null ||
          int.parse(partes[1]!) > 23 ||
          int.parse(partes[2]!) > 59) {
        throw const FormatException(
          'Usa horas válidas en formato 24 horas: HH:mm.',
        );
      }
      final hora = int.parse(partes[1]!);
      final minuto = int.parse(partes[2]!);
      if (anterior != null &&
          anterior.fechaHora.hour == hora &&
          anterior.fechaHora.minute == minuto) {
        resultado.add(
          anterior,
        ); // Conserva también los segundos si no se editó.
        continue;
      }
      if (anterior == null && !horarioConfirmado) {
        throw const FormatException(
          'No se pueden agregar marcas a una jornada sin horario identificado. Revisa primero su horario histórico.',
        );
      }
      final base = anterior ?? originales.first;
      const nota = 'Regularizado manualmente desde el panel administrativo.';
      final observacion = anterior?.observacion?.trim() ?? '';
      final nueva = Asistencia(
        id: anterior?.id ?? '',
        usuarioId: base.usuarioId,
        nombreUsuario: base.nombreUsuario,
        sedeId: base.sedeId,
        tipoMarcacion: campo.tipo,
        tipoHorario: anterior != null
            ? anterior.tipoHorario
            : resumen.tipoHorario.name,
        bloqueJornada: anterior != null
            ? anterior.bloqueJornada
            : campo.bloque.name,
        fechaHora: DateTime(fecha.year, fecha.month, fecha.day, hora, minuto),
        latitud: anterior?.latitud ?? 0,
        longitud: anterior?.longitud ?? 0,
        dentroDeZona: anterior?.dentroDeZona ?? false,
        rostroValidado: anterior?.rostroValidado ?? false,
        observacion: observacion.contains(nota)
            ? observacion
            : (observacion.isEmpty ? nota : '$observacion | $nota'),
        correoNotificacion: base.correoNotificacion,
        urlEvidenciaFacial: anterior?.urlEvidenciaFacial,
        notificacionEnviada: anterior?.notificacionEnviada ?? false,
      );
      resultado.add(nueva);
      nuevas.add(nueva);
    }
    for (final campo in campos.where((c) => c.tipo == TipoMarcacion.salida)) {
      final salida = resultado.where(
        (a) =>
            a.tipoMarcacion == TipoMarcacion.salida &&
            (a.bloqueJornada == campo.bloque.name ||
                a.id == existente(campo)?.id),
      );
      final entradaCampo = campos.firstWhere(
        (c) => c.tipo == TipoMarcacion.entrada && c.bloque == campo.bloque,
      );
      final entrada = resultado.where(
        (a) =>
            a.tipoMarcacion == TipoMarcacion.entrada &&
            (a.bloqueJornada == campo.bloque.name ||
                a.id == existente(entradaCampo)?.id),
      );
      if (salida.isNotEmpty && entrada.isEmpty) {
        throw const FormatException(
          'Completa la entrada antes de guardar la salida de ese bloque.',
        );
      }
    }
    DateTime? previa;
    for (final marca in resultado) {
      if (previa != null && marca.fechaHora.isBefore(previa)) {
        throw const FormatException(
          'Las horas deben seguir el orden de la jornada: entrada, receso, regreso y salida.',
        );
      }
      previa = marca.fechaHora;
    }
    // Las marcas antiguas sin metadatos no deben cambiar de bloque al inferirlo.
    for (final nueva in nuevas.where(
      (a) => a.id.isNotEmpty && a.bloqueJornada == null,
    )) {
      final antes = campos.firstWhere((c) => existente(c)?.id == nueva.id);
      final recalculado = construirResumenJornadaTrabajador(resultado, fecha);
      final tramo = recalculado.tramoPara(antes.bloque);
      final despues = nueva.tipoMarcacion == TipoMarcacion.entrada
          ? tramo.entradaMarcada
          : tramo.salidaMarcada;
      if (despues?.id != nueva.id) {
        throw const FormatException(
          'La corrección cambiaría el bloque de una marca histórica. Requiere revisión previa.',
        );
      }
    }
    return nuevas;
  }
}
