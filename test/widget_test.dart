import 'dart:async';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/paginas/pagina_inicio.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/fabrica_controlador_asistencia.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/datos/repositorios/repositorio_reconocimiento_facial_impl.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/rol_usuario.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/controladores/controlador_inicio_sesion.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/dominio/casos_de_uso/iniciar_sesion.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/dominio/repositorios/repositorio_autenticacion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/registrar_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/repositorios/repositorio_asistencias.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/modulo_historial_trabajador.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/paginas/pagina_inicio_sesion.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/entidades/resultado_validacion_ubicacion.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/repositorios/repositorio_geolocalizacion.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/entidades/resultado_validacion_facial.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/repositorios/repositorio_reconocimiento_facial.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/casos_de_uso/obtener_sede_por_id.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/repositorios/repositorio_sedes.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/casos_de_uso/obtener_usuario_por_id.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/repositorios/repositorio_usuarios.dart';

void main() {
  testWidgets(
    'no muestra sede pendiente ni errores de cargo durante la carga inicial',
    (tester) async {
      final usuarios = _UsuariosDemorados();
      final controlador = ControladorAsistencia(
        registrarAsistencia: RegistrarAsistencia(_RepositorioAsistenciasFake()),
        obtenerAsistenciasPorUsuario: ObtenerAsistenciasPorUsuario(
          _RepositorioAsistenciasFake(),
        ),
        obtenerPerfilTrabajadorActual: ObtenerPerfilTrabajadorActual(
          obtenerUsuarioPorId: ObtenerUsuarioPorId(usuarios),
          obtenerSedePorId: ObtenerSedePorId(_SedeLista()),
        ),
        validarRostroCapturado: ValidarRostroCapturado(
          _RepositorioReconocimientoFacialFake(),
        ),
        validarUbicacionActual: ValidarUbicacionActual(
          _RepositorioGeolocalizacionFake(),
        ),
        usuarioIdAutenticado: 'u1',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaInicio(
            crearDependencias: () => DependenciasAsistencia(
              controlador: controlador,
              repositorioReconocimientoFacial: _DetectorSinCamara(),
            ),
          ),
        ),
      );
      expect(
        find.text('Cargando tu información de asistencia…'),
        findsOneWidget,
      );
      expect(find.text('Sede pendiente'), findsNothing);
      expect(find.textContaining('Tu cargo no tiene horario'), findsNothing);
      expect(find.text('Progreso del dia'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Sede pendiente'), findsNothing);
      usuarios.respuesta.complete(
        const Usuario(
          id: 'u1',
          nombreCompleto: 'Trabajador prueba',
          correo: 'prueba@example.com',
          rol: RolUsuario.trabajador,
          cargo: 'Plataforma',
          sedeAsignadaId: 's1',
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Cargando tu información de asistencia…'), findsNothing);
      expect(find.text('Trabajador prueba'), findsOneWidget);
      expect(find.text('Sede prueba'), findsOneWidget);
      expect(find.textContaining('Tu cargo no tiene horario'), findsNothing);
      usuarios.fallar = true;
      await controlador.cargarPerfil();
      await tester.pump();
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Sede pendiente'), findsNothing);
      expect(find.textContaining('Tu cargo no tiene horario'), findsNothing);
      usuarios.fallar = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Trabajador prueba'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  // Esta prueba evita depender de Firebase durante el entorno de test
  // y valida la composicion basica de la pantalla de acceso.
  testWidgets('muestra la pantalla institucional de inicio de sesion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAplicacion(),
        home: PaginaInicioSesion(
          crearControlador: () => ControladorInicioSesion(
            iniciarSesion: IniciarSesion(_AuthFake()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('CREDIASCIENDE'), findsOneWidget);
    expect(find.text('INGRESAR AL SISTEMA'), findsOneWidget);
    expect(find.text('Mantener mi sesión iniciada'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
  });

  testWidgets(
    'el historial permite abrir selector de fecha en inicio/fin y buscar',
    (WidgetTester tester) async {
      var inicioSolicitada = 0;
      var finSolicitada = 0;
      var busquedaEjecutada = 0;

      final controlador = ControladorAsistencia(
        registrarAsistencia: RegistrarAsistencia(_RepositorioAsistenciasFake()),
        obtenerAsistenciasPorUsuario: ObtenerAsistenciasPorUsuario(
          _RepositorioAsistenciasFake(),
        ),
        obtenerPerfilTrabajadorActual: ObtenerPerfilTrabajadorActual(
          obtenerUsuarioPorId: ObtenerUsuarioPorId(_RepositorioUsuariosFake()),
          obtenerSedePorId: ObtenerSedePorId(_RepositorioSedesFake()),
        ),
        validarRostroCapturado: ValidarRostroCapturado(
          _RepositorioReconocimientoFacialFake(),
        ),
        validarUbicacionActual: ValidarUbicacionActual(
          _RepositorioGeolocalizacionFake(),
        ),
        usuarioIdAutenticado: 'u1',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: temaAplicacion(),
          home: ModuloHistorialTrabajador(
            controlador: controlador,
            onSeleccionarFechaInicio: () async {
              inicioSolicitada++;
            },
            onSeleccionarFechaFin: () async {
              finSolicitada++;
            },
            onBuscarRango: () async {
              busquedaEjecutada++;
            },
          ),
        ),
      );

      await tester.tap(find.text('Inicio'));
      await tester.tap(find.text('Fin'));
      await tester.tap(find.byIcon(Icons.search));

      expect(inicioSolicitada, 1);
      expect(finSolicitada, 1);
      expect(busquedaEjecutada, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      controlador.dispose();
    },
  );
}

class _RepositorioAsistenciasFake implements RepositorioAsistencias {
  @override
  Future<String> registrarAsistencia(Asistencia asistencia) async => 'id';

  @override
  Future<List<Asistencia>> obtenerAsistenciasPorUsuario(
    String usuarioId,
  ) async => const [];

  @override
  Future<List<Asistencia>> obtenerAsistencias() async => const [];

  @override
  Future<void> eliminarAsistencia(String id) async {}
}

class _RepositorioUsuariosFake implements RepositorioUsuarios {
  @override
  Future<Usuario?> obtenerUsuarioPorId(String id) async => null;

  @override
  Future<List<Usuario>> obtenerUsuarios() async => const [];

  @override
  Future<void> guardarUsuario(Usuario usuario) async {}
}

class _RepositorioSedesFake implements RepositorioSedes {
  @override
  Future<Sede?> obtenerSedePorId(String id) async => null;

  @override
  Future<void> guardarSede(Sede sede) async {}
}

class _RepositorioReconocimientoFacialFake
    implements RepositorioReconocimientoFacial {
  @override
  Future<ResultadoValidacionFacial> validarRostroEnImagen({
    required String rutaImagen,
  }) async {
    throw UnimplementedError();
  }
}

class _RepositorioGeolocalizacionFake implements RepositorioGeolocalizacion {
  @override
  Future<ResultadoValidacionUbicacion> validarUbicacionActual({
    required double latitudSede,
    required double longitudSede,
    required double radioPermitidoMetros,
  }) async {
    throw UnimplementedError();
  }
}

class _AuthFake extends Fake implements RepositorioAutenticacion {}

class _UsuariosDemorados extends _RepositorioUsuariosFake {
  final respuesta = Completer<Usuario?>();
  bool fallar = false;
  @override
  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    if (fallar) throw StateError('Sin conexion');
    return respuesta.future;
  }
}

class _SedeLista extends _RepositorioSedesFake {
  @override
  Future<Sede?> obtenerSedePorId(String id) async => const Sede(
    id: 's1',
    nombre: 'Sede prueba',
    latitud: -12,
    longitud: -75,
    radioPermitidoMetros: 100,
  );
}

class _DetectorSinCamara extends Fake
    implements RepositorioReconocimientoFacialImpl {
  @override
  Future<void> cerrar() async {}
}
