import 'dart:async';

import 'package:flutter/material.dart';

import '../../../alertas/dominio/casos_de_uso/obtener_alertas_por_usuario.dart';
import '../../../alertas/dominio/casos_de_uso/registrar_alerta.dart';
import '../../../alertas/dominio/entidades/alerta.dart';
import '../../../alertas/dominio/entidades/tipo_alerta.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/subir_evidencia_facial.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import '../../../reconocimiento_facial/dominio/entidades/resultado_validacion_facial.dart';
import '../../dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import '../../dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import '../../dominio/casos_de_uso/registrar_asistencia.dart';
import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/perfil_trabajador_actual.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../../../geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import '../../../geolocalizacion/dominio/entidades/resultado_validacion_ubicacion.dart';
import 'controlador_asistencia_auxiliares.dart';
import 'controlador_asistencia_marcacion_auxiliares.dart';

// Controlador principal de la pantalla del trabajador.
// Carga el perfil real desde Firestore, mantiene el reloj
// y registra las marcaciones que el trabajador realiza.
class ControladorAsistencia extends ChangeNotifier {
  ControladorAsistencia({
    required ObtenerAlertasPorUsuario obtenerAlertasPorUsuario,
    required RegistrarAlerta registrarAlerta,
    required RegistrarAsistencia registrarAsistencia,
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
  PerfilTrabajadorActual? perfilActual;
  ResultadoValidacionUbicacion? resultadoUbicacion;
  ResultadoValidacionFacial? resultadoFacial;
  DateTime? fechaInicioHistorialSeleccionada;
  DateTime? fechaFinHistorialSeleccionada;
  DateTimeRange? rangoHistorialSeleccionado;
  FiltroHistorial filtroHistorial = FiltroHistorial.todo;

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
        return filtrarMarcacionesPorDia(_historialReciente, DateTime.now());
      case FiltroHistorial.rango:
        return filtrarMarcacionesPorRango(
          _historialReciente,
          rangoHistorialSeleccionado,
        );
      case FiltroHistorial.todo:
        return historialReciente;
    }
  }

  Asistencia? get ultimaEntrada {
    return obtenerUltimaMarcacionPorTipo(
      _historialReciente,
      TipoMarcacion.entrada,
    );
  }

  Asistencia? get ultimaSalida {
    return obtenerUltimaMarcacionPorTipo(
      _historialReciente,
      TipoMarcacion.salida,
    );
  }

  ResumenJornadaTrabajador get resumenJornadaHoy {
    return construirResumenJornadaTrabajador(
      _marcacionesDelDia(DateTime.now()),
      DateTime.now(),
    );
  }

  // Filtra las marcaciones del mismo dia para aplicar reglas
  // como una sola entrada y una sola salida por jornada.
  List<Asistencia> _marcacionesDelDia(DateTime fecha) {
    return filtrarMarcacionesPorDia(_historialReciente, fecha);
  }

  void actualizarRangoHistorial(DateTimeRange? rango) {
    _actualizarEstadoLocal(() {
      rangoHistorialSeleccionado = rango;
      filtroHistorial =
          rango == null ? FiltroHistorial.todo : FiltroHistorial.rango;
    });
  }

  void actualizarInicioHistorial(DateTime? fechaInicio) {
    _actualizarEstadoLocal(() {
      fechaInicioHistorialSeleccionada = fechaInicio;
    });
  }

  void actualizarFinHistorial(DateTime? fechaFin) {
    _actualizarEstadoLocal(() {
      fechaFinHistorialSeleccionada = fechaFin;
    });
  }

  void _iniciarReloj() {
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      _actualizarEstadoLocal(() {
        fechaHoraActual = DateTime.now();
      });
    });
  }

  void _actualizarEstadoLocal(VoidCallback accion) {
    accion();
    notifyListeners();
  }

  void _notificarCambio() {
    notifyListeners();
  }

  ResultadoValidacionUbicacion _crearResultadoUbicacionConError() {
    return const ResultadoValidacionUbicacion(
      servicioHabilitado: false,
      permisoConcedido: false,
      latitudActual: null,
      longitudActual: null,
      distanciaMetros: null,
      dentroDeZona: false,
      mensajeEstado:
          'No pudimos obtener tu ubicacion actual. Revisa permisos o el GPS del dispositivo.',
    );
  }

  ResultadoValidacionUbicacion _crearResultadoUbicacionConfiguracionInvalida(
    String mensaje,
  ) {
    return ResultadoValidacionUbicacion(
      servicioHabilitado: true,
      permisoConcedido: true,
      latitudActual: null,
      longitudActual: null,
      distanciaMetros: null,
      dentroDeZona: false,
      mensajeEstado: mensaje,
    );
  }

  ResultadoValidacionFacial _crearResultadoFacialConError() {
    return const ResultadoValidacionFacial(
      permisoCamaraConcedido: false,
      rostroDetectado: false,
      cantidadRostros: 0,
      rutaImagenCapturada: null,
      mensajeEstado:
          'No pudimos analizar la foto facial. Intenta tomarla nuevamente.',
    );
  }

  void _aplicarResultadoFacial(ResultadoValidacionFacial resultado) {
    resultadoFacial = resultado;
    mensajeEstado = resultado.mensajeEstado;
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

  PerfilTrabajadorActual _crearPerfilDesdeAutenticacion() {
    return PerfilTrabajadorActual.desdeAutenticacion(
      usuarioId: usuarioIdAutenticado,
      nombreCompleto: nombreAutenticado,
      correo: correoAutenticado,
    );
  }

  Future<void> _cargarDatosComplementariosDelPerfil() async {
    await Future.wait<void>([
      () async {
        try {
          await cargarHistorial();
        } catch (_) {
          mensajeEstado =
              'Tu perfil se cargo correctamente, pero el historial no pudo consultarse en este momento.';
        }
      }(),
      () async {
        try {
          await cargarAlertas();
        } catch (_) {
          // Las alertas visibles ayudan a la transparencia del sistema,
          // pero no deben impedir que el trabajador use la pantalla principal.
        }
      }(),
    ]);
  }

  void _asignarPerfilNoConfigurado() {
    perfilActual = _crearPerfilDesdeAutenticacion();
  }

  void _asignarPerfilConErrorDeCarga() {
    perfilActual = _crearPerfilDesdeAutenticacion();
  }

  // Carga el perfil real del trabajador desde Firestore usando el uid autenticado.
  // Si no existe el documento, deja un mensaje claro para que el administrador
  // complete la ficha del usuario dentro de la coleccion usuarios.
  Future<void> cargarPerfil() async {
    _actualizarEstadoLocal(() {
      cargandoPerfil = true;
    });

    if (usuarioIdAutenticado.trim().isEmpty) {
      _actualizarEstadoLocal(() {
        perfilActual = null;
        cargandoPerfil = false;
      });
      return;
    }

    try {
      final perfil = await _obtenerPerfilTrabajadorActual.ejecutar(
        usuarioId: usuarioIdAutenticado,
        nombreFallback: nombreAutenticado,
        correoFallback: correoAutenticado,
      );

      if (perfil == null) {
        _asignarPerfilNoConfigurado();
      } else {
        perfilActual = perfil;
      }

      if (perfilActual != null) {
        await _cargarDatosComplementariosDelPerfil();
      }
    } catch (_) {
      _asignarPerfilConErrorDeCarga();
    } finally {
      _actualizarEstadoLocal(() {
        cargandoPerfil = false;
      });
    }
  }

  // Consulta el historial real del trabajador desde Firestore.
  Future<void> cargarHistorial() async {
    final perfil = perfilActual;
    if (perfil == null) {
      return;
    }

    _actualizarEstadoLocal(() {
      cargandoHistorial = true;
    });

    try {
      final historial =
          await _obtenerAsistenciasPorUsuario.ejecutar(perfil.usuarioId);

      _historialReciente
        ..clear()
        ..addAll(historial);
    } finally {
      _actualizarEstadoLocal(() {
        cargandoHistorial = false;
      });
    }
  }

  // Consulta las incidencias recientes del trabajador desde Firestore.
  // Estas alertas explican por que una accion fue rechazada o quedo observada.
  Future<void> cargarAlertas() async {
    final perfil = perfilActual;
    if (perfil == null) {
      return;
    }

    _actualizarEstadoLocal(() {
      cargandoAlertas = true;
    });

    try {
      final alertas = await _obtenerAlertasPorUsuario.ejecutar(perfil.usuarioId);
      _alertasRecientes
        ..clear()
        ..addAll(alertas);
    } finally {
      _actualizarEstadoLocal(() {
        cargandoAlertas = false;
      });
    }
  }

  // Consulta la ubicacion actual del dispositivo y la compara con la sede real.
  Future<void> validarUbicacion() async {
    final perfil = perfilActual;
    if (perfil == null || perfil.sedeId.isEmpty || validandoUbicacion) {
      return;
    }

    _actualizarEstadoLocal(() {
      validandoUbicacion = true;
    });

    try {
      if (perfil.sede == null) {
        resultadoUbicacion = _crearResultadoUbicacionConfiguracionInvalida(
          'La sede asignada no existe en Firestore. El administrador debe revisarla antes de validar ubicacion.',
        );
        return;
      }

      if (perfil.radioPermitidoMetros <= 0) {
        resultadoUbicacion = _crearResultadoUbicacionConfiguracionInvalida(
          'La sede asignada no tiene radio permitido configurado. El administrador debe completar ese dato.',
        );
        return;
      }

      if (perfil.latitudSede == 0 && perfil.longitudSede == 0) {
        resultadoUbicacion = _crearResultadoUbicacionConfiguracionInvalida(
          'La sede asignada no tiene coordenadas validas configuradas. El administrador debe registrar latitud y longitud.',
        );
        return;
      }

      resultadoUbicacion = await _validarUbicacionActual.ejecutar(
        latitudSede: perfil.latitudSede,
        longitudSede: perfil.longitudSede,
        radioPermitidoMetros: perfil.radioPermitidoMetros,
      );
    } catch (_) {
      resultadoUbicacion = _crearResultadoUbicacionConError();
    } finally {
      _actualizarEstadoLocal(() {
        validandoUbicacion = false;
      });
    }
  }

  // Recibe la ruta de la foto tomada por la pantalla de camara
  // y delega a ML Kit la deteccion del rostro.
  Future<void> validarRostroConImagen(String rutaImagen) async {
    _actualizarEstadoLocal(() {
      validandoRostro = true;
    });

    try {
      final resultado = await _validarRostroCapturado.ejecutar(
        rutaImagen: rutaImagen,
      );
      _aplicarResultadoFacial(resultado);

      if (resultadoFacial?.rostroDetectado != true) {
        await _registrarAlertaSistema(
          tipo: TipoAlerta.rostroNoValido,
          mensaje: resultadoFacial?.mensajeEstado ??
              'No se detecto un rostro valido antes de marcar asistencia.',
        );
      }
    } catch (_) {
      _aplicarResultadoFacial(_crearResultadoFacialConError());
      await _registrarAlertaSistema(
        tipo: TipoAlerta.rostroNoValido,
        mensaje: resultadoFacial!.mensajeEstado,
      );
    } finally {
      _actualizarEstadoLocal(() {
        validandoRostro = false;
      });
    }
  }

  // Cada marcacion debe apoyarse en una captura reciente,
  // por eso limpiamos el estado facial cuando la asistencia ya fue aceptada.
  void limpiarValidacionFacial() {
    _actualizarEstadoLocal(() {
      resultadoFacial = null;
    });
  }

  void _actualizarMensajeEstado(String? mensaje) {
    _actualizarEstadoLocal(() {
      mensajeEstado = mensaje;
    });
  }

  Future<bool> _rechazarMarcacion({
    required TipoAlerta tipoAlerta,
    required String mensaje,
  }) async {
    mensajeEstado = mensaje;
    await _registrarAlertaSistema(
      tipo: tipoAlerta,
      mensaje: mensaje,
    );
    _notificarCambio();
    return false;
  }

  bool _validarContextoBasicoMarcacion(PerfilTrabajadorActual? perfil) {
    final rechazo = obtenerRechazoContextoBasicoMarcacion(
      perfil: perfil,
      validandoUbicacion: validandoUbicacion,
    );
    if (rechazo != null) {
      _actualizarMensajeEstado(rechazo.mensaje);
      return false;
    }

    return true;
  }

  Future<bool> _validarUbicacionParaMarcacion(TipoMarcacion tipoMarcacion) async {
    if (resultadoUbicacion == null) {
      await validarUbicacion();
    }

    final rechazo = obtenerRechazoUbicacionMarcacion(
      ubicacion: resultadoUbicacion,
      tipoMarcacion: tipoMarcacion,
    );
    if (rechazo != null) {
      return _rechazarMarcacion(
        tipoAlerta: rechazo.tipoAlerta,
        mensaje: rechazo.mensaje,
      );
    }

    return true;
  }

  Future<bool> _validarRostroParaMarcacion(TipoMarcacion tipoMarcacion) async {
    final rechazo = obtenerRechazoRostroMarcacion(
      resultadoFacial: resultadoFacial,
      rostroValidado: rostroValidado,
      tipoMarcacion: tipoMarcacion,
    );
    if (rechazo != null) {
      return _rechazarMarcacion(
        tipoAlerta: rechazo.tipoAlerta,
        mensaje: rechazo.mensaje,
      );
    }

    return true;
  }

  Future<bool> _validarReglasDiariasMarcacion(TipoMarcacion tipoMarcacion) async {
    final rechazo = obtenerRechazoReglaDiariaMarcacion(
      marcacionesHoy: _marcacionesDelDia(DateTime.now()),
      tipoMarcacion: tipoMarcacion,
    );
    if (rechazo != null) {
      return _rechazarMarcacion(
        tipoAlerta: rechazo.tipoAlerta,
        mensaje: rechazo.mensaje,
      );
    }

    return true;
  }

  Future<String?> _subirEvidenciaFacialOpcional({
    required PerfilTrabajadorActual perfil,
    required String rutaImagenFacial,
    required DateTime fechaHora,
    required TipoMarcacion tipoMarcacion,
  }) async {
    return _subirEvidenciaFacial
        .ejecutar(
          usuarioId: perfil.usuarioId,
          rutaImagenLocal: rutaImagenFacial,
          fechaHora: fechaHora,
          tipoMarcacion: tipoMarcacion,
        )
        .timeout(const Duration(seconds: 5));
  }

  Asistencia _crearAsistenciaPendiente({
    required PerfilTrabajadorActual perfil,
    required TipoMarcacion tipoMarcacion,
    required DateTime fechaHora,
    required String observacion,
    required String? urlEvidenciaFacial,
  }) {
    return crearAsistenciaTrabajador(
      perfil: perfil,
      tipoMarcacion: tipoMarcacion,
      fechaHora: fechaHora,
      ubicacion: resultadoUbicacion,
      dentroDeZona: dentroDeZona,
      rostroValidado: rostroValidado,
      observacion: observacion,
      urlEvidenciaFacial: urlEvidenciaFacial,
    );
  }

  void _insertarAsistenciaEnMemoria(Asistencia asistencia, String idGenerado) {
    _historialReciente.insert(0, clonarAsistenciaConId(asistencia, idGenerado));
  }

  String _mensajeRegistroExitoso({
    required TipoMarcacion tipoMarcacion,
    required DateTime fechaHora,
    required bool evidenciaPendiente,
  }) {
    return construirMensajeRegistroExitoso(
      tipoMarcacion: tipoMarcacion,
      fechaHora: fechaHora,
      evidenciaPendiente: evidenciaPendiente,
    );
  }

  Future<bool> registrarMarcacion(TipoMarcacion tipoMarcacion) async {
    final perfil = perfilActual;
    if (!_validarContextoBasicoMarcacion(perfil)) return false;
    final perfilSeguro = perfil!;

    if (!await _validarUbicacionParaMarcacion(tipoMarcacion)) return false;
    if (!await _validarRostroParaMarcacion(tipoMarcacion)) return false;
    if (!await _validarReglasDiariasMarcacion(tipoMarcacion)) return false;

    final rutaImagenFacial = resultadoFacial!.rutaImagenCapturada!;
    final ahora = DateTime.now();

    _actualizarEstadoLocal(() {
      guardando = true;
      mensajeEstado = null;
    });

    try {
      String? urlEvidenciaFacial;
      String observacion =
          'Marcacion generada desde la pantalla del trabajador.';

      // La evidencia facial se sube antes de registrar la asistencia
      // para que ambos queden enlazados desde el primer guardado.
      // Si Storage aun no esta disponible, no bloqueamos la asistencia
      // y dejamos una observacion explicita para retomarlo luego.
      try {
        urlEvidenciaFacial = await _subirEvidenciaFacialOpcional(
          perfil: perfilSeguro,
          rutaImagenFacial: rutaImagenFacial,
          fechaHora: ahora,
          tipoMarcacion: tipoMarcacion,
        );
      } catch (_) {
        observacion =
            'Marcacion generada desde la pantalla del trabajador. La evidencia facial no pudo subirse a Firebase Storage.';
      }

      final asistencia = _crearAsistenciaPendiente(
        perfil: perfilSeguro,
        tipoMarcacion: tipoMarcacion,
        fechaHora: ahora,
        observacion: observacion,
        urlEvidenciaFacial: urlEvidenciaFacial,
      );

      final idGenerado = await _registrarAsistencia.ejecutar(asistencia);

      _insertarAsistenciaEnMemoria(asistencia, idGenerado);
      mensajeEstado = _mensajeRegistroExitoso(
        tipoMarcacion: tipoMarcacion,
        fechaHora: asistencia.fechaHora,
        evidenciaPendiente: urlEvidenciaFacial == null,
      );
      limpiarValidacionFacial();
      _notificarCambio();

      // Refrescamos el historial real despues de guardar para que la pantalla
      // refleje exactamente los datos persistidos en Firestore.
      await Future.wait<void>([
        cargarHistorial(),
        cargarAlertas(),
      ]);
      return true;
    } catch (_) {
      mensajeEstado =
          'No pudimos registrar la asistencia en Firebase. Intenta nuevamente en unos segundos.';
      return false;
    } finally {
      _actualizarEstadoLocal(() {
        guardando = false;
      });
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}
