import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../../asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../../../asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../asistencias/dominio/entidades/tipo_marcacion.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import 'contenedor_modulo_admin.dart';
import 'tarjeta_resumen_admin.dart';

class ModuloAsistenciasAdmin extends StatefulWidget {
  const ModuloAsistenciasAdmin({super.key});

  @override
  State<ModuloAsistenciasAdmin> createState() => _ModuloAsistenciasAdminState();
}

class _ModuloAsistenciasAdminState extends State<ModuloAsistenciasAdmin> {
  late final RepositorioAsistenciasImpl _repositorioAsistencias;
  late final RepositorioUsuariosImpl _repositorioUsuarios;
  late Future<List<_AsistenciaAdminFila>> _cargaAsistencias;

  final TextEditingController _busquedaController = TextEditingController();
  final ScrollController _tablaScrollController = ScrollController();

  String _busqueda = '';
  String _estadoSeleccionado = 'Todos';

  static const List<String> _estados = <String>[
    'Todos',
    'Correcta',
    'Observada',
    'Pendiente',
  ];

  @override
  void initState() {
    super.initState();
    _repositorioAsistencias = RepositorioAsistenciasImpl(
      FuenteDatosAsistenciasFirestore(),
    );
    _repositorioUsuarios = RepositorioUsuariosImpl(
      FuenteDatosUsuariosFirestore(),
    );
    _cargaAsistencias = _cargarFilasAsistencias();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _tablaScrollController.dispose();
    super.dispose();
  }

  Future<List<_AsistenciaAdminFila>> _cargarFilasAsistencias() async {
    final asistencias = await _repositorioAsistencias.obtenerAsistencias();
    final usuarios = await _repositorioUsuarios.obtenerUsuarios();
    final usuariosPorId = {
      for (final usuario in usuarios) usuario.id: usuario,
    };

    final grupos = <String, _GrupoAsistenciaAdmin>{};

    for (final asistencia in asistencias) {
      final fecha = _formatearFecha(asistencia.fechaHora);
      final clave = '${asistencia.usuarioId}|$fecha';
      final usuario = usuariosPorId[asistencia.usuarioId];

      final grupo = grupos.putIfAbsent(
        clave,
        () => _GrupoAsistenciaAdmin(
          fecha: fecha,
          usuarioId: asistencia.usuarioId,
          trabajador: usuario?.nombreCompleto.trim().isNotEmpty == true
              ? usuario!.nombreCompleto
              : asistencia.nombreUsuario,
          correo: usuario?.correo ?? asistencia.correoNotificacion ?? '',
          area: usuario?.area ?? '',
          cargo: usuario?.cargo ?? '',
        ),
      );

      grupo.marcaciones.add(asistencia);
      if (asistencia.tipoMarcacion == TipoMarcacion.entrada) {
        if (grupo.entrada == null ||
            asistencia.fechaHora.isBefore(grupo.entrada!.fechaHora)) {
          grupo.entrada = asistencia;
        }
      } else {
        if (grupo.salida == null ||
            asistencia.fechaHora.isAfter(grupo.salida!.fechaHora)) {
          grupo.salida = asistencia;
        }
      }
    }

    final filas = grupos.values.map((grupo) => grupo.aFila()).toList();
    filas.sort((a, b) => b.fechaOrden.compareTo(a.fechaOrden));
    return filas;
  }

  List<_AsistenciaAdminFila> _filtrarAsistencias(
    List<_AsistenciaAdminFila> asistencias,
  ) {
    final consulta = _busqueda.trim().toLowerCase();

    return asistencias.where((asistencia) {
      final coincideEstado = _estadoSeleccionado == 'Todos' ||
          asistencia.estado == _estadoSeleccionado;

      final coincideBusqueda = consulta.isEmpty ||
          asistencia.trabajador.toLowerCase().contains(consulta) ||
          asistencia.correo.toLowerCase().contains(consulta) ||
          asistencia.area.toLowerCase().contains(consulta) ||
          asistencia.cargo.toLowerCase().contains(consulta) ||
          asistencia.fecha.toLowerCase().contains(consulta);

      return coincideEstado && coincideBusqueda;
    }).toList();
  }

  void _recargarAsistencias() {
    setState(() {
      _cargaAsistencias = _cargarFilasAsistencias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_AsistenciaAdminFila>>(
      future: _cargaAsistencias,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return ContenedorModuloAdmin(
            titulo: 'Consulta de asistencias',
            descripcion:
                'No se pudieron cargar las marcaciones desde Firestore.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ocurrio un problema al consultar las asistencias reales. Revisa permisos, conexion o indices de Firestore.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.rojoInstitucionalOscuro,
                      ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _recargarAsistencias,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final todas = snapshot.data ?? const <_AsistenciaAdminFila>[];
        final asistencias = _filtrarAsistencias(todas);
        final correctas =
            todas.where((item) => item.estado == 'Correcta').length;
        final observadas =
            todas.where((item) => item.estado == 'Observada').length;
        final pendientes =
            todas.where((item) => item.estado == 'Pendiente').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                TarjetaResumenAdmin(
                  titulo: 'Marcaciones cargadas',
                  valor: '${todas.length}',
                  detalle: 'Registros agrupados desde Firestore.',
                  colorAcento: ColoresSistema.rojoInstitucional,
                  icono: Icons.fact_check_outlined,
                ),
                TarjetaResumenAdmin(
                  titulo: 'Registros correctos',
                  valor: '$correctas',
                  detalle: 'Entrada y salida completas sin observacion.',
                  colorAcento: ColoresSistema.verdeExito,
                  icono: Icons.verified_outlined,
                ),
                TarjetaResumenAdmin(
                  titulo: 'Registros observados',
                  valor: '$observadas',
                  detalle: 'Casos con validaciones parciales o alertas.',
                  colorAcento: const Color(0xFFB66A18),
                  icono: Icons.warning_amber_outlined,
                ),
                TarjetaResumenAdmin(
                  titulo: 'Pendientes',
                  valor: '$pendientes',
                  detalle: 'Jornadas incompletas o aun sin cierre.',
                  colorAcento: ColoresSistema.verdeInstitucional,
                  icono: Icons.pending_actions_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ContenedorModuloAdmin(
              titulo: 'Consulta de asistencias',
              descripcion:
                  'Marcaciones reales de Firestore agrupadas por trabajador y fecha.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ancho = constraints.maxWidth;
                      if (ancho >= 1100) {
                        return Row(
                          children: [
                            const Expanded(
                              child: _CampoFiltroAdmin(
                                icono: Icons.calendar_today_outlined,
                                texto: 'Fecha inicio',
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: _CampoFiltroAdmin(
                                icono: Icons.event_outlined,
                                texto: 'Fecha fin',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _busquedaController,
                                onChanged: (valor) {
                                  setState(() {
                                    _busqueda = valor;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Buscar trabajador o correo...',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                initialValue: _estadoSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                ),
                                items: _estados
                                    .map(
                                      (estado) => DropdownMenuItem<String>(
                                        value: estado,
                                        child: Text(estado),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (valor) {
                                  if (valor == null) {
                                    return;
                                  }
                                  setState(() {
                                    _estadoSeleccionado = valor;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: 'Actualizar asistencias',
                              onPressed: _recargarAsistencias,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        );
                      }

                      final anchoFecha = ancho < 760 ? 150.0 : 260.0;
                      final anchoBusqueda = ancho < 760 ? 190.0 : 420.0;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: anchoFecha,
                            child: const _CampoFiltroAdmin(
                              icono: Icons.calendar_today_outlined,
                              texto: 'Fecha inicio',
                            ),
                          ),
                          SizedBox(
                            width: anchoFecha,
                            child: const _CampoFiltroAdmin(
                              icono: Icons.event_outlined,
                              texto: 'Fecha fin',
                            ),
                          ),
                          SizedBox(
                            width: anchoBusqueda,
                            child: TextField(
                              controller: _busquedaController,
                              onChanged: (valor) {
                                setState(() {
                                  _busqueda = valor;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Buscar trabajador o correo...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              initialValue: _estadoSeleccionado,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                              ),
                              items: _estados
                                  .map(
                                    (estado) => DropdownMenuItem<String>(
                                      value: estado,
                                      child: Text(estado),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (valor) {
                                if (valor == null) {
                                  return;
                                }
                                setState(() {
                                  _estadoSeleccionado = valor;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Actualizar asistencias',
                            onPressed: _recargarAsistencias,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Registros encontrados: ${asistencias.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ColoresSistema.rojoInstitucionalOscuro,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final usarTablaCompacta = constraints.maxWidth < 1200;

                      Widget contenidoTabla({
                        required bool compacta,
                      }) {
                        return Container(
                          decoration: BoxDecoration(
                            color: ColoresSistema.fondoSuave,
                            borderRadius: BorderRadius.circular(
                              MedidasSistema.radioBloque,
                            ),
                            border: Border.all(
                              color: ColoresSistema.bordeIntermedio,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE9EFF3),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      MedidasSistema.radioBloque,
                                    ),
                                    topRight: Radius.circular(
                                      MedidasSistema.radioBloque,
                                    ),
                                  ),
                                ),
                                child: compacta
                                    ? const Row(
                                        children: [
                                          SizedBox(
                                            width: 110,
                                            child: _TituloColumna('Trabajador'),
                                          ),
                                          SizedBox(
                                            width: 150,
                                            child: _TituloColumna('Area'),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: _TituloColumna('Cargo'),
                                          ),
                                          SizedBox(
                                            width: 95,
                                            child: _TituloColumna('Fecha'),
                                          ),
                                          SizedBox(
                                            width: 70,
                                            child: _TituloColumna('Entrada'),
                                          ),
                                          SizedBox(
                                            width: 70,
                                            child: _TituloColumna('Salida'),
                                          ),
                                          SizedBox(
                                            width: 75,
                                            child: _TituloColumna('Tardanza'),
                                          ),
                                          SizedBox(
                                            width: 85,
                                            child: _TituloColumna('T. laborado'),
                                          ),
                                          SizedBox(
                                            width: 110,
                                            child: _TituloColumna('Estado'),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: _TituloColumna('Accion'),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: _TituloColumna('Trabajador'),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: _TituloColumna('Area'),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: _TituloColumna('Cargo'),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: _TituloColumna('Fecha'),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: _TituloColumna('Entrada'),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: _TituloColumna('Salida'),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: _TituloColumna('Tardanza'),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: _TituloColumna('T. laborado'),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: _TituloColumna('Estado'),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: _TituloColumna('Accion'),
                                          ),
                                        ],
                                      ),
                              ),
                              if (asistencias.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    todas.isEmpty
                                        ? 'Aun no hay marcaciones registradas en Firestore.'
                                        : 'No se encontraron marcaciones con los filtros actuales.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: ColoresSistema.textoSecundario,
                                        ),
                                  ),
                                )
                              else
                                ...asistencias.map(
                                  (item) => _FilaAsistenciaAdmin(
                                    asistencia: item,
                                    onVerDetalle: () => _mostrarDetalle(item),
                                    compacta: compacta,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      if (usarTablaCompacta) {
                        return Scrollbar(
                          controller: _tablaScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _tablaScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 1120,
                              child: contenidoTabla(compacta: true),
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: contenidoTabla(compacta: false),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  void _mostrarDetalle(_AsistenciaAdminFila asistencia) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Detalle de marcacion',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DatoDetalleAdmin(
                  etiqueta: 'Correo',
                  valor: asistencia.correo.isEmpty ? 'Sin correo' : asistencia.correo,
                ),
                _DatoDetalleAdmin(
                  etiqueta: 'Ubic. entrada',
                  valor: asistencia.ubicacionEntrada,
                ),
                _DatoDetalleAdmin(
                  etiqueta: 'Ubic. salida',
                  valor: asistencia.ubicacionSalida,
                ),
                _DatoDetalleAdmin(
                  etiqueta: 'Rostro',
                  valor: asistencia.rostro,
                ),
                const SizedBox(height: 8),
                Text(
                  'Observacion',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ColoresSistema.textoSecundario,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ColoresSistema.fondoSuave,
                    borderRadius: BorderRadius.circular(
                      MedidasSistema.radioCampo,
                    ),
                    border: Border.all(color: ColoresSistema.bordeIntermedio),
                  ),
                  child: Text(
                    asistencia.detalle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _CampoFiltroAdmin extends StatelessWidget {
  const _CampoFiltroAdmin({
    required this.icono,
    required this.texto,
  });

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        border: Border.all(color: ColoresSistema.bordeCampo),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: ColoresSistema.iconoSuave),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresSistema.textoSuave,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloColumna extends StatelessWidget {
  const _TituloColumna(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: ColoresSistema.iconoSuave,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
    );
  }
}

class _FilaAsistenciaAdmin extends StatelessWidget {
  const _FilaAsistenciaAdmin({
    required this.asistencia,
    required this.onVerDetalle,
    required this.compacta,
  });

  final _AsistenciaAdminFila asistencia;
  final VoidCallback onVerDetalle;
  final bool compacta;

  Color _colorEstado() {
    switch (asistencia.estado) {
      case 'Correcta':
        return ColoresSistema.verdeExito;
      case 'Observada':
        return const Color(0xFFB66A18);
      case 'Pendiente':
        return ColoresSistema.rojoInstitucional;
      default:
        return ColoresSistema.textoSecundario;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorEstado();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ColoresSistema.divisor),
        ),
      ),
      child: compacta
          ? Row(
              children: [
                SizedBox(
                  width: 110,
                  child: _CeldaTrabajadorTabla(asistencia: asistencia),
                ),
                SizedBox(
                  width: 150,
                  child: _TextoTabla(
                    asistencia.area.isEmpty
                        ? '--'
                        : _formatearAreaEnBloques(asistencia.area),
                    maxLines: 4,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _TextoTabla(
                    asistencia.cargo.isEmpty ? '--' : asistencia.cargo,
                  ),
                ),
                SizedBox(width: 95, child: _TextoTabla(asistencia.fecha)),
                SizedBox(width: 70, child: _TextoTabla(asistencia.entrada)),
                SizedBox(width: 70, child: _TextoTabla(asistencia.salida)),
                SizedBox(width: 75, child: _TextoTabla(asistencia.tardanza)),
                SizedBox(
                  width: 85,
                  child: _TextoTabla(asistencia.tiempoLaboral),
                ),
                SizedBox(
                  width: 110,
                  child: _ChipEstadoTabla(
                    estado: asistencia.estado,
                    colorEstado: colorEstado,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _BotonAccionTabla(onVerDetalle: onVerDetalle),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _CeldaTrabajadorTabla(asistencia: asistencia),
                ),
                Expanded(
                  flex: 3,
                  child: _TextoTabla(
                    asistencia.area.isEmpty
                        ? '--'
                        : _formatearAreaEnBloques(asistencia.area),
                    maxLines: 4,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _TextoTabla(
                    asistencia.cargo.isEmpty ? '--' : asistencia.cargo,
                  ),
                ),
                Expanded(flex: 2, child: _TextoTabla(asistencia.fecha)),
                Expanded(flex: 1, child: _TextoTabla(asistencia.entrada)),
                Expanded(flex: 1, child: _TextoTabla(asistencia.salida)),
                Expanded(flex: 1, child: _TextoTabla(asistencia.tardanza)),
                Expanded(
                  flex: 1,
                  child: _TextoTabla(asistencia.tiempoLaboral),
                ),
                Expanded(
                  flex: 2,
                  child: _ChipEstadoTabla(
                    estado: asistencia.estado,
                    colorEstado: colorEstado,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _BotonAccionTabla(onVerDetalle: onVerDetalle),
                ),
              ],
            ),
    );
  }
}

class _CeldaTrabajadorTabla extends StatelessWidget {
  const _CeldaTrabajadorTabla({
    required this.asistencia,
  });

  final _AsistenciaAdminFila asistencia;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _formatearNombreTrabajador(asistencia.trabajador),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ColoresSistema.textoTitulo,
                height: 1.25,
              ),
        ),
      ],
    );
  }
}

class _ChipEstadoTabla extends StatelessWidget {
  const _ChipEstadoTabla({
    required this.estado,
    required this.colorEstado,
  });

  final String estado;
  final Color colorEstado;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colorEstado.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
        ),
        child: Text(
          estado,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorEstado,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _BotonAccionTabla extends StatelessWidget {
  const _BotonAccionTabla({
    required this.onVerDetalle,
  });

  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: OutlinedButton.icon(
        onPressed: onVerDetalle,
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: const Text('Ver'),
      ),
    );
  }
}

class _TextoTabla extends StatelessWidget {
  const _TextoTabla(
    this.texto, {
    this.maxLines = 2,
  });

  final String texto;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColoresSistema.textoBase,
            height: 1.25,
          ),
    );
  }
}

class _DatoDetalleAdmin extends StatelessWidget {
  const _DatoDetalleAdmin({
    required this.etiqueta,
    required this.valor,
  });

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ColoresSistema.textoSecundario,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresSistema.textoBase,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrupoAsistenciaAdmin {
  _GrupoAsistenciaAdmin({
    required this.fecha,
    required this.usuarioId,
    required this.trabajador,
    required this.correo,
    required this.area,
    required this.cargo,
  });

  final String fecha;
  final String usuarioId;
  final String trabajador;
  final String correo;
  final String area;
  final String cargo;
  final List<Asistencia> marcaciones = [];
  Asistencia? entrada;
  Asistencia? salida;

  _AsistenciaAdminFila aFila() {
    final validaciones = marcaciones;
    final todasDentroZona = validaciones.every((item) => item.dentroDeZona);
    final todasConRostro = validaciones.every((item) => item.rostroValidado);
    final completa = entrada != null && salida != null;
    final observaciones = validaciones
        .map((item) => item.observacion)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList();

    final estado = !completa
        ? 'Pendiente'
        : (!todasDentroZona || !todasConRostro || observaciones.isNotEmpty)
            ? 'Observada'
            : 'Correcta';

    return _AsistenciaAdminFila(
      fecha: fecha,
      fechaOrden: entrada?.fechaHora ?? salida?.fechaHora ?? DateTime(1900),
      usuarioId: usuarioId,
      trabajador: trabajador.trim().isEmpty ? 'Trabajador sin nombre' : trabajador,
      correo: correo,
      area: area,
      cargo: cargo,
      entrada: entrada == null ? '--:--' : _formatearHora(entrada!.fechaHora),
      salida: salida == null ? '--:--' : _formatearHora(salida!.fechaHora),
      tardanza: _calcularTardanza(),
      tiempoLaboral: _calcularTiempoLaboral(),
      ubicacion: todasDentroZona ? 'Valida' : 'Observada',
      ubicacionEntrada: _estadoUbicacion(entrada),
      ubicacionSalida: _estadoUbicacion(salida),
      rostro: todasConRostro ? 'Validado' : 'Pendiente',
      estado: estado,
      detalle: observaciones.isEmpty
          ? _detallePorEstado(estado)
          : observaciones.join(' | '),
    );
  }

  String _estadoUbicacion(Asistencia? marcacion) {
    if (marcacion == null) {
      return '--';
    }
    return marcacion.dentroDeZona ? 'Valida' : 'Observada';
  }

  String _calcularTardanza() {
    if (entrada == null) {
      return '--';
    }

    final horaBase = DateTime(
      entrada!.fechaHora.year,
      entrada!.fechaHora.month,
      entrada!.fechaHora.day,
      8,
    );
    final tardanza = entrada!.fechaHora.difference(horaBase);

    if (tardanza.isNegative || tardanza == Duration.zero) {
      return '00:00';
    }

    return _formatearDuracion(tardanza);
  }

  String _calcularTiempoLaboral() {
    if (entrada == null || salida == null) {
      return '--';
    }

    final tiempo = salida!.fechaHora.difference(entrada!.fechaHora);
    if (tiempo.isNegative) {
      return '--';
    }

    return _formatearDuracion(tiempo);
  }

  String _detallePorEstado(String estado) {
    switch (estado) {
      case 'Correcta':
        return 'Entrada y salida registradas con ubicacion y rostro validados.';
      case 'Observada':
        return 'La jornada tiene validaciones parciales o requiere revision administrativa.';
      case 'Pendiente':
      default:
        return 'La jornada aun no cuenta con entrada y salida completas.';
    }
  }
}

class _AsistenciaAdminFila {
  const _AsistenciaAdminFila({
    required this.fecha,
    required this.fechaOrden,
    required this.usuarioId,
    required this.trabajador,
    required this.correo,
    required this.area,
    required this.cargo,
    required this.entrada,
    required this.salida,
    required this.tardanza,
    required this.tiempoLaboral,
    required this.ubicacion,
    required this.ubicacionEntrada,
    required this.ubicacionSalida,
    required this.rostro,
    required this.estado,
    required this.detalle,
  });

  final String fecha;
  final DateTime fechaOrden;
  final String usuarioId;
  final String trabajador;
  final String correo;
  final String area;
  final String cargo;
  final String entrada;
  final String salida;
  final String tardanza;
  final String tiempoLaboral;
  final String ubicacion;
  final String ubicacionEntrada;
  final String ubicacionSalida;
  final String rostro;
  final String estado;
  final String detalle;
}

String _formatearFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

String _formatearHora(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}

String _formatearNombreVertical(String nombre) {
  return _formatearTextoVertical(nombre);
}

String _formatearNombreTrabajador(String nombre) {
  final palabras = nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((palabra) => palabra.isNotEmpty)
      .toList();

  if (palabras.isEmpty) {
    return 'Trabajador';
  }

  final lineas = <String>[];
  var lineaActual = '';

  for (final palabra in palabras) {
    final propuesta = lineaActual.isEmpty ? palabra : '$lineaActual $palabra';
    if (propuesta.length <= 14) {
      lineaActual = propuesta;
    } else {
      if (lineaActual.isNotEmpty) {
        lineas.add(lineaActual);
      }
      lineaActual = palabra;
    }
  }

  if (lineaActual.isNotEmpty) {
    lineas.add(lineaActual);
  }

  return lineas.take(3).join('\n');
}

String _formatearTextoVertical(String texto) {
  final partes = texto
      .trim()
      .split(RegExp(r'\s+'))
      .where((parte) => parte.isNotEmpty)
      .toList();

  if (partes.isEmpty) {
    return 'Trabajador';
  }

  return partes.join('\n');
}

String _formatearAreaEnBloques(String area) {
  final palabras = area
      .trim()
      .split(RegExp(r'\s+'))
      .where((palabra) => palabra.isNotEmpty)
      .toList();

  if (palabras.isEmpty) {
    return '--';
  }

  final lineas = <String>[];
  var lineaActual = '';

  for (final palabra in palabras) {
    final propuesta = lineaActual.isEmpty ? palabra : '$lineaActual $palabra';
    if (propuesta.length <= 18) {
      lineaActual = propuesta;
    } else {
      lineas.add(lineaActual);
      lineaActual = palabra;
    }
  }

  if (lineaActual.isNotEmpty) {
    lineas.add(lineaActual);
  }

  return lineas.join('\n');
}

String _formatearDuracion(Duration duracion) {
  final horas = duracion.inHours.toString().padLeft(2, '0');
  final minutos = duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
  return '$horas:$minutos';
}
