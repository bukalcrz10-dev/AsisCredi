import 'dart:async';
import '../../../reconocimiento_facial/seguridad/servicio_seguridad_biometrica.dart';

import 'package:flutter/material.dart';
import '../../../autenticacion/presentacion/controladores/sesion_trabajador.dart';

import '../../../reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import '../../../reconocimiento_facial/dominio/entidades/resultado_validacion_facial.dart';
import '../../dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import '../../dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import '../../dominio/casos_de_uso/registrar_asistencia.dart';
import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/fecha_asistencia_invalida.dart';
import '../../dominio/entidades/perfil_trabajador_actual.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../../../geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import '../../../geolocalizacion/dominio/entidades/resultado_validacion_ubicacion.dart';
import 'controlador_asistencia_auxiliares.dart';
import 'controlador_asistencia_marcacion_auxiliares.dart';
import 'monitor_conexion.dart';

// Controlador principal de la pantalla del trabajador.
// Carga el perfil real desde Firestore, mantiene el reloj
// y registra las marcaciones que el trabajador realiza.
class ControladorAsistencia extends ChangeNotifier {
  ControladorAsistencia({
    required RegistrarAsistencia registrarAsistencia,
    required ObtenerAsistenciasPorUsuario obtenerAsistenciasPorUsuario,
    required ObtenerPerfilTrabajadorActual obtenerPerfilTrabajadorActual,
    required ValidarRostroCapturado validarRostroCapturado,
    required ValidarUbicacionActual validarUbicacionActual,
    required this.usuarioIdAutenticado,
    this.nombreAutenticado,
    this.correoAutenticado,
    this.comprobarSeguridad,
    this.alLimpiarRostro,
    DateTime Function()? ahora,
    MonitorConexion? monitorConexion,
    this.esperaConfirmacion = const Duration(seconds: 20),
  }) : conexion =
           monitorConexion ?? MonitorConexion(comprobar: () async => false),
       _ahora = ahora ?? DateTime.now,
       _registrarAsistencia = registrarAsistencia,
       _obtenerAsistenciasPorUsuario = obtenerAsistenciasPorUsuario,
       _obtenerPerfilTrabajadorActual = obtenerPerfilTrabajadorActual,
       _validarRostroCapturado = validarRostroCapturado,
       _validarUbicacionActual = validarUbicacionActual {
    _iniciarReloj();
    conexion.addListener(_notificarCambio);
  }

  final RegistrarAsistencia _registrarAsistencia;
  final ObtenerAsistenciasPorUsuario _obtenerAsistenciasPorUsuario;
  final ObtenerPerfilTrabajadorActual _obtenerPerfilTrabajadorActual;
  final ValidarRostroCapturado _validarRostroCapturado;
  final ValidarUbicacionActual _validarUbicacionActual;
  final String usuarioIdAutenticado;
  final String? nombreAutenticado;
  final String? correoAutenticado;
  final Future<void> Function()? comprobarSeguridad;
  final VoidCallback? alLimpiarRostro;
  final DateTime Function() _ahora;
  final MonitorConexion conexion;
  final Duration esperaConfirmacion;
  Future<String>? _envioPendiente;
  bool get confirmacionPendiente => _envioPendiente != null;
  static const _mensajePendiente =
      'No pudimos confirmar tu marcación. Cuando tengas conexión, actualiza el historial para verificarla. No necesitas volver a enviarla mientras está pendiente.';
  final List<Asistencia> _historialReciente = [];

  Timer? _temporizador;
  DateTime fechaHoraActual = DateTime.now();
  bool cargandoPerfil = false;
  String? errorCargaPerfil;
  bool cargandoHistorial = false;
  String? errorFechaHistorial;
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

  // Historial visible para la UI segun el filtro seleccionado.
  // Mantenemos el historial completo en memoria para que cambiar
  // de dia o de rango no obligue a consultar Firestore otra vez.
  List<Asistencia> get historialFiltrado {
    switch (filtroHistorial) {
      case FiltroHistorial.hoy:
        return filtrarMarcacionesPorDia(_historialReciente, _ahora());
      case FiltroHistorial.rango:
        return filtrarMarcacionesPorRango(
          _historialReciente,
          rangoHistorialSeleccionado,
        );
      case FiltroHistorial.todo:
        return historialReciente;
    }
  }

  TipoHorarioPersonal? get horarioAsignado =>
      horarioDesdeCargo(perfilActual?.cargo ?? '');

  // La jornada iniciada conserva su horario aunque se retire el cargo.
  // Las marcas de otros días no habilitan una jornada nueva.
  bool get tieneHorarioParaHoy =>
      horarioAsignado != null ||
      _marcacionesDelDia(
        _ahora(),
      ).any((marca) => horarioDesdeTexto(marca.tipoHorario) != null);

  ResumenJornadaTrabajador get resumenJornadaHoy {
    return construirResumenJornadaTrabajador(
      _marcacionesDelDia(_ahora()),
      _ahora(),
      tipoHorario: horarioAsignado,
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
      filtroHistorial = rango == null
          ? FiltroHistorial.todo
          : FiltroHistorial.rango;
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
        fechaHoraActual = _ahora();
      });
    });
  }

  void _actualizarEstadoLocal(VoidCallback accion) {
    if (_cerrado) return;
    accion();
    notifyListeners();
  }

  void _notificarCambio() {
    if (_cerrado) return;
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

  PerfilTrabajadorActual _crearPerfilDesdeAutenticacion() {
    return PerfilTrabajadorActual.desdeAutenticacion(
      usuarioId: usuarioIdAutenticado,
      nombreCompleto: nombreAutenticado,
      correo: correoAutenticado,
    );
  }

  Future<void> _cargarDatosComplementariosDelPerfil() async {
    try {
      await cargarHistorial();
    } on FechaAsistenciaInvalida {
      mensajeEstado = FechaAsistenciaInvalida.mensaje;
    } catch (_) {
      mensajeEstado =
          'Tu perfil se cargo correctamente, pero el historial no pudo consultarse en este momento.';
    }
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
    if (_cerrado || cargandoPerfil || guardando) return;
    _actualizarEstadoLocal(() {
      cargandoPerfil = true;
      errorCargaPerfil = null;
    });

    if (usuarioIdAutenticado.trim().isEmpty) {
      _actualizarEstadoLocal(() {
        perfilActual = null;
        errorCargaPerfil =
            'No se pudo identificar tu sesión. Vuelve a iniciar sesión.';
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
        errorCargaPerfil =
            'No se encontró tu perfil de trabajador. Contacta al administrador.';
        return;
      } else {
        perfilActual = perfil;
      }

      if (perfilActual != null) {
        await _cargarDatosComplementariosDelPerfil();
      }
    } catch (_) {
      _asignarPerfilConErrorDeCarga();
      errorCargaPerfil =
          'No se pudo cargar tu información de asistencia. Revisa tu conexión y vuelve a intentar.';
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
      final historial = await _obtenerAsistenciasPorUsuario
          .ejecutar(perfil.usuarioId)
          .timeout(esperaConfirmacion);

      _historialReciente
        ..clear()
        ..addAll(historial);
      errorFechaHistorial = null;
    } on FechaAsistenciaInvalida {
      _historialReciente.clear();
      errorFechaHistorial = FechaAsistenciaInvalida.mensaje;
      rethrow;
    } finally {
      _actualizarEstadoLocal(() {
        cargandoHistorial = false;
      });
    }
  }

  // Consulta la ubicacion actual del dispositivo y la compara con la sede real.
  Future<void> validarUbicacion() async {
    final perfil = perfilActual;
    if (_cerrado ||
        guardando ||
        perfil == null ||
        perfil.sedeId.isEmpty ||
        validandoUbicacion) {
      return;
    }
    await _validarUbicacionConPerfil(perfil);
  }

  Future<void> _validarUbicacionConPerfil(PerfilTrabajadorActual perfil) async {
    _actualizarEstadoLocal(() {
      validandoUbicacion = true;
      resultadoUbicacion = null;
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
    if (_cerrado || guardando || validandoRostro) return;
    _actualizarEstadoLocal(() {
      validandoRostro = true;
    });

    try {
      final resultado = await _validarRostroCapturado.ejecutar(
        rutaImagen: rutaImagen,
      );
      _aplicarResultadoFacial(resultado);
    } catch (_) {
      _aplicarResultadoFacial(_crearResultadoFacialConError());
    } finally {
      _actualizarEstadoLocal(() {
        validandoRostro = false;
      });
    }
  }

  // Cada marcacion debe apoyarse en una captura reciente,
  // por eso limpiamos el estado facial cuando la asistencia ya fue aceptada.
  void limpiarValidacionFacial() {
    alLimpiarRostro?.call();
    _actualizarEstadoLocal(() {
      resultadoFacial = null;
    });
  }

  void _actualizarMensajeEstado(String? mensaje) {
    _actualizarEstadoLocal(() {
      mensajeEstado = mensaje;
    });
  }

  Future<bool> _rechazarMarcacion({required String mensaje}) async {
    mensajeEstado = mensaje;
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

  Future<bool> _validarUbicacionParaMarcacion(
    TipoMarcacion tipoMarcacion,
  ) async {
    // La validación de la pantalla previa nunca sustituye al GPS al confirmar.
    await _validarUbicacionConPerfil(perfilActual!);

    final rechazo = obtenerRechazoUbicacionMarcacion(
      ubicacion: resultadoUbicacion,
      tipoMarcacion: tipoMarcacion,
    );
    if (rechazo != null) {
      return _rechazarMarcacion(mensaje: rechazo.mensaje);
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
      return _rechazarMarcacion(mensaje: rechazo.mensaje);
    }

    return true;
  }

  Future<bool> _validarReglasDiariasMarcacion(
    TipoMarcacion tipoMarcacion,
    DateTime ahora,
  ) async {
    final rechazo = obtenerRechazoReglaDiariaMarcacion(
      marcacionesHoy: _marcacionesDelDia(ahora),
      tipoMarcacion: tipoMarcacion,
      ahora: ahora,
      tipoHorario: horarioAsignado,
    );
    if (rechazo != null) {
      return _rechazarMarcacion(mensaje: rechazo.mensaje);
    }

    return true;
  }

  Asistencia _crearAsistenciaPendiente({
    required PerfilTrabajadorActual perfil,
    required TipoMarcacion tipoMarcacion,
    required DateTime fechaHora,
    required String observacion,
    required String? urlEvidenciaFacial,
    required TipoHorarioPersonal horario,
    required BloqueJornada bloque,
  }) {
    return crearAsistenciaTrabajador(
      perfil: perfil,
      tipoMarcacion: tipoMarcacion,
      fechaHora: fechaHora,
      tipoHorario: horario.name,
      bloqueJornada: bloque.name,
      ubicacion: resultadoUbicacion,
      dentroDeZona: dentroDeZona,
      rostroValidado: rostroValidado,
      observacion: observacion,
      urlEvidenciaFacial: urlEvidenciaFacial,
    );
  }

  void _insertarAsistenciaEnMemoria(Asistencia asistencia, String idGenerado) {
    _historialReciente.removeWhere((marca) => marca.id == idGenerado);
    _historialReciente.insert(0, clonarAsistenciaConId(asistencia, idGenerado));
  }

  String _mensajeRegistroExitoso({
    required TipoMarcacion tipoMarcacion,
    required DateTime fechaHora,
  }) {
    return construirMensajeRegistroExitoso(
      tipoMarcacion: tipoMarcacion,
      fechaHora: fechaHora,
    );
  }

  Future<bool> registrarMarcacion(
    TipoMarcacion tipoMarcacion, {
    DateTime? fechaProceso,
  }) => SesionTrabajador.instancia.protegerOperacion(
    () =>
        _registrarMarcacionProtegida(tipoMarcacion, fechaProceso: fechaProceso),
  );

  Future<bool> _registrarMarcacionProtegida(
    TipoMarcacion tipoMarcacion, {
    DateTime? fechaProceso,
  }) async {
    if (confirmacionPendiente) {
      _actualizarEstadoLocal(() => mensajeEstado = _mensajePendiente);
      return false;
    }
    if (_cerrado ||
        guardando ||
        cargandoPerfil ||
        cargandoHistorial ||
        validandoRostro ||
        validandoUbicacion) {
      return false;
    }

    _actualizarEstadoLocal(() {
      guardando = true;
      mensajeEstado = null;
      resultadoUbicacion = null;
    });

    var envioIniciado = false;
    try {
      // En producción estas lecturas exigen servidor: no se reutiliza el perfil
      // almacenado en memoria ni el de la caché cuando no hay conexión.
      final perfilSeguro = await _obtenerPerfilTrabajadorActual
          .ejecutar(
            usuarioId: usuarioIdAutenticado,
            nombreFallback: nombreAutenticado,
            correoFallback: correoAutenticado,
          )
          .timeout(esperaConfirmacion);
      if (_cerrado) return false;
      perfilActual = perfilSeguro;
      if (perfilSeguro == null) {
        mensajeEstado =
            'No se pudo confirmar un perfil activo. Actualiza tus datos o consulta al administrador.';
        return false;
      }
      errorCargaPerfil = null;
      if (comprobarSeguridad != null) await comprobarSeguridad!();
      if (!_validarContextoBasicoMarcacion(perfilSeguro)) return false;
      // La consulta al servidor detecta marcas previas de otros dispositivos.
      await cargarHistorial();
      if (_cerrado) return false;
      if (!tieneHorarioParaHoy) {
        mensajeEstado =
            'Tu cargo no tiene horario asignado. Solicita revisión al administrador.';
        return false;
      }
      if (!await _validarRostroParaMarcacion(tipoMarcacion)) return false;
      if (!await _validarUbicacionParaMarcacion(tipoMarcacion)) return false;
      if (_cerrado) return false;
      final ahora = _ahora();
      if (fechaProceso != null &&
          !mismoProcesoMarcacion(
            fechaProceso,
            ahora,
            tipoMarcacion,
            resumenJornadaHoy.tipoHorario,
          )) {
        mensajeEstado =
            'Cambio el turno o la fecha. Cierra esta ventana y vuelve a iniciar la marcacion.';
        return false;
      }
      if (!await _validarReglasDiariasMarcacion(tipoMarcacion, ahora)) {
        return false;
      }
      final horarioRegistro = resumenJornadaHoy.tipoHorario;
      final ventanaRegistro = ventanasPara(
        horarioRegistro,
        fecha: ahora,
      ).firstWhere((v) => v.tipo == tipoMarcacion && v.contiene(ahora));
      final asistencia = _crearAsistenciaPendiente(
        horario: horarioRegistro,
        bloque: ventanaRegistro.bloque,
        perfil: perfilSeguro,
        tipoMarcacion: tipoMarcacion,
        fechaHora: ahora,
        observacion: 'Marcacion generada desde la pantalla del trabajador.',
        urlEvidenciaFacial: null,
      );

      envioIniciado = true;
      // El timeout libera la pantalla, pero NO cancela la escritura de Firebase.
      // Conservamos su resultado para atender también confirmaciones tardías.
      final envio = _registrarAsistencia.ejecutar(asistencia);
      _envioPendiente = envio;
      final confirmacion = envio.then(
        (idGenerado) {
          _envioPendiente = null;
          if (_cerrado) return;
          _insertarAsistenciaEnMemoria(asistencia, idGenerado);
          mensajeEstado = _mensajeRegistroExitoso(
            tipoMarcacion: tipoMarcacion,
            fechaHora: asistencia.fechaHora,
          );
          limpiarValidacionFacial();
          _notificarCambio();
        },
        onError: (Object error, StackTrace stack) {
          _envioPendiente = null;
          if (!_cerrado) {
            mensajeEstado =
                'No pudimos confirmar la asistencia. Actualiza el historial con internet antes de reintentar.';
            _notificarCambio();
          }
          Error.throwWithStackTrace(error, stack);
        },
      );
      await confirmacion.timeout(esperaConfirmacion);

      // Refrescamos el historial real despues de guardar para que la pantalla
      // refleje exactamente los datos persistidos en Firestore.
      try {
        await cargarHistorial().timeout(esperaConfirmacion);
      } catch (_) {
        // El registro ya fue confirmado; una recarga no cambia ese resultado.
      }
      return true;
    } on FechaAsistenciaInvalida {
      mensajeEstado = FechaAsistenciaInvalida.mensaje;
      return false;
    } on ErrorBiometrico catch (e) {
      limpiarValidacionFacial();
      mensajeEstado = e.mensaje;
      return false;
    } catch (_) {
      mensajeEstado = envioIniciado
          ? (confirmacionPendiente
                ? _mensajePendiente
                : 'No pudimos confirmar la asistencia. Actualiza el historial con internet antes de reintentar.')
          : 'No pudimos actualizar los datos necesarios para marcar. Revisa tu conexión y vuelve a intentar. No se envió la asistencia.';
      return false;
    } finally {
      _actualizarEstadoLocal(() {
        guardando = false;
      });
    }
  }

  @override
  void dispose() {
    _cerrado = true;
    _temporizador?.cancel();
    conexion.removeListener(_notificarCambio);
    conexion.dispose();
    super.dispose();
  }

  bool _cerrado = false;
}
