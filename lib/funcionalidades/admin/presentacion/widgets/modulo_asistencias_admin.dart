import '../modelos/evaluacion_asistencia_admin.dart';
import '../modelos/jornada_admin.dart';
import '../modelos/regularizacion_jornada.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../../asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../../../asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../asistencias/dominio/entidades/fecha_asistencia_invalida.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../../../sedes/datos/fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../../../sedes/datos/modelos/modelo_sede.dart';
import 'contenedor_modulo_admin.dart';
import 'tarjeta_resumen_admin.dart';
import 'cuadricula_admin.dart';
import 'exportacion_asistencias_trabajador_admin.dart';
import '../modelos/informe_asistencias_trabajador.dart';

enum VistaAsistenciasAdmin { completa, registros, resumen }

class ModuloAsistenciasAdmin extends StatefulWidget {
  const ModuloAsistenciasAdmin({
    super.key,
    this.trabajadorId,
    this.repositorioAsistencias,
    this.repositorioUsuarios,
    this.cargarSedes,
    this.vista = VistaAsistenciasAdmin.completa,
  });

  final String? trabajadorId;
  final RepositorioAsistenciasImpl? repositorioAsistencias;
  final RepositorioUsuariosImpl? repositorioUsuarios;
  final Future<Map<String, String>> Function()? cargarSedes;
  final VistaAsistenciasAdmin vista;

  @override
  State<ModuloAsistenciasAdmin> createState() => _ModuloAsistenciasAdminState();
}

class _ModuloAsistenciasAdminState extends State<ModuloAsistenciasAdmin> {
  late final RepositorioAsistenciasImpl _repositorioAsistencias;
  late final RepositorioUsuariosImpl _repositorioUsuarios;
  late Future<void> _cargaAsistencias;
  final List<Asistencia> _marcacionesCargadas = [];
  List<_AsistenciaAdminFila> _filasCargadas = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _ultimoDocumento;
  Map<String, Usuario> _usuariosPorId = {};
  Map<String, String> _sedesPorId = {};
  bool _hayMasAsistencias = true;
  bool _cargandoMas = false;
  String? _errorCargarMas;
  int _versionConsulta = 0;

  final TextEditingController _busquedaController = TextEditingController();
  final ScrollController _tablaScrollController = ScrollController();

  String _busqueda = '';
  String _estadoSeleccionado = 'Todos';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  static const List<String> _estados = <String>[
    'Todos',
    'Correcta',
    'Observada',
    'Pendiente',
  ];

  @override
  void initState() {
    super.initState();
    _repositorioAsistencias =
        widget.repositorioAsistencias ??
        RepositorioAsistenciasImpl(FuenteDatosAsistenciasFirestore());
    _repositorioUsuarios =
        widget.repositorioUsuarios ??
        RepositorioUsuariosImpl(FuenteDatosUsuariosFirestore());
    _cargaAsistencias = _cargarPaginaInicial();
  }

  @override
  void didUpdateWidget(covariant ModuloAsistenciasAdmin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trabajadorId != widget.trabajadorId) {
      _busquedaController.clear();
      _busqueda = '';
      _estadoSeleccionado = 'Todos';
      _fechaInicio = null;
      _fechaFin = null;
      _recargarAsistencias();
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _tablaScrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarPaginaInicial() async {
    final version = ++_versionConsulta;
    final trabajadorId = widget.trabajadorId?.trim();
    if (trabajadorId != null && trabajadorId.isEmpty) {
      throw ArgumentError(
        'El identificador del trabajador no puede estar vacío.',
      );
    }
    _cargandoMas = false;
    _errorCargarMas = null;
    final List<Usuario> usuarios;
    if (trabajadorId == null) {
      usuarios = await _repositorioUsuarios.obtenerUsuarios();
    } else {
      final usuario = await _repositorioUsuarios.obtenerUsuarioPorId(
        trabajadorId,
      );
      usuarios = usuario == null ? [] : [usuario];
    }
    final sedes = widget.cargarSedes != null
        ? await widget.cargarSedes!()
        : {
            for (final sede in await FuenteDatosSedesFirestore().obtenerSedes())
              sede.key: ModeloSede.desdeMapa(sede.value, sede.key).nombre,
          };
    if (!mounted || version != _versionConsulta) return;
    _sedesPorId = sedes;
    _usuariosPorId = {for (final usuario in usuarios) usuario.id: usuario};
    if (trabajadorId != null) {
      final marcaciones = await _repositorioAsistencias
          .obtenerAsistenciasPorUsuario(trabajadorId);
      if (!mounted || version != _versionConsulta) return;
      final inicio = _fechaInicio == null
          ? null
          : DateTime(
              _fechaInicio!.year,
              _fechaInicio!.month,
              _fechaInicio!.day,
            );
      final fin = _fechaFin == null
          ? null
          : DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day + 1);
      _marcacionesCargadas
        ..clear()
        ..addAll(
          marcaciones.where(
            (a) =>
                a.usuarioId == trabajadorId &&
                (inicio == null || !a.fechaHora.isBefore(inicio)) &&
                (fin == null || a.fechaHora.isBefore(fin)),
          ),
        );
      _ultimoDocumento = null;
      _hayMasAsistencias = false;
      _filasCargadas = _agruparMarcaciones(_marcacionesCargadas);
      return;
    }
    final pagina = await _repositorioAsistencias.obtenerPaginaAsistencias(
      desde: _fechaInicio == null
          ? null
          : DateTime(
              _fechaInicio!.year,
              _fechaInicio!.month,
              _fechaInicio!.day,
            ),
      hastaExclusiva: _fechaFin == null
          ? null
          : DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day + 1),
    );
    if (!mounted || version != _versionConsulta) return;
    _marcacionesCargadas
      ..clear()
      ..addAll(pagina.asistencias);
    _ultimoDocumento = pagina.ultimoDocumento;
    _hayMasAsistencias = pagina.hayMas;
    _filasCargadas = _agruparMarcaciones(_marcacionesCargadas);
  }

  Future<void> _cargarSiguientePagina() async {
    if (widget.trabajadorId != null) return;
    if (_cargandoMas || !_hayMasAsistencias) return;
    final version = _versionConsulta;
    setState(() {
      _cargandoMas = true;
      _errorCargarMas = null;
    });
    try {
      final pagina = await _repositorioAsistencias.obtenerPaginaAsistencias(
        desde: _fechaInicio == null
            ? null
            : DateTime(
                _fechaInicio!.year,
                _fechaInicio!.month,
                _fechaInicio!.day,
              ),
        hastaExclusiva: _fechaFin == null
            ? null
            : DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day + 1),
        despuesDe: _ultimoDocumento,
      );
      if (!mounted || version != _versionConsulta) return;
      setState(() {
        _marcacionesCargadas.addAll(pagina.asistencias);
        _ultimoDocumento = pagina.ultimoDocumento;
        _hayMasAsistencias = pagina.hayMas;
        _filasCargadas = _agruparMarcaciones(_marcacionesCargadas);
        _cargandoMas = false;
      });
    } catch (_) {
      if (!mounted || version != _versionConsulta) return;
      setState(() {
        _cargandoMas = false;
        _errorCargarMas =
            'No se pudo cargar la siguiente página. Revisa la conexión e intenta nuevamente.';
      });
    }
  }

  List<_AsistenciaAdminFila> _agruparMarcaciones(List<Asistencia> asistencias) {
    final grupos = <String, _GrupoAsistenciaAdmin>{};

    for (final asistencia in asistencias) {
      final fecha = _formatearFecha(asistencia.fechaHora);
      final clave = claveJornadaAdmin(asistencia);
      final usuario = _usuariosPorId[asistencia.usuarioId];

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
          sedesPorId: _sedesPorId,
        ),
      );

      grupo.marcaciones.add(asistencia);
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
      final coincideEstado =
          _estadoSeleccionado == 'Todos' ||
          asistencia.estado == _estadoSeleccionado;

      final coincideBusqueda =
          consulta.isEmpty ||
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
      _marcacionesCargadas.clear();
      _filasCargadas = [];
      _ultimoDocumento = null;
      _hayMasAsistencias = true;
      _cargaAsistencias = _cargarPaginaInicial();
    });
  }

  void _limpiarFechas() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _marcacionesCargadas.clear();
      _filasCargadas = [];
      _ultimoDocumento = null;
      _hayMasAsistencias = true;
      _cargaAsistencias = _cargarPaginaInicial();
    });
  }

  Future<void> _seleccionarFecha({required bool inicio}) async {
    final actual = inicio ? _fechaInicio : _fechaFin;
    final otra = inicio ? _fechaFin : _fechaInicio;
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? otra ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null || !mounted) return;
    final dia = DateTime(
      seleccionada.year,
      seleccionada.month,
      seleccionada.day,
    );
    if (otra != null && (inicio ? dia.isAfter(otra) : dia.isBefore(otra))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inicio
                ? 'La fecha de inicio no puede ser posterior a la fecha de fin.'
                : 'La fecha de fin no puede ser anterior a la fecha de inicio.',
          ),
        ),
      );
      return;
    }
    setState(() {
      if (inicio) {
        _fechaInicio = dia;
      } else {
        _fechaFin = dia;
      }
      _marcacionesCargadas.clear();
      _filasCargadas = [];
      _ultimoDocumento = null;
      _hayMasAsistencias = true;
      _cargaAsistencias = _cargarPaginaInicial();
    });
  }

  String _textoFecha(DateTime? fecha, String vacio) {
    if (fecha == null) return vacio;
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
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
                  snapshot.error is FechaAsistenciaInvalida
                      ? snapshot.error.toString()
                      : 'Ocurrio un problema al consultar las asistencias reales. Revisa permisos, conexion o indices de Firestore.',
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

        final todas = _filasCargadas;
        final asistencias = _filtrarAsistencias(todas);
        final correctas = todas
            .where((item) => item.estado == 'Correcta')
            .length;
        final observadas = todas
            .where((item) => item.estado == 'Observada')
            .length;
        final pendientes = todas
            .where((item) => item.estado == 'Pendiente')
            .length;

        final tarjetasResumen = CuadriculaAdmin(
          maximoColumnas: 4,
          children: [
            TarjetaResumenAdmin(
              titulo: 'Marcaciones cargadas',
              compacta: widget.vista == VistaAsistenciasAdmin.resumen,
              valor: '${_marcacionesCargadas.length}',
              detalle: widget.vista == VistaAsistenciasAdmin.resumen
                  ? '${todas.length} ${todas.length == 1 ? 'jornada registrada' : 'jornadas registradas'}'
                  : '${todas.length} jornadas agrupadas por trabajador y fecha.',
              colorAcento: ColoresPanel.azul,
              icono: Icons.fact_check_outlined,
            ),
            TarjetaResumenAdmin(
              titulo: 'Jornadas correctas',
              compacta: widget.vista == VistaAsistenciasAdmin.resumen,
              valor: '$correctas',
              detalle: widget.vista == VistaAsistenciasAdmin.resumen
                  ? 'Completas y sin observaciones'
                  : 'Entrada y salida completas sin observacion.',
              colorAcento: ColoresSistema.verdeExito,
              icono: Icons.verified_outlined,
            ),
            TarjetaResumenAdmin(
              titulo: 'Jornadas observadas',
              compacta: widget.vista == VistaAsistenciasAdmin.resumen,
              valor: '$observadas',
              detalle: widget.vista == VistaAsistenciasAdmin.resumen
                  ? 'Requieren revisión'
                  : 'Casos con validaciones parciales o alertas.',
              colorAcento: const Color(0xFFB66A18),
              icono: Icons.warning_amber_outlined,
            ),
            TarjetaResumenAdmin(
              titulo: 'Pendientes',
              compacta: widget.vista == VistaAsistenciasAdmin.resumen,
              valor: '$pendientes',
              detalle: widget.vista == VistaAsistenciasAdmin.resumen
                  ? 'Jornadas por completar'
                  : 'Jornadas incompletas o aun sin cierre.',
              colorAcento: ColoresSistema.verdeInstitucional,
              icono: Icons.pending_actions_outlined,
            ),
          ],
        );
        if (widget.vista == VistaAsistenciasAdmin.resumen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de asistencias',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Historial completo del trabajador',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _recargarAsistencias,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar resumen'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              tarjetasResumen,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.vista == VistaAsistenciasAdmin.completa) ...[
              tarjetasResumen,
              const SizedBox(height: 16),
            ],
            ContenedorModuloAdmin(
              titulo: 'Consulta de asistencias',
              descripcion: '',
              accionCabecera:
                  widget.trabajadorId != null &&
                      _usuariosPorId[widget.trabajadorId] != null
                  ? ExportacionAsistenciasTrabajadorAdmin(
                      key: ValueKey(widget.trabajadorId),
                      informe: InformeAsistenciasTrabajador(
                        usuario: _usuariosPorId[widget.trabajadorId]!,
                        marcaciones: asistencias
                            .expand((fila) => fila.originales)
                            .toList(),
                        desde: _fechaInicio,
                        hasta: _fechaFin,
                        estado: _estadoSeleccionado,
                      ).informe,
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ColoresSistema.bordeSuave),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final ancho = constraints.maxWidth;
                        final escalaFiltros =
                            (MediaQuery.textScalerOf(context).scale(15) / 15)
                                .clamp(1.0, 2.0);
                        final anchoFecha = ancho < 600
                            ? ancho
                            : (190.0 * escalaFiltros)
                                  .clamp(0.0, ancho)
                                  .toDouble();
                        final anchoBusqueda = ancho < 600
                            ? ancho
                            : (360.0 * escalaFiltros)
                                  .clamp(0.0, ancho)
                                  .toDouble();

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (widget.trabajadorId == null)
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
                                    labelText: 'Trabajador',
                                    hintText: 'Buscar por nombre o correo...',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: ancho < 600
                                  ? ancho
                                  : (160.0 * escalaFiltros)
                                        .clamp(0.0, ancho)
                                        .toDouble(),
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
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
                            SizedBox(
                              width: anchoFecha,
                              child: _CampoFiltroAdmin(
                                icono: Icons.calendar_today_outlined,
                                texto: _textoFecha(
                                  _fechaInicio,
                                  'Fecha inicio',
                                ),
                                onTap: () => _seleccionarFecha(inicio: true),
                              ),
                            ),
                            SizedBox(
                              width: anchoFecha,
                              child: _CampoFiltroAdmin(
                                icono: Icons.event_outlined,
                                texto: _textoFecha(_fechaFin, 'Fecha fin'),
                                onTap: () => _seleccionarFecha(inicio: false),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Limpiar fechas',
                              onPressed:
                                  _fechaInicio == null && _fechaFin == null
                                  ? null
                                  : _limpiarFechas,
                              icon: const Icon(Icons.filter_alt_off_outlined),
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
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final escala =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final usarTablaCompacta =
                          constraints.maxWidth < 1200 * escala;

                      final continuas = asistencias
                          .where((fila) => fila.esContinua)
                          .toList();
                      final partidas = asistencias
                          .where((fila) => !fila.esContinua)
                          .toList();

                      Widget tablaDeJornadas(
                        List<_AsistenciaAdminFila> filas, {
                        required bool continua,
                        required bool compacta,
                      }) {
                        final etiquetas = continua
                            ? ['Entrada', 'Salida']
                            : [
                                'Entrada\nMañana',
                                'Salida\nMañana',
                                'Entrada\nTarde',
                                'Salida\nTarde',
                              ];
                        return Container(
                          decoration: BoxDecoration(
                            color: ColoresSistema.fondoSuave,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ColoresSistema.bordeIntermedio,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0F5F7),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (widget.trabajadorId == null)
                                      Expanded(
                                        flex: compacta ? 120 : 2,
                                        child: const _TituloColumna(
                                          'Trabajador',
                                        ),
                                      ),
                                    Expanded(
                                      flex: compacta ? 95 : 2,
                                      child: const _TituloColumna('Fecha'),
                                    ),
                                    for (final etiqueta in etiquetas)
                                      Expanded(
                                        flex: compacta ? 85 : 1,
                                        child: _TituloColumna(etiqueta),
                                      ),
                                    Expanded(
                                      flex: compacta ? 75 : 1,
                                      child: const _TituloColumna('Tardanza'),
                                    ),
                                    Expanded(
                                      flex: compacta ? 85 : 1,
                                      child: const _TituloColumna(
                                        'T. laborado',
                                      ),
                                    ),
                                    Expanded(
                                      flex: compacta ? 110 : 2,
                                      child: const _TituloColumna('Estado'),
                                    ),
                                    if (compacta)
                                      const Expanded(
                                        flex: 110,
                                        child: _TituloColumna('Acción'),
                                      )
                                    else
                                      const SizedBox(
                                        width: 120,
                                        child: _TituloColumna('Acción'),
                                      ),
                                  ],
                                ),
                              ),
                              for (final fila in filas)
                                _FilaAsistenciaAdmin(
                                  asistencia: fila,
                                  compacta: compacta,
                                  mostrarTrabajador:
                                      widget.trabajadorId == null,
                                  onRegularizar: () =>
                                      _mostrarDialogoRegularizacion(fila),
                                ),
                            ],
                          ),
                        );
                      }

                      Widget contenidoTabla({required bool compacta}) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (asistencias.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                todas.isEmpty
                                    ? 'Aun no hay marcaciones registradas en Firestore.'
                                    : 'No se encontraron marcaciones con los filtros actuales.',
                              ),
                            ),
                          if (continuas.isNotEmpty) ...[
                            tablaDeJornadas(
                              continuas,
                              continua: true,
                              compacta: compacta,
                            ),
                          ],
                          if (partidas.isNotEmpty) ...[
                            if (continuas.isNotEmpty)
                              const SizedBox(height: 20),
                            tablaDeJornadas(
                              partidas,
                              continua: false,
                              compacta: compacta,
                            ),
                          ],
                          if (_errorCargarMas != null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _errorCargarMas!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      );
                      if (usarTablaCompacta) {
                        final minimo =
                            ((partidas.isEmpty ? 820.0 : 1080.0) -
                                (widget.trabajadorId == null ? 0 : 120)) *
                            escala.clamp(1.0, 2.0);
                        final anchoTabla = constraints.maxWidth < minimo
                            ? minimo
                            : constraints.maxWidth;
                        return Scrollbar(
                          controller: _tablaScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _tablaScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: anchoTabla,
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
                  if (_hayMasAsistencias) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _cargandoMas ? null : _cargarSiguientePagina,
                        icon: _cargandoMas
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(
                          _cargandoMas
                              ? 'Cargando...'
                              : 'Cargar más asistencias',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoRegularizacion(
    _AsistenciaAdminFila asistencia,
  ) async {
    if (widget.trabajadorId != null &&
        asistencia.usuarioId != widget.trabajadorId!.trim()) {
      return;
    }
    final actualizado = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoRegularizacionAsistencia(
        asistencia: asistencia,
        repositorioAsistencias: _repositorioAsistencias,
        sedesPorId: _sedesPorId,
      ),
    );

    if (!mounted || actualizado != true) return;

    _recargarAsistencias();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La jornada fue regularizada correctamente.'),
      ),
    );
  }
}

class _DialogoRegularizacionAsistencia extends StatefulWidget {
  const _DialogoRegularizacionAsistencia({
    required this.asistencia,
    required this.repositorioAsistencias,
    required this.sedesPorId,
  });

  final _AsistenciaAdminFila asistencia;
  final RepositorioAsistenciasImpl repositorioAsistencias;
  final Map<String, String> sedesPorId;

  @override
  State<_DialogoRegularizacionAsistencia> createState() =>
      _DialogoRegularizacionAsistenciaState();
}

class _DialogoRegularizacionAsistenciaState
    extends State<_DialogoRegularizacionAsistencia> {
  RegularizacionJornada? _jornada;
  final _horas = <String, TextEditingController>{};
  final _sedesNuevas = <String, String>{};
  final _motivo = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    try {
      final jornada = RegularizacionJornada(widget.asistencia.originales);
      _jornada = jornada;
      for (final campo in jornada.campos) {
        _horas[jornada.clave(campo)] = TextEditingController(
          text: jornada.texto(campo),
        );
      }
    } on FormatException catch (error) {
      _error = error.message;
    }
  }

  @override
  void dispose() {
    _motivo.dispose();
    for (final controller in _horas.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || _jornada == null) return;
    try {
      final cambios = _jornada!.preparar({
        for (final e in _horas.entries) e.key: e.value.text,
      }, sedesNuevas: _sedesNuevas);
      setState(() {
        _guardando = true;
        _error = null;
      });
      await widget.repositorioAsistencias.regularizarJornada(
        originales: widget.asistencia.originales,
        actualizadas: cambios,
        motivo: _motivo.text,
        administradorId:
            FirebaseAuth.instance.currentUser?.uid ??
            (throw StateError('No hay una sesión administrativa activa.')),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = error.message;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error =
            'No se pudo confirmar el guardado. Cierra el diálogo y actualiza la lista antes de reintentar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final jornada = _jornada;
    final sedes = widget.asistencia.originales.map((m) => m.sedeId).toSet();
    return PopScope(
      canPop: !_guardando,
      child: AlertDialog(
        title: const Text('Regularizar jornada'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (jornada != null) ...[
                  if (!jornada.horarioConfirmado)
                    const Text(
                      'Jornada antigua sin horario identificado: solo se pueden corregir marcas existentes, conservando sus datos.',
                    ),
                  for (final campo in jornada.campos) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _horas[jornada.clave(campo)],
                      enabled:
                          !_guardando &&
                          (jornada.horarioConfirmado ||
                              jornada.existente(campo) != null),
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: campo.etiqueta.replaceFirst(
                          'Registrar ',
                          '',
                        ),
                        hintText: 'HH:mm',
                      ),
                    ),
                    if (sedes.length > 1 && jornada.existente(campo) == null)
                      DropdownButtonFormField<String>(
                        initialValue: _sedesNuevas[jornada.clave(campo)],
                        decoration: const InputDecoration(
                          labelText: 'Sede de la nueva marcación',
                        ),
                        items: [
                          for (final sede in sedes)
                            DropdownMenuItem(
                              value: sede,
                              child: Text(widget.sedesPorId[sede] ?? sede),
                            ),
                        ],
                        onChanged: _guardando
                            ? null
                            : (valor) {
                                if (valor != null) {
                                  setState(
                                    () => _sedesNuevas[jornada.clave(campo)] =
                                        valor,
                                  );
                                }
                              },
                      ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Formato de 24 horas, por ejemplo 08:30 o 18:30. No borres horas existentes.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _motivo,
                    enabled: !_guardando,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de la corrección (obligatorio)',
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: _guardando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _guardando || jornada == null ? null : _guardar,
            child: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}

class _CampoFiltroAdmin extends StatelessWidget {
  const _CampoFiltroAdmin({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresSistema.fondoTarjeta,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).width < 600 ? 44 : 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
              if (texto != 'Fecha inicio' && texto != 'Fecha fin')
                const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
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
        fontSize: 13,
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
    required this.onRegularizar,
    required this.compacta,
    required this.mostrarTrabajador,
  });

  final _AsistenciaAdminFila asistencia;
  final VoidCallback onRegularizar;
  final bool compacta;
  final bool mostrarTrabajador;

  Color _colorEstado() {
    switch (asistencia.estado) {
      case 'Correcta':
        return const Color(0xFF146C43);
      case 'Observada':
        return const Color(0xFF915012);
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ColoresSistema.divisor)),
      ),
      child: Row(
        children: [
          if (mostrarTrabajador)
            Expanded(
              flex: compacta ? 120 : 2,
              child: _CeldaTrabajadorTabla(asistencia: asistencia),
            ),
          Expanded(
            flex: compacta ? 95 : 2,
            child: _TextoTabla(asistencia.fecha),
          ),
          Expanded(
            flex: compacta ? 85 : 1,
            child: _TextoTabla(asistencia.entradaManana),
          ),
          Expanded(
            flex: compacta ? 85 : 1,
            child: _TextoTabla(asistencia.salidaManana),
          ),
          if (!asistencia.esContinua) ...[
            Expanded(
              flex: compacta ? 85 : 1,
              child: _TextoTabla(asistencia.entradaTarde),
            ),
            Expanded(
              flex: compacta ? 85 : 1,
              child: _TextoTabla(asistencia.salidaTarde),
            ),
          ],
          Expanded(
            flex: compacta ? 75 : 1,
            child: _TextoTabla(asistencia.tardanza),
          ),
          Expanded(
            flex: compacta ? 85 : 1,
            child: _TextoTabla(asistencia.tiempoLaboral),
          ),
          Expanded(
            flex: compacta ? 110 : 2,
            child: _ChipEstadoTabla(
              estado: asistencia.estado,
              colorEstado: colorEstado,
            ),
          ),
          if (compacta)
            Expanded(
              flex: 110,
              child: _BotonAccionTabla(onRegularizar: onRegularizar),
            )
          else
            SizedBox(
              width: 120,
              child: _BotonAccionTabla(onRegularizar: onRegularizar),
            ),
        ],
      ),
    );
  }
}

class _CeldaTrabajadorTabla extends StatelessWidget {
  const _CeldaTrabajadorTabla({required this.asistencia});

  final _AsistenciaAdminFila asistencia;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: asistencia.trabajador,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            asistencia.trabajador,
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
      ),
    );
  }
}

class _ChipEstadoTabla extends StatelessWidget {
  const _ChipEstadoTabla({required this.estado, required this.colorEstado});

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
  const _BotonAccionTabla({required this.onRegularizar});

  final VoidCallback onRegularizar;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: OutlinedButton.icon(
        onPressed: onRegularizar,
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Regularizar'),
      ),
    );
  }
}

class _TextoTabla extends StatelessWidget {
  const _TextoTabla(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: ColoresSistema.textoBase,
        height: 1.25,
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
    required this.sedesPorId,
  });

  final String fecha;
  final String usuarioId;
  final String trabajador;
  final String correo;
  final String area;
  final String cargo;
  final Map<String, String> sedesPorId;
  final List<Asistencia> marcaciones = [];

  _AsistenciaAdminFila aFila() {
    final fechaBase = marcaciones.isEmpty
        ? DateTime(1900)
        : DateTime(
            marcaciones.first.fechaHora.year,
            marcaciones.first.fechaHora.month,
            marcaciones.first.fechaHora.day,
          );
    final evaluacion = EvaluacionAsistenciaAdmin(marcaciones, fechaBase);
    final resumen = evaluacion.resumen;
    final fechaOrden = marcaciones.isEmpty
        ? DateTime(1900)
        : marcaciones
              .map((item) => item.fechaHora)
              .reduce(
                (actual, siguiente) =>
                    actual.isAfter(siguiente) ? actual : siguiente,
              );

    return _AsistenciaAdminFila(
      fecha: fecha,
      fechaOrden: fechaOrden,
      usuarioId: usuarioId,
      trabajador: trabajador.trim().isEmpty
          ? 'Trabajador sin nombre'
          : trabajador,
      correo: correo,
      area: area,
      cargo: cargo,
      esContinua: resumen.esJornadaContinua,
      entradaManana: _formatearHoraMarcacion(resumen.manana.entradaMarcada),
      salidaManana: _formatearHoraMarcacion(resumen.manana.salidaMarcada),
      entradaTarde: _formatearHoraMarcacion(resumen.tarde.entradaMarcada),
      salidaTarde: _formatearHoraMarcacion(resumen.tarde.salidaMarcada),
      originales: List.unmodifiable(marcaciones),
      entradaMananaRef: resumen.manana.entradaMarcada,
      salidaMananaRef: resumen.manana.salidaMarcada,
      entradaTardeRef: resumen.tarde.entradaMarcada,
      salidaTardeRef: resumen.tarde.salidaMarcada,
      tardanza: _formatearDuracionOpcional(resumen.tardanzaTotal),
      tiempoLaboral: _formatearDuracionOpcional(resumen.tiempoLaborado),
      ubicacionEntradaManana: _estadoUbicacion(resumen.manana.entradaMarcada),
      ubicacionSalidaManana: _estadoUbicacion(resumen.manana.salidaMarcada),
      ubicacionEntradaTarde: _estadoUbicacion(resumen.tarde.entradaMarcada),
      ubicacionSalidaTarde: _estadoUbicacion(resumen.tarde.salidaMarcada),
      rostro: evaluacion.todasConRostro ? 'Validado' : 'Pendiente',
      estado: evaluacion.estado,
      detalle: evaluacion.detalle,
    );
  }

  String _estadoUbicacion(Asistencia? marcacion) {
    if (marcacion == null) {
      return '--';
    }
    final estado = marcacion.dentroDeZona ? 'Válida' : 'Observada';
    return '$estado · Sede: ${sedesPorId[marcacion.sedeId] ?? marcacion.sedeId}';
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
    required this.esContinua,
    required this.entradaManana,
    required this.salidaManana,
    required this.entradaTarde,
    required this.salidaTarde,
    required this.originales,
    required this.entradaMananaRef,
    required this.salidaMananaRef,
    required this.entradaTardeRef,
    required this.salidaTardeRef,
    required this.tardanza,
    required this.tiempoLaboral,
    required this.ubicacionEntradaManana,
    required this.ubicacionSalidaManana,
    required this.ubicacionEntradaTarde,
    required this.ubicacionSalidaTarde,
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
  final bool esContinua;
  final String entradaManana;
  final String salidaManana;
  final String entradaTarde;
  final String salidaTarde;
  final List<Asistencia> originales;
  final Asistencia? entradaMananaRef;
  final Asistencia? salidaMananaRef;
  final Asistencia? entradaTardeRef;
  final Asistencia? salidaTardeRef;
  final String tardanza;
  final String tiempoLaboral;
  final String ubicacionEntradaManana;
  final String ubicacionSalidaManana;
  final String ubicacionEntradaTarde;
  final String ubicacionSalidaTarde;
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

String _formatearDuracion(Duration duracion) {
  final horas = duracion.inHours.toString().padLeft(2, '0');
  final minutos = duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
  return '$horas:$minutos';
}

String _formatearHoraMarcacion(Asistencia? marcacion) {
  if (marcacion == null) {
    return '--:--';
  }
  return _formatearHora(marcacion.fechaHora);
}

String _formatearDuracionOpcional(Duration? duracion) {
  if (duracion == null) {
    return '--';
  }
  return _formatearDuracion(duracion);
}
