import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/modulo_asistencias_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/tema_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/exportacion_asistencias_trabajador_admin.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/rol_usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/ficha_trabajador_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/trabajador_admin.dart';
import 'evaluacion_asistencia_admin_test.dart' as fixtures;

const _usuarios = [
  Usuario(
    id: 'uno',
    nombreCompleto: 'Trabajador Uno',
    correo: 'uno@example.com',
    cargo: 'Asesor',
    rol: RolUsuario.trabajador,
    sedeAsignadaId: 's',
  ),
  Usuario(
    id: 'dos',
    nombreCompleto: 'Persona Ajena',
    correo: 'dos@example.com',
    cargo: 'Asesor',
    rol: RolUsuario.trabajador,
    sedeAsignadaId: 's',
  ),
];

class _Asistencias extends Fake implements RepositorioAsistenciasImpl {
  final consultas = <String>[];
  int generales = 0;
  _Asistencias({
    TipoHorarioPersonal horario = TipoHorarioPersonal.asesor,
    int dia = 9,
  }) {
    agregarJornada(horario, dia: dia);
  }
  final marcas = <Asistencia>[];
  void agregarJornada(
    TipoHorarioPersonal horario, {
    required int dia,
    int retraso = 0,
  }) {
    for (final usuario in _usuarios) {
      for (final m in fixtures.jornada(horario, dia: dia, retraso: retraso)) {
        marcas.add(
          Asistencia(
            id: '${usuario.id}-$dia-${m.id}',
            usuarioId: usuario.id,
            nombreUsuario: usuario.nombreCompleto,
            sedeId: m.sedeId,
            tipoMarcacion: m.tipoMarcacion,
            fechaHora: m.fechaHora,
            latitud: m.latitud,
            longitud: m.longitud,
            dentroDeZona: m.dentroDeZona,
            rostroValidado: m.rostroValidado,
            tipoHorario: m.tipoHorario,
            bloqueJornada: m.bloqueJornada,
          ),
        );
      }
    }
  }

  @override
  Future<List<Asistencia>> obtenerAsistenciasPorUsuario(
    String usuarioId,
  ) async {
    consultas.add(usuarioId);
    // Entrega también otra persona para verificar la defensa de la pantalla.
    return marcas;
  }

  @override
  Future<PaginaAsistencias> obtenerPaginaAsistencias({
    int limite = 50,
    DateTime? desde,
    DateTime? hastaExclusiva,
    dynamic despuesDe,
  }) async {
    generales++;
    return PaginaAsistencias(
      asistencias: marcas,
      ultimoDocumento: null,
      hayMas: false,
    );
  }
}

class _Usuarios extends Fake implements RepositorioUsuariosImpl {
  int generales = 0;
  final consultas = <String>[];
  @override
  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    consultas.add(id);
    return _usuarios.where((u) => u.id == id).firstOrNull;
  }

  @override
  Future<List<Usuario>> obtenerUsuarios() async {
    generales++;
    return _usuarios;
  }
}

Widget _pantalla(
  _Asistencias asistencias,
  _Usuarios usuarios, {
  String? id,
  VistaAsistenciasAdmin vista = VistaAsistenciasAdmin.completa,
}) => MaterialApp(
  theme: temaPanelAdmin(temaAplicacion()),
  home: Scaffold(
    body: SingleChildScrollView(
      child: ModuloAsistenciasAdmin(
        trabajadorId: id,
        vista: vista,
        repositorioAsistencias: asistencias,
        repositorioUsuarios: usuarios,
        cargarSedes: () async => {'s': 'Sede Principal'},
      ),
    ),
  ),
);

void main() {
  testWidgets('consulta compacta se adapta sin perder filtros ni exportación', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final ancho in [1280.0, 768.0, 320.0]) {
      for (final escala in [1.0, 2.0]) {
        await tester.binding.setSurfaceSize(Size(ancho, 1000));
        final pantalla =
            _pantalla(
                  _Asistencias(),
                  _Usuarios(),
                  id: 'uno',
                  vista: VistaAsistenciasAdmin.registros,
                )
                as MaterialApp;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('$ancho-$escala'),
            theme: pantalla.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
            home: pantalla.home,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('1 jornada · 2 marcaciones'), findsNothing);
        expect(find.text('Consulta y exporta sus registros.'), findsNothing);
        expect(find.byTooltip('Actualizar asistencias'), findsOneWidget);
        expect(
          find.byType(ExportacionAsistenciasTrabajadorAdmin),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
        if (ancho == 1280 && escala == 1) {
          expect(
            (tester.getCenter(find.text('Consulta de asistencias')).dy -
                    tester.getCenter(find.text('Exportar')).dy)
                .abs(),
            lessThan(28),
          );
        }
      }
    }
  });

  testWidgets('resumen integrado se adapta a ventanas y texto ampliado', (
    tester,
  ) async {
    final captura = GlobalKey();
    final asistencias = _Asistencias();
    final usuarios = _Usuarios();
    for (final medida in [
      (1600.0, 1.0),
      (768.0, 1.0),
      (320.0, 1.0),
      (1280.0, 2.0),
      (320.0, 2.0),
    ]) {
      await tester.binding.setSurfaceSize(Size(medida.$1, 1100));
      await tester.pumpWidget(
        MaterialApp(
          theme: temaPanelAdmin(temaAplicacion()),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(medida.$2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: captura,
                child: FichaTrabajadorAdmin(
                  trabajador: const TrabajadorAdmin(
                    id: 'uno',
                    nombreCompleto: 'Ana María Pérez García',
                    correo: 'ana@example.com',
                    telefono: '999999999',
                    area: 'Créditos y cobranzas',
                    cargo: 'Asesor',
                    rol: 'Trabajador',
                    estadoActivo: true,
                    sede: 'Sede Principal',
                  ),
                  onVolver: () {},
                  construirResumenAsistencia: (_) => ModuloAsistenciasAdmin(
                    trabajadorId: 'uno',
                    vista: VistaAsistenciasAdmin.resumen,
                    repositorioAsistencias: asistencias,
                    repositorioUsuarios: usuarios,
                    cargarSedes: () async => {'s': 'Sede Principal'},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Actualizar resumen'), findsOneWidget);
      expect(find.text('Jornadas correctas'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Resumen ${medida.$1} px, texto ${medida.$2}',
      );
      if (medida.$1 == 1600) {
        await tester.runAsync(() async {
          final borde =
              captura.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final imagen = await borde.toImage();
          final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
          final directorio = Directory('.dart_tool/verificacion_diseno')
            ..createSync(recursive: true);
          File(
            '${directorio.path}/resumen_trabajador.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          imagen.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    }
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('la exportación usa las jornadas mostradas tras filtrar estado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    final asistencias = _Asistencias()
      ..agregarJornada(TipoHorarioPersonal.asesor, dia: 8, retraso: 15);
    await tester.pumpWidget(
      _pantalla(
        asistencias,
        _Usuarios(),
        id: 'uno',
        vista: VistaAsistenciasAdmin.registros,
      ),
    );
    await tester.pumpAndSettle();
    final exportador = find.byType(ExportacionAsistenciasTrabajadorAdmin);
    expect(
      tester
          .widget<ExportacionAsistenciasTrabajadorAdmin>(exportador)
          .informe
          .dias
          .length,
      2,
    );
    final estado = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(estado);
    await tester.pumpAndSettle();
    await tester.tap(estado);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Observada').last);
    await tester.pumpAndSettle();
    final informe = tester
        .widget<ExportacionAsistenciasTrabajadorAdmin>(exportador)
        .informe;
    expect(informe.dias.single.fecha.day, 8);
    expect(informe.totalTardanzaTexto, '00:15:00');
    expect(find.text('Regularizar'), findsOneWidget);
    expect(asistencias.consultas, ['uno']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'en la ficha las tarjetas están en Resumen y los filtros en Asistencia',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      final asistencias = _Asistencias();
      final usuarios = _Usuarios();
      await tester.pumpWidget(
        _pantalla(
          asistencias,
          usuarios,
          id: 'uno',
          vista: VistaAsistenciasAdmin.registros,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Marcaciones cargadas'), findsNothing);
      expect(find.text('Consulta de asistencias'), findsOneWidget);
      expect(find.text('Regularizar'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Trabajador'), findsNothing);
      await tester.pumpWidget(
        _pantalla(
          asistencias,
          usuarios,
          id: 'uno',
          vista: VistaAsistenciasAdmin.resumen,
        ),
      );
      await tester.pumpAndSettle();
      for (final titulo in [
        'Marcaciones cargadas',
        'Jornadas correctas',
        'Jornadas observadas',
        'Pendientes',
      ]) {
        expect(find.text(titulo), findsOneWidget);
      }
      expect(find.text('Consulta de asistencias'), findsNothing);
      expect(find.text('Regularizar'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Actualizar resumen'));
      await tester.pumpAndSettle();
      expect(asistencias.consultas, ['uno', 'uno']);
      expect(asistencias.generales, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final caso in [
    (TipoHorarioPersonal.asesor, 9, true),
    (TipoHorarioPersonal.plataforma, 9, false),
    (TipoHorarioPersonal.plataforma, 10, true),
  ]) {
    testWidgets(
      '${caso.$1} día ${caso.$2}: columnas y regularización directa según jornada',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1200));
        final asistencias = _Asistencias(horario: caso.$1, dia: caso.$2);
        await tester.pumpWidget(_pantalla(asistencias, _Usuarios(), id: 'uno'));
        await tester.pumpAndSettle();
        if (caso.$3) {
          expect(find.text('Entrada'), findsOneWidget);
          expect(find.text('Salida'), findsOneWidget);
          expect(find.text('Entrada\nTarde'), findsNothing);
          expect(find.text(caso.$2 == 10 ? '15:00' : '18:30'), findsOneWidget);
        } else {
          for (final columna in [
            'Entrada\nMañana',
            'Salida\nMañana',
            'Entrada\nTarde',
            'Salida\nTarde',
          ]) {
            expect(find.text(columna), findsOneWidget);
          }
          expect(find.text('13:00'), findsOneWidget);
          expect(find.text('15:00'), findsOneWidget);
        }
        await tester.ensureVisible(find.text('Regularizar'));
        await tester.tap(find.text('Regularizar'));
        await tester.pumpAndSettle();
        expect(find.text('Detalle de marcacion'), findsNothing);
        expect(find.text('Regularizar jornada'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          findsNWidgets(caso.$3 ? 3 : 5),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }

  testWidgets(
    'historial mixto conserva ambos tipos aunque el cargo actual sea Asesor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      final asistencias = _Asistencias()
        ..agregarJornada(TipoHorarioPersonal.plataforma, dia: 8);
      await tester.pumpWidget(_pantalla(asistencias, _Usuarios(), id: 'uno'));
      await tester.pumpAndSettle();
      expect(find.text('Jornada continua · entrada y salida'), findsNothing);
      expect(find.text('Jornada partida · mañana y tarde'), findsNothing);
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Entrada\nTarde'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);
      expect(find.text('18:30'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'consulta, recarga y cambio de trabajador mantienen el alcance por ID',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      final asistencias = _Asistencias();
      final usuarios = _Usuarios();
      await tester.pumpWidget(_pantalla(asistencias, usuarios, id: 'uno'));
      await tester.pumpAndSettle();
      expect(asistencias.consultas, ['uno']);
      expect(asistencias.generales, 0);
      expect(usuarios.generales, 0);
      expect(find.text('Regularizar'), findsOneWidget);
      expect(find.text('Trabajador Uno'), findsNothing);
      expect(find.text('Persona Ajena'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Actualizar asistencias'));
      await tester.tap(find.byTooltip('Actualizar asistencias'));
      await tester.pumpAndSettle();
      expect(asistencias.consultas, ['uno', 'uno']);
      await tester.ensureVisible(find.text('Regularizar'));
      await tester.tap(find.text('Regularizar'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de marcacion'), findsNothing);
      expect(find.text('Regularizar jornada'), findsOneWidget);
      expect(
        find.textContaining('Corrige las horas de'),
        findsNothing,
      );
      expect(
        find.text('Motivo de la corrección (obligatorio)'),
        findsOneWidget,
      );
      expect(find.text('Persona Ajena'), findsNothing);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_pantalla(asistencias, usuarios, id: 'dos'));
      await tester.pumpAndSettle();
      expect(asistencias.consultas.last, 'dos');
      expect(find.text('Trabajador Uno'), findsNothing);
      expect(find.text('Regularizar'), findsOneWidget);
      await tester.ensureVisible(find.text('Regularizar'));
      await tester.tap(find.text('Regularizar'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Corrige las horas de'),
        findsNothing,
      );
      expect(asistencias.generales, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'el módulo general conserva la consulta de todos los trabajadores',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      final asistencias = _Asistencias();
      final usuarios = _Usuarios();
      await tester.pumpWidget(_pantalla(asistencias, usuarios));
      await tester.pumpAndSettle();
      expect(asistencias.generales, 1);
      expect(asistencias.consultas, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Trabajador'), findsWidgets);
      expect(find.text('Trabajador Uno'), findsWidgets);
      expect(find.text('Persona Ajena'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('un identificador vacío no abre una consulta general', (
    tester,
  ) async {
    final asistencias = _Asistencias();
    final usuarios = _Usuarios();
    await tester.pumpWidget(_pantalla(asistencias, usuarios, id: ' '));
    await tester.pumpAndSettle();
    expect(asistencias.generales, 0);
    expect(usuarios.generales, 0);
    expect(asistencias.consultas, isEmpty);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
