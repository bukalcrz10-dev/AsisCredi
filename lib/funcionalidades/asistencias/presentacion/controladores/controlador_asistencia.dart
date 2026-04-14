import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../alertas/dominio/casos_de_uso/obtener_alertas_por_usuario.dart';
import '../../../alertas/dominio/casos_de_uso/registrar_alerta.dart';
import '../../../alertas/dominio/entidades/alerta.dart';
import '../../../alertas/dominio/entidades/tipo_alerta.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/subir_evidencia_facial.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import '../../../reconocimiento_facial/dominio/entidades/resultado_validacion_facial.dart';
import '../../dominio/casos_de_uso/crear_perfil_trabajador_demo.dart';
import '../../dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import '../../dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import '../../dominio/casos_de_uso/registrar_asistencia.dart';
import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/perfil_trabajador_actual.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../../../geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import '../../../geolocalizacion/dominio/entidades/resultado_validacion_ubicacion.dart';

// Controlador principal de la pantalla del trabajador.
// Carga el perfil real desde Firestore, mantiene el reloj
// y registra las marcaciones que el trabajador realiza.
class ControladorAsistencia extends ChangeNotifier {
  ControladorAsistencia({
    required ObtenerAlertasPorUsuario obtenerAlertasPorUsuario,
    required RegistrarAlerta registrarAlerta,
    required RegistrarAsistencia registrarAsistencia,
    required CrearPerfilTrabajadorDemo crearPerfilTrabajadorDemo,
    required ObtenerAsistenciasPorUsuario obtenerAsistenciasPorUsuario,
    required ObtenerPerfilTrabajadorActual obtenerPerfilTrabajadorActual,
    required SubirEvidenciaFacial subirEvidenciaFacial,
    required ValidarRostroCapturado validarRostroCapturado,
    required ValidarUbicacionActual validarUbicacionActual,
    required this.usuarioIdAutenticado,
    this.nombreAutenticado,
    this.correoAutenticado,
  })  : _obtenerAlertasPorUsuario = obtenerAlertasPorUsuario,
        _registrarAlerta = registrarAlerta,
        _registrarAsistencia = registrarAsistencia,
        _crearPerfilTrabajadorDemo = crearPerfilTrabajadorDemo,
        _obtenerAsistenciasPorUsuario = obtenerAsistenciasPorUsuario,
        _obtenerPerfilTrabajadorActual = obtenerPerfilTrabajadorActual,
        _subirEvidenciaFacial = subirEvidenciaFacial,
        _validarRostroCapturado = validarRostroCapturado,
        _validarUbicacionActual = validarUbicacionActual {
    _iniciarReloj();
  }

  final ObtenerAlertasPorUsuario _obtenerAlertasPorUsuario;
  final RegistrarAlerta _registrarAlerta;
  final RegistrarAsistencia _registrarAsistencia;
  final CrearPerfilTrabajadorDemo _crearPerfilTrabajadorDemo;
  final ObtenerAsistenciasPorUsuario _obtenerAsistenciasPorUsuario;
  final ObtenerPerfilTrabajadorActual _obtenerPerfilTrabajadorActual;
  final SubirEvidenciaFacial _subirEvidenciaFacial;
  final ValidarRostroCapturado _validarRostroCapturado;
  final ValidarUbicacionActual _validarUbicacionActual;
  final String usuarioIdAutenticado;
  final String? nombreAutenticado;
  final String? correoAutenticado;
  final List<Asistencia> _historialReciente = [];
  final List<Alerta> _alertasRecientes = [];

  Timer? _temporizador;
  DateTime fechaHoraActual = DateTime.now();
  bool cargandoPerfil = false;
  bool cargandoHistorial = false;
  bool cargandoAlertas = false;
  bool validandoUbicacion = false;
  bool validandoRostro = false;
  bool guardando = false;
  String? mensajeEstado;
  String? mensajePerfil;
  String? ultimoIdRegistrado;
  PerfilTrabajadorActual? perfilActual;
  ResultadoValidacionUbicacion? resultadoUbicacion;
  ResultadoValidacionFacial? resultadoFacial;
  DateTimeRange? rangoHistorialSeleccionado;
  FiltroHistorial filtroHistorial = FiltroHistorial.hoy;

  bool get tienePerfilCargado => perfilActual != null;

  // La ubicacion ya se alimenta desde el GPS real. Si aun no hay consulta,
  // se considera fuera de zona hasta obtener un resultado valido.
  bool get dentroDeZona => resultadoUbicacion?.dentroDeZona ?? false;
  bool get rostroValidado => resultadoFacial?.rostroDetectado ?? false;

  List<Asistencia> get historialReciente =>
      List<Asistencia>.unmodifiable(_historialReciente);
  List<Alerta> get alertasRecientes =>
      List<Alerta>.unmodifiable(_alertasRecientes);

  // Historial visible para la UI segun el filtro seleccionado.
  // Mantenemos el historial completo en memoria para que cambiar
  // de dia o de rango no obligue a consultar Firestore otra vez.
  List<Asistencia> get historialFiltrado {
    switch (filtroHistorial) {
      case FiltroHistorial.hoy:
        return _filtrarPorDia(DateTime.now());
      case FiltroHistorial.rango:
        return _filtrarPorRango();
      case FiltroHistorial.todo:
        return historialReciente;
    }
  }

  String get descripcionFiltroHistorial {
    switch (filtroHistorial) {
      case FiltroHistorial.hoy:
        return 'Mostrando solo las marcaciones del dia actual.';
      case FiltroHistorial.rango:
        if (rangoHistorialSeleccionado == null) {
          return 'Selecciona un rango para consultar marcaciones especificas.';
        }

        return 'Mostrando desde ${_formatearFecha(rangoHistorialSeleccionado!.start)} hasta ${_formatearFecha(rangoHistorialSeleccionado!.end)}.';
      case FiltroHistorial.todo:
        return 'Mostrando todo el historial disponible del trabajador.';
    }
  }

  Asistencia? get ultimaMarcacion =>
      _historialReciente.isEmpty ? null : _historialReciente.first;

  Asistencia? get ultimaEntrada {
    for (final asistencia in _historialReciente) {
      if (asistencia.tipoMarcacion == TipoMarcacion.entrada) {
        return asistencia;
      }
    }
    return null;
  }

  Asistencia? get ultimaSalida {
    for (final asistencia in _historialReciente) {
      if (asistencia.tipoMarcacion == TipoMarcacion.salida) {
        return asistencia;
      }
    }
    return null;
  }

  // Filtra las marcaciones del mismo dia para aplicar reglas
  // como una sola entrada y una sola salida por jornada.
  List<Asistencia> _marcacionesDelDia(DateTime fecha) {
    return _historialReciente.where((asistencia) {
      final fechaAsistencia = asistencia.fechaHora;
      return fechaAsistencia.year == fecha.year &&
          fechaAsistencia.month == fecha.month &&
          fechaAsistencia.day == fecha.day;
    }).toList();
  }

  List<Asistencia> _filtrarPorDia(DateTime fecha) {
    return _marcacionesDelDia(fecha);
  }

  List<Asistencia> _filtrarPorRango() {
    final rango = rangoHistorialSeleccionado;
    if (rango == null) {
      return historialReciente;
    }

    final inicio = DateTime(rango.start.year, rango.start.month, rango.start.day);
    final fin = DateTime(
      rango.end.year,
      rango.end.month,
      rango.end.day,
      23,
      59,
      59,
      999,
    );

    return _historialReciente.where((asistencia) {
      final fecha = asistencia.fechaHora;
      return !fecha.isBefore(inicio) && !fecha.isAfter(fin);
    }).toList();
  }

  void cambiarFiltroHistorial(FiltroHistorial filtro) {
    filtroHistorial = filtro;
    notifyListeners();
  }

  void actualizarRangoHistorial(DateTimeRange? rango) {
    rangoHistorialSeleccionado = rango;
    if (rango != null) {
      filtroHistorial = FiltroHistorial.rango;
    }
    notifyListeners();
  }

  void _iniciarReloj() {
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      fechaHoraActual = DateTime.now();
      notifyListeners();
    });
  }

  // Registra una alerta en Firestore cuando el trabajador intenta
  // hacer una marcacion invalida o cuando ocurre un error relevante.
  Future<void> _registrarAlertaSistema({
    required TipoAlerta tipo,
    required String mensaje,
  }) async {
    final perfil = perfilActual;
    if (perfil == null) {
      return;
    }

    try {
      await _registrarAlerta.ejecutar(
        Alerta(
          id: '',
          usuarioId: perfil.usuarioId,
          nombreUsuario: perfil.nombreCompleto,
          tipo: tipo,
          mensaje: mensaje,
          fechaHora: DateTime.now(),
        ),
      );
      await cargarAlertas();
    } catch (_) {
      // Si la alerta no se puede guardar, no bloqueamos la experiencia principal.
    }
  }

  // Carga el perfil real del trabajador desde Firestore usando el uid autenticado.
  // Si no existe el documento, deja un mensaje claro para que el administrador
  // complete la ficha del usuario dentro de la coleccion usuarios.
  Future<void> cargarPerfil() async {
    cargandoPerfil = true;
    mensajePerfil = null;
    notifyListeners();

    try {
      final perfil = await _obtenerPerfilTrabajadorActual.ejecutar(
        usuarioId: usuarioIdAutenticado,
        nombreFallback: nombreAutenticado,
        correoFallback: correoAutenticado,
      );

      if (perfil == null) {
        // Si no existe perfil todavia, sembramos una sede y un usuario demo
        // para que puedas probar el flujo sin volver a Firebase Console.
        await _crearPerfilTrabajadorDemo.ejecutar(
          usuarioId: usuarioIdAutenticado,
          nombreCompleto:
              (nombreAutenticado != null && nombreAutenticado!.trim().isNotEmpty)
                  ? nombreAutenticado!.trim()
                  : 'Trabajador Demo',
          correo: correoAutenticado ?? '',
        );

        final perfilSembrado = await _obtenerPerfilTrabajadorActual.ejecutar(
          usuarioId: usuarioIdAutenticado,
          nombreFallback: nombreAutenticado,
          correoFallback: correoAutenticado,
        );

        perfilActual = perfilSembrado;
      mensajePerfil =
            'Se preparo un perfil de prueba para que puedas seguir usando la app mientras terminas la configuracion administrativa.';
      } else {
        perfilActual = perfil;
      }

      if (perfilActual != null) {
        try {
          await cargarHistorial();
        } catch (_) {
          mensajeEstado =
              'Tu perfil se cargo correctamente, pero el historial no pudo consultarse en este momento.';
        }
        try {
          await cargarAlertas();
        } catch (_) {
          // Las alertas visibles ayudan a la transparencia del sistema,
          // pero no deben impedir que el trabajador use la pantalla principal.
        }
        await validarUbicacion();
      }
    } catch (_) {
      perfilActual = PerfilTrabajadorActual.desdeAutenticacion(
        usuarioId: usuarioIdAutenticado,
        nombreCompleto: nombreAutenticado,
        correo: correoAutenticado,
      );
      mensajePerfil =
          'No pudimos cargar tu perfil completo desde Firestore. Revisa las colecciones usuarios y sedes.';
    } finally {
      cargandoPerfil = false;
      notifyListeners();
    }
  }

  // Consulta el historial real del trabajador desde Firestore.
  Future<void> cargarHistorial() async {
    final perfil = perfilActual;
    if (perfil == null) {
      return;
    }

    cargandoHistorial = true;
    notifyListeners();

    try {
      final historial =
          await _obtenerAsistenciasPorUsuario.ejecutar(perfil.usuarioId);

      _historialReciente
        ..clear()
        ..addAll(historial);
    } finally {
      cargandoHistorial = false;
      notifyListeners();
    }
  }

  // Consulta las incidencias recientes del trabajador desde Firestore.
  // Estas alertas explican por que una accion fue rechazada o quedo observada.
  Future<void> cargarAlertas() async {
    final perfil = perfilActual;
    if (perfil == null) {
      return;
    }

    cargandoAlertas = true;
    notifyListeners();

    try {
      final alertas = await _obtenerAlertasPorUsuario.ejecutar(perfil.usuarioId);
      _alertasRecientes
        ..clear()
        ..addAll(alertas);
    } finally {
      cargandoAlertas = false;
      notifyListeners();
    }
  }

  // Consulta la ubicacion actual del dispositivo y la compara con la sede real.
  Future<void> validarUbicacion() async {
    final perfil = perfilActual;
    if (perfil == null || perfil.sedeId.isEmpty) {
      return;
    }

    validandoUbicacion = true;
    notifyListeners();

    try {
      resultadoUbicacion = await _validarUbicacionActual.ejecutar(
        latitudSede: perfil.latitudSede,
        longitudSede: perfil.longitudSede,
        radioPermitidoMetros: perfil.radioPermitidoMetros,
      );
    } catch (_) {
      resultadoUbicacion = const ResultadoValidacionUbicacion(
        servicioHabilitado: false,
        permisoConcedido: false,
        latitudActual: null,
        longitudActual: null,
        distanciaMetros: null,
        dentroDeZona: false,
        mensajeEstado:
            'No pudimos obtener tu ubicacion actual. Revisa permisos o el GPS del dispositivo.',
      );
    } finally {
      validandoUbicacion = false;
      notifyListeners();
    }
  }

  // Recibe la ruta de la foto tomada por la pantalla de camara
  // y delega a ML Kit la deteccion del rostro.
  Future<void> validarRostroConImagen(String rutaImagen) async {
    validandoRostro = true;
    notifyListeners();

    try {
      resultadoFacial = await _validarRostroCapturado.ejecutar(
        rutaImagen: rutaImagen,
      );

        mensajeEstado = resultadoFacial?.mensajeEstado;

      if (resultadoFacial?.rostroDetectado != true) {
        await _registrarAlertaSistema(
          tipo: TipoAlerta.rostroNoValido,
          mensaje: resultadoFacial?.mensajeEstado ??
              'No se detecto un rostro valido antes de marcar asistencia.',
        );
      }
    } catch (_) {
      resultadoFacial = const ResultadoValidacionFacial(
        permisoCamaraConcedido: false,
        rostroDetectado: false,
        cantidadRostros: 0,
        rutaImagenCapturada: null,
        mensajeEstado:
            'No pudimos analizar la foto facial. Intenta tomarla nuevamente.',
      );
      mensajeEstado = resultadoFacial!.mensajeEstado;
      await _registrarAlertaSistema(
        tipo: TipoAlerta.rostroNoValido,
        mensaje: resultadoFacial!.mensajeEstado,
      );
    } finally {
      validandoRostro = false;
      notifyListeners();
    }
  }

  // Cada marcacion debe apoyarse en una captura reciente,
  // por eso limpiamos el estado facial cuando la asistencia ya fue aceptada.
  void limpiarValidacionFacial() {
    resultadoFacial = null;
    notifyListeners();
  }

  Future<void> registrarMarcacion(TipoMarcacion tipoMarcacion) async {
    final perfil = perfilActual;
    if (perfil == null) {
      mensajeEstado =
          'Tu perfil aun no esta listo. Espera unos segundos y vuelve a intentarlo.';
      notifyListeners();
      return;
    }

    if (resultadoUbicacion == null) {
      await validarUbicacion();
    }

    final ubicacion = resultadoUbicacion;
    if (ubicacion == null) {
      mensajeEstado =
          'No pudimos validar tu ubicacion antes de registrar la asistencia.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.marcacionRechazada,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    // La asistencia normal solo se permite si el trabajador
    // se encuentra dentro del radio autorizado de su sede.
    if (!ubicacion.dentroDeZona) {
      mensajeEstado =
          'No pudimos registrar tu ${tipoMarcacion.name} porque estas fuera del radio permitido de la sede.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.fueraDeZona,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    if (resultadoFacial == null) {
      mensajeEstado =
          'Antes de registrar tu ${tipoMarcacion.name}, primero valida tu rostro.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.rostroNoValido,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    if (!rostroValidado) {
      mensajeEstado =
          'No pudimos registrar tu ${tipoMarcacion.name} porque la validacion facial no fue correcta.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.rostroNoValido,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    final rutaImagenFacial = resultadoFacial?.rutaImagenCapturada;
    if (rutaImagenFacial == null || rutaImagenFacial.isEmpty) {
      mensajeEstado =
          'La validacion facial quedo incompleta. Toma nuevamente la foto antes de marcar.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.rostroNoValido,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    final ahora = DateTime.now();
    final marcacionesHoy = _marcacionesDelDia(ahora);
    final yaMarcoEntradaHoy = marcacionesHoy.any(
      (asistencia) => asistencia.tipoMarcacion == TipoMarcacion.entrada,
    );
    final yaMarcoSalidaHoy = marcacionesHoy.any(
      (asistencia) => asistencia.tipoMarcacion == TipoMarcacion.salida,
    );

    // Reglas de negocio diarias:
    // 1. Solo una entrada por dia.
    // 2. Solo una salida por dia.
    // 3. No se permite salida sin una entrada previa ese mismo dia.
    if (tipoMarcacion == TipoMarcacion.entrada && yaMarcoEntradaHoy) {
      mensajeEstado =
          'Ya registraste tu entrada de hoy. No necesitas volver a marcar otra entrada.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.marcacionRechazada,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    if (tipoMarcacion == TipoMarcacion.salida && !yaMarcoEntradaHoy) {
      mensajeEstado =
          'Primero necesitas registrar una entrada hoy antes de marcar tu salida.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.marcacionRechazada,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    if (tipoMarcacion == TipoMarcacion.salida && yaMarcoSalidaHoy) {
      mensajeEstado =
          'Ya registraste tu salida de hoy. No necesitas volver a marcar otra salida.';
      await _registrarAlertaSistema(
        tipo: TipoAlerta.marcacionRechazada,
        mensaje: mensajeEstado!,
      );
      notifyListeners();
      return;
    }

    guardando = true;
    mensajeEstado = null;
    notifyListeners();

    try {
      String? urlEvidenciaFacial;
      String observacion =
          'Marcacion generada desde la pantalla del trabajador.';

      // La evidencia facial se sube antes de registrar la asistencia
      // para que ambos queden enlazados desde el primer guardado.
      // Si Storage aun no esta disponible, no bloqueamos la asistencia
      // y dejamos una observacion explicita para retomarlo luego.
      try {
        urlEvidenciaFacial = await _subirEvidenciaFacial.ejecutar(
          usuarioId: perfil.usuarioId,
          rutaImagenLocal: rutaImagenFacial,
          fechaHora: ahora,
          tipoMarcacion: tipoMarcacion,
        );
      } catch (_) {
        observacion =
            'Marcacion generada desde la pantalla del trabajador. La evidencia facial no pudo subirse a Firebase Storage.';
      }

      final asistencia = Asistencia(
        id: '',
        usuarioId: perfil.usuarioId,
        nombreUsuario: perfil.nombreCompleto,
        sedeId: perfil.sedeId,
        tipoMarcacion: tipoMarcacion,
        fechaHora: ahora,
        latitud: ubicacion.latitudActual ?? perfil.latitudSede,
        longitud: ubicacion.longitudActual ?? perfil.longitudSede,
        dentroDeZona: dentroDeZona,
        rostroValidado: rostroValidado,
        observacion: observacion,
        correoNotificacion: perfil.correoNotificacion,
        urlEvidenciaFacial: urlEvidenciaFacial,
      );

      final idGenerado = await _registrarAsistencia.ejecutar(asistencia);

      ultimoIdRegistrado = idGenerado;
      mensajeEstado = urlEvidenciaFacial == null
          ? 'Tu ${tipoMarcacion.name} se registro correctamente a las ${_formatearHora(asistencia.fechaHora)}. La evidencia facial quedo pendiente porque Storage aun no esta disponible.'
          : 'Tu ${tipoMarcacion.name} se registro correctamente a las ${_formatearHora(asistencia.fechaHora)}.';

      // Refrescamos el historial real despues de guardar para que la pantalla
      // refleje exactamente los datos persistidos en Firestore.
      await cargarHistorial();
      await cargarAlertas();
      limpiarValidacionFacial();
    } catch (_) {
      mensajeEstado =
          'No pudimos registrar la asistencia en Firebase. Intenta nuevamente en unos segundos.';
    } finally {
      guardando = false;
      notifyListeners();
    }
  }

  String _formatearHora(DateTime fechaHora) {
    final hora = fechaHora.hour.toString().padLeft(2, '0');
    final minuto = fechaHora.minute.toString().padLeft(2, '0');
    final segundo = fechaHora.second.toString().padLeft(2, '0');
    return '$hora:$minuto:$segundo';
  }

  String _formatearFecha(DateTime fechaHora) {
    final dia = fechaHora.day.toString().padLeft(2, '0');
    final mes = fechaHora.month.toString().padLeft(2, '0');
    final anio = fechaHora.year.toString();
    return '$dia/$mes/$anio';
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}

// Modos de consulta del historial personal del trabajador.
// Permiten alternar entre el dia actual, un rango concreto o todo el historial.
enum FiltroHistorial {
  hoy,
  rango,
  todo,
}
