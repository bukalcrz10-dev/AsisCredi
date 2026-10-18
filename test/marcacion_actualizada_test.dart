import 'dart:async';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/seguridad/servicio_seguridad_biometrica.dart';
import 'package:flutter/material.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/modulo_asistencia_trabajador.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/hoja_proceso_marcacion.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/fecha_asistencia_invalida.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/registrar_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/perfil_trabajador_actual.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/tipo_marcacion.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/entidades/resultado_validacion_ubicacion.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/entidades/resultado_validacion_facial.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';

PerfilTrabajadorActual perfil({
  String cargo = 'Plataforma',
  String sede = 'huancayo',
  bool activa = true,
}) {
  final latitud = sede == 'huancayo' ? -12.0 : -11.0;
  final oficina = Sede(
    id: sede,
    nombre: sede,
    latitud: latitud,
    longitud: -75,
    radioPermitidoMetros: 100,
    activa: activa,
  );
  return PerfilTrabajadorActual(
    usuarioId: 'u1',
    nombreCompleto: 'Prueba',
    rolOCargo: cargo,
    area: '',
    cargo: cargo,
    telefono: '',
    sedeId: sede,
    nombreSede: sede,
    correoNotificacion: 'prueba@example.invalid',
    latitudSede: latitud,
    longitudSede: -75,
    radioPermitidoMetros: 100,
    sede: oficina,
  );
}

ResultadoValidacionUbicacion ubicacion({
  bool dentro = true,
  double latitud = -12,
}) => ResultadoValidacionUbicacion(
  servicioHabilitado: true,
  permisoConcedido: true,
  latitudActual: latitud,
  longitudActual: -75,
  distanciaMetros: dentro ? 0 : 1000,
  dentroDeZona: dentro,
  mensajeEstado: dentro ? 'Correcta' : 'Fuera de zona',
);

class _Perfil extends Fake implements ObtenerPerfilTrabajadorActual {
  PerfilTrabajadorActual? actual = perfil();
  bool fallar = false;
  @override
  Future<PerfilTrabajadorActual?> ejecutar({
    required String usuarioId,
    String? nombreFallback,
    String? correoFallback,
  }) async {
    if (fallar) throw StateError('Sin red');
    return actual;
  }
}

class _Historial extends Fake implements ObtenerAsistenciasPorUsuario {
  bool fechaInvalida = false;
  final List<Asistencia> marcas = [];
  @override
  Future<List<Asistencia>> ejecutar(String usuarioId) async {
    if (fechaInvalida) throw const FechaAsistenciaInvalida('invalida');
    return List.of(marcas);
  }
}

class _Guardar extends Fake implements RegistrarAsistencia {
  final List<Asistencia> enviadas = [];
  Completer<String>? pendiente;
  @override
  Future<String> ejecutar(Asistencia asistencia) async {
    enviadas.add(asistencia);
    return pendiente == null ? 'nueva' : await pendiente!.future;
  }
}

class _Gps extends Fake implements ValidarUbicacionActual {
  ResultadoValidacionUbicacion resultado = ubicacion();
  Completer<ResultadoValidacionUbicacion>? pendiente;
  bool fallar = false;
  int consultas = 0;
  double? latitudConsultada;
  @override
  Future<ResultadoValidacionUbicacion> ejecutar({
    required double latitudSede,
    required double longitudSede,
    required double radioPermitidoMetros,
  }) async {
    consultas++;
    latitudConsultada = latitudSede;
    if (fallar) throw StateError('GPS apagado');
    return pendiente == null ? resultado : await pendiente!.future;
  }
}

class _Rostro extends Fake implements ValidarRostroCapturado {
  bool fallar = false;
  @override
  Future<ResultadoValidacionFacial> ejecutar({
    required String rutaImagen,
  }) async {
    if (fallar) throw StateError('No se pudo analizar la imagen');
    return const ResultadoValidacionFacial(
      permisoCamaraConcedido: true,
      rostroDetectado: false,
      cantidadRostros: 0,
      rutaImagenCapturada: null,
      mensajeEstado: 'No se detectó un rostro. Vuelve a intentarlo.',
    );
  }
}

void main() {
  late _Perfil perfiles;
  late _Historial historial;
  late _Guardar guardar;
  late _Gps gps;
  late _Rostro rostros;
  late ControladorAsistencia controlador;
  late DateTime ahora;
  ErrorBiometrico? falloSeguridad;
  int consultasSeguridad = 0;
  setUp(() {
    falloSeguridad = null;
    consultasSeguridad = 0;
    perfiles = _Perfil();
    historial = _Historial();
    guardar = _Guardar();
    gps = _Gps();
    rostros = _Rostro();
    ahora = DateTime(2026, 10, 9, 8, 30);
    controlador = ControladorAsistencia(
      comprobarSeguridad: () async {
        consultasSeguridad++;
        if (falloSeguridad != null) throw falloSeguridad!;
      },

      registrarAsistencia: guardar,
      obtenerAsistenciasPorUsuario: historial,
      obtenerPerfilTrabajadorActual: perfiles,
      validarRostroCapturado: rostros,
      validarUbicacionActual: gps,
      usuarioIdAutenticado: 'u1',
      ahora: () => ahora,
      esperaConfirmacion: const Duration(milliseconds: 50),
    );
    controlador.perfilActual = perfil();
    controlador.resultadoUbicacion = ubicacion();
    controlador.resultadoFacial = const ResultadoValidacionFacial(
      permisoCamaraConcedido: true,
      rostroDetectado: true,
      cantidadRostros: 1,
      rutaImagenCapturada: 'prueba.jpg',
      mensajeEstado: 'Correcta',
    );
  });
  tearDown(() => controlador.dispose());

  test(
    'rostro rechazado muestra el motivo y bloquea la marca sin alertas',
    () async {
      await controlador.validarRostroConImagen('foto.jpg');
      expect(
        controlador.mensajeEstado,
        'No se detectó un rostro. Vuelve a intentarlo.',
      );
      expect(controlador.rostroValidado, isFalse);
      expect(controlador.validandoRostro, isFalse);
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isFalse,
      );
      expect(guardar.enviadas, isEmpty);
    },
  );

  test(
    'un error de análisis facial sigue mostrando un mensaje y libera la espera',
    () async {
      rostros.fallar = true;
      await controlador.validarRostroConImagen('foto.jpg');
      expect(
        controlador.mensajeEstado,
        contains('No pudimos analizar la foto facial'),
      );
      expect(controlador.rostroValidado, isFalse);
      expect(controlador.validandoRostro, isFalse);
      expect(guardar.enviadas, isEmpty);
    },
  );

  test(
    'autorización retirada bloquea la marcación y limpia la validación facial',
    () async {
      falloSeguridad = const ErrorBiometrico(
        'El celular ya no está autorizado.',
      );
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isFalse,
      );
      expect(consultasSeguridad, 1);
      expect(guardar.enviadas, isEmpty);
      expect(gps.consultas, 0);
      expect(controlador.resultadoFacial, isNull);
      expect(controlador.mensajeEstado, 'El celular ya no está autorizado.');
      expect(controlador.guardando, isFalse);
    },
  );

  test(
    'validación vigente permite guardar y se vuelve a consultar al confirmar',
    () async {
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isTrue,
      );
      expect(consultasSeguridad, 1);
      expect(guardar.enviadas, hasLength(1));
    },
  );

  for (final horario in ['plataforma', 'asesor']) {
    testWidgets('$horario conserva botones y salida con cargo retirado', (
      tester,
    ) async {
      historial.marcas.add(
        Asistencia(
          id: 'entrada',
          usuarioId: 'u1',
          nombreUsuario: 'Prueba',
          sedeId: 'huancayo',
          tipoMarcacion: TipoMarcacion.entrada,
          tipoHorario: horario,
          bloqueJornada: 'manana',
          fechaHora: ahora,
          latitud: -12,
          longitud: -75,
          dentroDeZona: true,
          rostroValidado: true,
        ),
      );
      perfiles.actual = perfil(cargo: '');
      controlador.perfilActual = perfiles.actual;
      ahora = DateTime(
        2026,
        10,
        9,
        horario == 'plataforma' ? 13 : 18,
        horario == 'plataforma' ? 0 : 30,
      );
      controlador.fechaHoraActual = ahora;
      await controlador.cargarHistorial();
      expect(controlador.horarioAsignado, isNull);
      expect(controlador.tieneHorarioParaHoy, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModuloAsistenciaTrabajador(
              controlador: controlador,
              onAbrirProcesoMarcacion: (_) async {},
            ),
          ),
        ),
      );
      expect(find.text('Registrarse'), findsOneWidget);
      expect(find.textContaining('Tu cargo no tiene horario'), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HojaProcesoMarcacion(
              controlador: controlador,
              tipoMarcacion: TipoMarcacion.salida,
              fechaProceso: ahora,
              onValidarRostro: () async {},
            ),
          ),
        ),
      );
      final boton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrarse'),
      );
      expect(boton.onPressed, isNotNull);
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.salida),
        isTrue,
      );
      expect(guardar.enviadas.single.tipoHorario, horario);
      await tester.pumpWidget(const SizedBox.shrink());
      ahora = DateTime(2026, 10, 10, 8, 30);
      expect(controlador.tieneHorarioParaHoy, isFalse);
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isFalse,
      );
      expect(guardar.enviadas, hasLength(1));
    });
  }

  test(
    'fecha inválida impide marcar y permite recuperar historial corregido',
    () async {
      historial.fechaInvalida = true;
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isFalse,
      );
      expect(guardar.enviadas, isEmpty);
      expect(controlador.errorFechaHistorial, FechaAsistenciaInvalida.mensaje);
      expect(controlador.mensajeEstado, FechaAsistenciaInvalida.mensaje);
      expect(controlador.guardando, isFalse);
      expect(controlador.cargandoHistorial, isFalse);
      historial.fechaInvalida = false;
      await controlador.cargarHistorial();
      expect(controlador.errorFechaHistorial, isNull);
    },
  );

  test('libera la espera sin reenviar y acepta confirmación tardía', () async {
    guardar.pendiente = Completer<String>();
    expect(
      await controlador.registrarMarcacion(TipoMarcacion.entrada),
      isFalse,
    );
    expect(controlador.guardando, isFalse);
    expect(controlador.confirmacionPendiente, isTrue);
    expect(controlador.historialReciente, isEmpty);
    expect(controlador.mensajeEstado, contains('actualiza el historial'));
    expect(
      await controlador.registrarMarcacion(TipoMarcacion.entrada),
      isFalse,
    );
    expect(guardar.enviadas, hasLength(1));
    guardar.pendiente!.complete('confirmada');
    await Future<void>.delayed(Duration.zero);
    expect(controlador.confirmacionPendiente, isFalse);
    expect(controlador.historialReciente.single.id, 'confirmada');
    expect(controlador.mensajeEstado, isNot(contains('No pudimos')));
  });

  test('rechazo tardío no inventa un registro ni deja bloqueado', () async {
    guardar.pendiente = Completer<String>();
    await controlador.registrarMarcacion(TipoMarcacion.entrada);
    guardar.pendiente!.completeError(StateError('Rechazado'));
    await Future<void>.delayed(Duration.zero);
    expect(controlador.confirmacionPendiente, isFalse);
    expect(controlador.guardando, isFalse);
    expect(controlador.historialReciente, isEmpty);
    expect(controlador.mensajeEstado, contains('antes de reintentar'));
  });

  test(
    'confirmación después de cerrar no notifica un controlador destruido',
    () async {
      guardar.pendiente = Completer<String>();
      await controlador.registrarMarcacion(TipoMarcacion.entrada);
      controlador.dispose();
      guardar.pendiente!.complete('confirmada');
      await Future<void>.delayed(Duration.zero);
      expect(controlador.historialReciente, isEmpty);
      // tearDown no debe destruir dos veces el mismo ChangeNotifier.
      controlador = ControladorAsistencia(
        registrarAsistencia: guardar,
        obtenerAsistenciasPorUsuario: historial,
        obtenerPerfilTrabajadorActual: perfiles,
        validarRostroCapturado: _Rostro(),
        validarUbicacionActual: gps,
        usuarioIdAutenticado: 'u1',
      );
    },
  );

  test('reconsulta GPS y rechaza si salió de la sede tras validar', () async {
    gps.resultado = ubicacion(dentro: false);
    expect(
      await controlador.registrarMarcacion(TipoMarcacion.entrada),
      isFalse,
    );
    expect(gps.consultas, 1);
    expect(guardar.enviadas, isEmpty);
    expect(controlador.dentroDeZona, isFalse);
  });
  test('fallo GPS no reutiliza coordenadas anteriores', () async {
    gps.fallar = true;
    expect(
      await controlador.registrarMarcacion(TipoMarcacion.entrada),
      isFalse,
    );
    expect(guardar.enviadas, isEmpty);
    expect(controlador.resultadoUbicacion!.latitudActual, isNull);
    expect(controlador.guardando, isFalse);
  });
  test(
    'cambio de sede usa nuevas coordenadas y guarda la nueva sede',
    () async {
      perfiles.actual = perfil(sede: 'satipo');
      gps.resultado = ubicacion(latitud: -11);
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isTrue,
      );
      expect(gps.latitudConsultada, -11);
      expect(guardar.enviadas.single.sedeId, 'satipo');
      expect(guardar.enviadas.single.latitud, -11);
      expect(controlador.perfilActual!.sedeId, 'satipo');
    },
  );
  test(
    'sin red para refrescar perfil no consulta GPS ni envía marca',
    () async {
      perfiles.fallar = true;
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isFalse,
      );
      expect(gps.consultas, 0);
      expect(guardar.enviadas, isEmpty);
      expect(controlador.resultadoUbicacion, isNull);
      expect(controlador.mensajeEstado, contains('No se envió'));
    },
  );
  test('perfil retirado/inactivo no usa la asignación anterior', () async {
    perfiles.actual = null;
    expect(
      await controlador.registrarMarcacion(TipoMarcacion.entrada),
      isFalse,
    );
    expect(controlador.perfilActual, isNull);
    expect(guardar.enviadas, isEmpty);
  });
  test(
    'sede desactivada mientras la app estaba abierta impide marcar',
    () async {
      perfiles.actual = perfil(activa: false);
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isFalse,
      );
      expect(gps.consultas, 0);
      expect(guardar.enviadas, isEmpty);
    },
  );
  test('cargo nuevo sin jornada iniciada usa horario nuevo', () async {
    ahora = DateTime(2026, 10, 9, 14);
    perfiles.actual = perfil(cargo: 'Asesor');
    expect(await controlador.registrarMarcacion(TipoMarcacion.entrada), isTrue);
    expect(guardar.enviadas.single.tipoHorario, 'asesor');
    expect(guardar.enviadas.single.bloqueJornada, 'manana');
  });
  test(
    'jornada Plataforma iniciada conserva horario aunque ahora sea Asesor',
    () async {
      historial.marcas.add(
        Asistencia(
          id: 'entrada',
          usuarioId: 'u1',
          nombreUsuario: 'Prueba',
          sedeId: 'huancayo',
          tipoMarcacion: TipoMarcacion.entrada,
          tipoHorario: 'plataforma',
          bloqueJornada: 'manana',
          fechaHora: ahora,
          latitud: -12,
          longitud: -75,
          dentroDeZona: true,
          rostroValidado: true,
        ),
      );
      ahora = DateTime(2026, 10, 9, 13);
      perfiles.actual = perfil(cargo: 'Asesor');
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.salida),
        isTrue,
      );
      expect(guardar.enviadas.single.tipoHorario, 'plataforma');
      expect(guardar.enviadas.single.bloqueJornada, 'manana');
    },
  );
  test('cierre de ventana durante GPS impide guardar', () async {
    ahora = DateTime(2026, 10, 9, 12, 59);
    final inicio = ahora;
    gps.pendiente = Completer();
    final registro = controlador.registrarMarcacion(
      TipoMarcacion.entrada,
      fechaProceso: inicio,
    );
    await Future<void>.delayed(Duration.zero);
    ahora = DateTime(2026, 10, 9, 13);
    gps.pendiente!.complete(ubicacion());
    expect(await registro, isFalse);
    expect(guardar.enviadas, isEmpty);
  });
  test(
    'doble confirmación no inicia otra consulta ni duplica la marca',
    () async {
      gps.pendiente = Completer();
      final primero = controlador.registrarMarcacion(TipoMarcacion.entrada);
      await Future<void>.delayed(Duration.zero);
      expect(controlador.guardando, isTrue);
      expect(
        await controlador.registrarMarcacion(TipoMarcacion.entrada),
        isFalse,
      );
      await controlador.validarUbicacion();
      expect(gps.consultas, 1);
      gps.pendiente!.complete(ubicacion());
      expect(await primero, isTrue);
      expect(guardar.enviadas, hasLength(1));
    },
  );
}
