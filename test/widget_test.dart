import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/alertas/dominio/casos_de_uso/obtener_alertas_por_usuario.dart';
import 'package:asistencia_app/funcionalidades/alertas/dominio/casos_de_uso/registrar_alerta.dart';
import 'package:asistencia_app/funcionalidades/alertas/dominio/entidades/alerta.dart';
import 'package:asistencia_app/funcionalidades/alertas/dominio/repositorios/repositorio_alertas.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/registrar_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/tipo_marcacion.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/repositorios/repositorio_asistencias.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/modulo_historial_trabajador.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/paginas/pagina_inicio_sesion.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/entidades/resultado_validacion_ubicacion.dart';
import 'package:asistencia_app/funcionalidades/geolocalizacion/dominio/repositorios/repositorio_geolocalizacion.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/casos_de_uso/subir_evidencia_facial.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/entidades/resultado_validacion_facial.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/repositorios/repositorio_evidencia_facial.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/dominio/repositorios/repositorio_reconocimiento_facial.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/casos_de_uso/obtener_sede_por_id.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/repositorios/repositorio_sedes.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/casos_de_uso/obtener_usuario_por_id.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/repositorios/repositorio_usuarios.dart';

void main() {
  // Esta prueba evita depender de Firebase durante el entorno de test
  // y valida la composicion basica de la pantalla de acceso.
  testWidgets('muestra la pantalla institucional de inicio de sesion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAplicacion(),
        home: const PaginaInicioSesion(),
      ),
    );
    await tester.pump();

    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('UNACHU'), findsOneWidget);
    expect(find.text('INGRESAR AL SISTEMA'), findsOneWidget);
  });

  testWidgets('el historial permite abrir selector de fecha en inicio/fin y buscar', (
    WidgetTester tester,
  ) async {
    var inicioSolicitada = 0;
    var finSolicitada = 0;
    var busquedaEjecutada = 0;

    final controlador = ControladorAsistencia(
      obtenerAlertasPorUsuario: ObtenerAlertasPorUsuario(
        _RepositorioAlertasFake(),
      ),
      registrarAlerta: RegistrarAlerta(_RepositorioAlertasFake()),
      registrarAsistencia: RegistrarAsistencia(_RepositorioAsistenciasFake()),
      obtenerAsistenciasPorUsuario:
          ObtenerAsistenciasPorUsuario(_RepositorioAsistenciasFake()),
      obtenerPerfilTrabajadorActual: ObtenerPerfilTrabajadorActual(
        obtenerUsuarioPorId: ObtenerUsuarioPorId(_RepositorioUsuariosFake()),
        obtenerSedePorId: ObtenerSedePorId(_RepositorioSedesFake()),
      ),
      subirEvidenciaFacial: SubirEvidenciaFacial(_RepositorioEvidenciaFacialFake()),
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
  });
}

class _RepositorioAlertasFake implements RepositorioAlertas {
  @override
  Future<String> registrarAlerta(Alerta alerta) async => 'id';

  @override
  Future<List<Alerta>> obtenerAlertasPorUsuario(String usuarioId) async => const [];
}

class _RepositorioAsistenciasFake implements RepositorioAsistencias {
  @override
  Future<String> registrarAsistencia(Asistencia asistencia) async => 'id';

  @override
  Future<List<Asistencia>> obtenerAsistenciasPorUsuario(String usuarioId) async => const [];

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

class _RepositorioEvidenciaFacialFake implements RepositorioEvidenciaFacial {
  @override
  Future<String> subirEvidenciaFacial({
    required String usuarioId,
    required String rutaImagenLocal,
    required DateTime fechaHora,
    required TipoMarcacion tipoMarcacion,
  }) async => 'url';
}

class _RepositorioReconocimientoFacialFake implements RepositorioReconocimientoFacial {
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
