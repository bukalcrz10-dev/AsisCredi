import 'package:flutter/material.dart';
import '../modelos/trabajador_admin.dart';
import 'cuadricula_admin.dart';
import 'espacio_visible_admin.dart';

class _PanelRecuperacionContrasena extends StatelessWidget {
  const _PanelRecuperacionContrasena({required this.correo, this.onRecuperar});

  final String correo;
  final VoidCallback? onRecuperar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE9ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tema.colorScheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: tema.colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recuperación de contraseña',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recibirá un enlace para crear una nueva contraseña.',
                      style: tema.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Container(
                width: 400,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0EAEE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.alternate_email_rounded,
                      size: 18,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correo del trabajador',
                            style: tema.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 3),
                          SelectableText(
                            correo,
                            style: tema.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onRecuperar,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Enviar enlace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FichaTrabajadorAdmin extends StatefulWidget {
  const FichaTrabajadorAdmin({
    super.key,
    required this.trabajador,
    required this.onVolver,
    this.onEditar,
    this.onRecuperar,
    this.onEstado,
    this.construirBiometria,
    this.construirAsistencia,
    this.construirResumenAsistencia,
    this.error,
  });
  final TrabajadorAdmin trabajador;
  final VoidCallback onVolver;
  final VoidCallback? onEditar, onRecuperar, onEstado;
  final WidgetBuilder? construirBiometria;
  final WidgetBuilder? construirAsistencia;
  final WidgetBuilder? construirResumenAsistencia;
  final String? error;

  @override
  State<FichaTrabajadorAdmin> createState() => _FichaTrabajadorAdminState();
}

class _FichaTrabajadorAdminState extends State<FichaTrabajadorAdmin>
    with SingleTickerProviderStateMixin {
  late final TabController _pestanas;

  @override
  void initState() {
    super.initState();
    _pestanas = TabController(length: 4, vsync: this);
    _pestanas.addListener(_actualizarPestana);
  }

  void _actualizarPestana() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FichaTrabajadorAdmin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trabajador.id != widget.trabajador.id) _pestanas.index = 0;
  }

  @override
  void dispose() {
    _pestanas.removeListener(_actualizarPestana);
    _pestanas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trabajador = widget.trabajador;
    final partesNombre = trabajador.nombreCompleto
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();
    final corteNombre = partesNombre.length >= 3
        ? partesNombre.length - 2
        : partesNombre.length == 2
        ? 1
        : partesNombre.length;
    final nombres = partesNombre.take(corteNombre).join(' ');
    final apellidos = partesNombre.skip(corteNombre).join(' ');
    final onEditar = widget.onEditar;
    final onRecuperar = widget.onRecuperar;
    final onEstado = widget.onEstado;
    final onVolver = widget.onVolver;
    final error = widget.error;
    Widget dato(String etiqueta, String valor, IconData icono) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icono, size: 16, color: const Color(0xFF74909B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF006575),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  valor.isEmpty ? 'Sin asignar' : valor,
                  style:
                      (etiqueta == 'Identificador'
                              ? Theme.of(context).textTheme.bodySmall
                              : Theme.of(context).textTheme.bodyMedium)
                          ?.copyWith(
                            fontSize: etiqueta == 'Identificador' ? 12 : 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF263E48),
                            letterSpacing: 0,
                            height: 1.4,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final decoracionPrincipal = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCBDDE3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14123847),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    );
    Widget panel(Widget child) => Container(
      padding: const EdgeInsets.all(20),
      decoration: decoracionPrincipal,
      child: child,
    );
    final identidad = Container(
      key: const ValueKey('tarjeta-identidad-trabajador'),
      clipBehavior: Clip.antiAlias,
      decoration: decoracionPrincipal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            color: const Color(0xFFF0F7F8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Volver al listado',
                      onPressed: onVolver,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar trabajador',
                          onPressed: onEditar,
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        IconButton(
                          tooltip: trabajador.estadoActivo
                              ? 'Desactivar trabajador'
                              : 'Activar trabajador',
                          onPressed: onEstado,
                          icon: Icon(
                            trabajador.estadoActivo
                                ? Icons.toggle_on_outlined
                                : Icons.toggle_off_outlined,
                            size: 23,
                          ),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person_outline_rounded, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombres.isEmpty ? 'Sin nombre' : nombres,
                            key: const ValueKey('nombres-trabajador'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                          ),
                          if (apellidos.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              apellidos,
                              key: const ValueKey('apellidos-trabajador'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                    height: 1.25,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            trabajador.cargo.trim().isEmpty
                                ? 'Sin cargo asignado'
                                : trabajador.cargo,
                            key: const ValueKey('cargo-cabecera-trabajador'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Información general',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                dato(
                  'Correo institucional',
                  trabajador.correo,
                  Icons.mail_outline_rounded,
                ),
                dato('Teléfono', trabajador.telefono, Icons.phone_outlined),
                const Divider(height: 14),
                dato('Cargo', trabajador.cargo, Icons.work_outline_rounded),
                dato('Área', trabajador.area, Icons.business_center_outlined),
                dato(
                  'Sede asignada',
                  trabajador.sede,
                  Icons.location_on_outlined,
                ),
                dato('Rol de acceso', trabajador.rol, Icons.badge_outlined),
                dato(
                  'Inicio de labores',
                  trabajador.fechaInicioLabores == null
                      ? 'Sin registrar'
                      : '${trabajador.fechaInicioLabores!.day.toString().padLeft(2, '0')}/${trabajador.fechaInicioLabores!.month.toString().padLeft(2, '0')}/${trabajador.fechaInicioLabores!.year}',
                  Icons.calendar_today_outlined,
                ),
                const Divider(height: 14),
                dato('Identificador', trabajador.id, Icons.fingerprint_rounded),
              ],
            ),
          ),
        ],
      ),
    );
    final resumen = panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _pestanas,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
            indicator: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
            tabs: const [
              Tab(text: 'Resumen'),
              Tab(text: 'Asistencia'),
              Tab(text: 'Rostro y celular'),
              Tab(text: 'Recuperar contraseña'),
            ],
          ),
          const SizedBox(height: 24),
          if (_pestanas.index == 0) ...[
            Text(
              'Resumen del trabajador',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            CuadriculaAdmin(
              maximoColumnas: 4,
              children: [
                for (final item in [
                  ('Cargo', trabajador.cargo, Icons.work_outline),
                  ('Área', trabajador.area, Icons.business_center_outlined),
                  (
                    'Sede asignada',
                    trabajador.sede,
                    Icons.location_on_outlined,
                  ),
                  ('Rol de acceso', trabajador.rol, Icons.badge_outlined),
                ])
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.$3,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 5),
                              SelectableText(
                                item.$2.isEmpty ? 'Sin asignar' : item.$2,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (_pestanas.index == 0 &&
              widget.construirResumenAsistencia != null) ...[
            const Divider(height: 36),
            widget.construirResumenAsistencia!(context),
          ],
          if (_pestanas.index == 1)
            widget.construirAsistencia?.call(context) ??
                const Text(
                  'La consulta de asistencia no está disponible en esta vista.',
                ),
          if (_pestanas.index == 2)
            widget.construirBiometria?.call(context) ??
                const Text(
                  'La gestión de rostro y celular no está disponible en esta vista.',
                ),
          if (_pestanas.index == 3)
            _PanelRecuperacionContrasena(
              correo: trabajador.correo,
              onRecuperar: onRecuperar,
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= 900 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 21
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: EspacioVisibleAdmin.alturaDe(context),
                        ),
                        child: identidad,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: resumen),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [identidad, const SizedBox(height: 16), resumen],
                ),
        ),
      ],
    );
  }
}
