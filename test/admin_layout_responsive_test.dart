import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/item_menu_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/layout_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/cuadricula_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/indicador_dashboard_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/formulario_sedes_admin.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/rol_usuario.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/topbar_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/sidebar_admin.dart';

void main() {
  testWidgets(
    'la barra ocupa todo el ancho sobre el menú y permite ocultarlo',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      await tester.pumpWidget(
        MaterialApp(
          theme: temaAplicacion(),
          home: const LayoutAdmin(
            items: _items,
            indiceSeleccionado: 0,
            onSeleccionar: _noSeleccionado,
            child: Text('Contenido'),
          ),
        ),
      );
      await tester.pump();
      final barra = tester.getRect(find.byType(TopbarAdmin));
      expect(barra.left, 0);
      expect(barra.width, 1280);
      expect(tester.getRect(find.byType(SidebarAdmin)).top, barra.bottom);
      await tester.tap(find.byTooltip('Ocultar menú'));
      await tester.pump();
      expect(find.byType(SidebarAdmin), findsNothing);
      expect(tester.getRect(find.byType(TopbarAdmin)), barra);
      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pump();
      expect(find.byType(SidebarAdmin), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('fecha y nombre permanecen arriba al desplazar el contenido', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 480));
    const nombre = 'Administradora con nombres y apellidos completos';
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAplicacion(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const LayoutAdmin(
          usuarioAdministrador: Usuario(
            id: 'admin',
            nombreCompleto: nombre,
            correo: 'admin@example.com',
            rol: RolUsuario.administrador,
            sedeAsignadaId: 'principal',
          ),
          items: _items,
          indiceSeleccionado: 0,
          onSeleccionar: _noSeleccionado,
          child: Column(
            children: [SizedBox(height: 1800), Text('Fin del módulo')],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(nombre), findsOneWidget);
    final ahora = DateTime.now();
    final fecha =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}';
    expect(find.text(fecha), findsOneWidget);
    final posicion = tester.getTopLeft(find.byType(TopbarAdmin));
    await tester.ensureVisible(find.text('Fin del módulo'));
    await tester.pump();
    expect(tester.getTopLeft(find.byType(TopbarAdmin)), posicion);
    expect(find.text(nombre).hitTestable(), findsOneWidget);
    expect(find.text(fecha).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('el panel se adapta sin desbordar en distintos anchos', (
    tester,
  ) async {
    const anchos = [
      320.0,
      360.0,
      600.0,
      768.0,
      942.0,
      979.0,
      980.0,
      1024.0,
      1099.0,
      1100.0,
      1280.0,
      1440.0,
      1536.0,
      1920.0,
    ];
    const item = ItemMenuAdmin(
      id: 'dashboard',
      titulo: 'Dashboard',
      descripcion: 'Resumen general del panel administrativo.',
      icono: Icons.dashboard_outlined,
    );
    const items = [item];

    for (final ancho in anchos) {
      await tester.binding.setSurfaceSize(Size(ancho, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: LayoutAdmin(
            items: items,
            indiceSeleccionado: 0,
            onSeleccionar: _noSeleccionado,
            child: SizedBox(height: 700),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'La cabecera no debe desbordar a $ancho px.',
      );
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'contenido y navegación accesibles en ventanas bajas y texto ampliado',
    (tester) async {
      for (final escala in [1.0, 1.25, 1.5, 2.0]) {
        for (final pantalla in [
          const Size(320, 480),
          const Size(768, 400),
          const Size(1366, 768),
          const Size(1536, 864),
          const Size(1920, 1080),
        ]) {
          await tester.binding.setSurfaceSize(pantalla);
          await tester.pumpWidget(
            MaterialApp(
              theme: temaAplicacion(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(escala)),
                child: child!,
              ),
              home: LayoutAdmin(
                items: _items,
                indiceSeleccionado: 0,
                onSeleccionar: _noSeleccionado,
                onCerrarSesion: () async {},
                child: Column(
                  children: [
                    CuadriculaAdmin(
                      children: [
                        for (var i = 0; i < 5; i++)
                          const IndicadorDashboardAdmin(
                            titulo: 'Trabajadores sin marcaciones',
                            valor: '123',
                            etiqueta:
                                'Información para revisar las jornadas de los trabajadores.',
                            colorAcento: Colors.teal,
                            icono: Icons.groups_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormularioSedesAdmin(
                      sedes: const [
                        Sede(
                          id: 's',
                          nombre: 'Sede Principal',
                          latitud: -12,
                          longitud: -75,
                          radioPermitidoMetros: 50,
                        ),
                      ],
                      onGuardado: (_) {},
                    ),
                    const SizedBox(height: 20),
                    const Text('Fin del contenido'),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '$pantalla, texto $escala',
          );
          final scroll = find
              .descendant(
                of: find.byType(Scrollbar),
                matching: find.byType(SingleChildScrollView),
              )
              .first;
          await tester.scrollUntilVisible(
            find.text('Fin del contenido'),
            700,
            scrollable: find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
            maxScrolls: 40,
          );
          expect(find.text('Fin del contenido').hitTestable(), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Desplazamiento $pantalla, texto $escala',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'cinco indicadores caben con el ancho útil de un monitor escalado',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      await tester.pumpWidget(
        MaterialApp(
          theme: temaAplicacion(),
          home: LayoutAdmin(
            items: _items,
            indiceSeleccionado: 0,
            onSeleccionar: _noSeleccionado,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CuadriculaAdmin(
                children: [
                  for (var i = 0; i < 5; i++)
                    IndicadorDashboardAdmin(
                      key: ValueKey('indicador-$i'),
                      titulo: 'Jornadas registradas hoy',
                      valor: '123',
                      etiqueta: 'Registros del día',
                      colorAcento: Colors.teal,
                      icono: Icons.groups_outlined,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final primeraFila = tester
          .getTopLeft(find.byKey(const ValueKey('indicador-0')))
          .dy;
      for (var i = 1; i < 5; i++) {
        expect(
          tester.getTopLeft(find.byKey(ValueKey('indicador-$i'))).dy,
          primeraFila,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('elegir un módulo cierra el menú de ventanas pequeñas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 600));
    var seleccionado = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAplicacion(),
        home: StatefulBuilder(
          builder: (context, cambiar) => LayoutAdmin(
            items: _items,
            indiceSeleccionado: seleccionado,
            onSeleccionar: (indice) => cambiar(() => seleccionado = indice),
            child: const Text('Contenido'),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sedes'));
    await tester.pumpAndSettle();
    expect(seleccionado, 4);
    expect(
      tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Trabajadores despliega sus submódulos y permite navegar', (
    tester,
  ) async {
    for (final ancho in [390.0, 1366.0]) {
      await tester.binding.setSurfaceSize(Size(ancho, 800));
      var seleccionado = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: temaAplicacion(),
          home: StatefulBuilder(
            builder: (context, cambiar) => LayoutAdmin(
              items: _items,
              indiceSeleccionado: seleccionado,
              onSeleccionar: (indice) => cambiar(() => seleccionado = indice),
              child: const Text('Contenido del submódulo'),
            ),
          ),
        ),
      );
      if (ancho < 1200) {
        await tester.tap(find.byTooltip('Abrir menú'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Trabajadores'));
      await tester.pumpAndSettle();
      expect(seleccionado, 0);
      final crear = find.text('Crear trabajador').hitTestable();
      expect(crear, findsOneWidget);
      await tester.tap(crear);
      await tester.pumpAndSettle();
      expect(seleccionado, 2);
      if (ancho < 1200) {
        expect(
          tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
          isFalse,
        );
        await tester.tap(find.byTooltip('Abrir menú'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Vigentes').hitTestable());
      await tester.pumpAndSettle();
      expect(seleccionado, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    await tester.binding.setSurfaceSize(null);
  });
}

const _items = [
  ItemMenuAdmin(
    id: 'dashboard',
    titulo: 'Dashboard',
    descripcion: 'Resumen de las jornadas y del personal.',
    icono: Icons.dashboard_outlined,
  ),
  ItemMenuAdmin(
    id: 'trabajadores',
    titulo: 'Trabajadores',
    descripcion: 'Gestión del personal.',
    icono: Icons.groups_outlined,
  ),
  ItemMenuAdmin(
    id: 'crear_trabajador',
    grupoId: 'trabajadores',
    titulo: 'Crear trabajador',
    descripcion: 'Registro de personal.',
    icono: Icons.person_add_alt_1_outlined,
  ),
  ItemMenuAdmin(
    id: 'trabajadores_vigentes',
    grupoId: 'trabajadores',
    titulo: 'Vigentes',
    descripcion: 'Personal vigente.',
    icono: Icons.verified_user_outlined,
  ),
  ItemMenuAdmin(
    id: 'sedes',
    titulo: 'Sedes',
    descripcion: 'Configuración de ubicaciones.',
    icono: Icons.location_on_outlined,
  ),
  ItemMenuAdmin(
    id: 'asistencias',
    titulo: 'Asistencias',
    descripcion: 'Consulta de las jornadas.',
    icono: Icons.fact_check_outlined,
  ),
  ItemMenuAdmin(
    id: 'auditoria',
    titulo: 'Auditoría',
    descripcion: 'Historial de cambios.',
    icono: Icons.history_outlined,
  ),
];

void _noSeleccionado(int _) {}
