import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../alertas/datos/fuentes_datos/fuente_datos_alertas_firestore.dart';
import '../../../alertas/datos/repositorios/repositorio_alertas_impl.dart';
import '../../../alertas/dominio/casos_de_uso/obtener_alertas_por_usuario.dart';
import '../../../alertas/dominio/casos_de_uso/registrar_alerta.dart';
import '../../../alertas/dominio/entidades/alerta.dart';
import '../../../alertas/dominio/entidades/tipo_alerta.dart';
import '../../../geolocalizacion/datos/fuentes_datos/fuente_datos_geolocalizacion_dispositivo.dart';
import '../../../geolocalizacion/datos/repositorios/repositorio_geolocalizacion_impl.dart';
import '../../../geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import '../../../reconocimiento_facial/datos/fuentes_datos/fuente_datos_detector_rostro_mlkit.dart';
import '../../../reconocimiento_facial/datos/fuentes_datos/fuente_datos_evidencia_facial_storage.dart';
import '../../../reconocimiento_facial/datos/repositorios/repositorio_evidencia_facial_impl.dart';
import '../../../reconocimiento_facial/datos/repositorios/repositorio_reconocimiento_facial_impl.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/subir_evidencia_facial.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import '../../../reconocimiento_facial/presentacion/paginas/pagina_validacion_facial.dart';
import '../../../sedes/datos/fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../../../sedes/datos/repositorios/repositorio_sedes_impl.dart';
import '../../../sedes/dominio/casos_de_uso/obtener_sede_por_id.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../../usuarios/dominio/casos_de_uso/obtener_usuario_por_id.dart';
import '../../datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../../datos/repositorios/repositorio_asistencias_impl.dart';
import '../../dominio/casos_de_uso/crear_perfil_trabajador_demo.dart';
import '../../dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import '../../dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import '../../dominio/casos_de_uso/registrar_asistencia.dart';
import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../controladores/controlador_asistencia.dart';

// Esta pantalla ahora agrupa la experiencia del trabajador en modulos.
// La logica principal sigue en el controlador, pero la UI se separa
// para evitar una vista unica demasiado larga y dificil de recorrer.
class PaginaInicio extends StatefulWidget {
  const PaginaInicio({
    super.key,
    this.usuarioAutenticado,
    this.onCerrarSesion,
  });

  final User? usuarioAutenticado;
  final Future<void> Function()? onCerrarSesion;

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  late final ControladorAsistencia _controlador;
  late final RepositorioReconocimientoFacialImpl _repositorioReconocimientoFacial;
  int _indice = 0;

  @override
  void initState() {
    super.initState();

    final fuenteDatosAsistencias = FuenteDatosAsistenciasFirestore();
    final repositorioAsistencias =
        RepositorioAsistenciasImpl(fuenteDatosAsistencias);
    final fuenteDatosUsuarios = FuenteDatosUsuariosFirestore();
    final repositorioUsuarios = RepositorioUsuariosImpl(fuenteDatosUsuarios);
    final fuenteDatosSedes = FuenteDatosSedesFirestore();
    final repositorioSedes = RepositorioSedesImpl(fuenteDatosSedes);
    final fuenteDatosGeolocalizacion = FuenteDatosGeolocalizacionDispositivo();
    final repositorioGeolocalizacion =
        RepositorioGeolocalizacionImpl(fuenteDatosGeolocalizacion);
    final fuenteDatosAlertas = FuenteDatosAlertasFirestore();
    final repositorioAlertas = RepositorioAlertasImpl(fuenteDatosAlertas);
    final fuenteDatosEvidenciaFacial = FuenteDatosEvidenciaFacialStorage();
    final repositorioEvidenciaFacial =
        RepositorioEvidenciaFacialImpl(fuenteDatosEvidenciaFacial);
    final fuenteDatosRostro = FuenteDatosDetectorRostroMlkit();
    _repositorioReconocimientoFacial =
        RepositorioReconocimientoFacialImpl(fuenteDatosRostro);

    _controlador = ControladorAsistencia(
      obtenerAlertasPorUsuario: ObtenerAlertasPorUsuario(repositorioAlertas),
      registrarAlerta: RegistrarAlerta(repositorioAlertas),
      registrarAsistencia: RegistrarAsistencia(repositorioAsistencias),
      crearPerfilTrabajadorDemo: CrearPerfilTrabajadorDemo(
        repositorioUsuarios: repositorioUsuarios,
        repositorioSedes: repositorioSedes,
      ),
      obtenerAsistenciasPorUsuario:
          ObtenerAsistenciasPorUsuario(repositorioAsistencias),
      obtenerPerfilTrabajadorActual: ObtenerPerfilTrabajadorActual(
        obtenerUsuarioPorId: ObtenerUsuarioPorId(repositorioUsuarios),
        obtenerSedePorId: ObtenerSedePorId(repositorioSedes),
      ),
      subirEvidenciaFacial: SubirEvidenciaFacial(repositorioEvidenciaFacial),
      validarRostroCapturado:
          ValidarRostroCapturado(_repositorioReconocimientoFacial),
      validarUbicacionActual:
          ValidarUbicacionActual(repositorioGeolocalizacion),
      usuarioIdAutenticado: widget.usuarioAutenticado?.uid ?? 'usuario_demo',
      nombreAutenticado: widget.usuarioAutenticado?.displayName,
      correoAutenticado: widget.usuarioAutenticado?.email,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controlador.cargarPerfil();
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    _repositorioReconocimientoFacial.cerrar();
    super.dispose();
  }

  Future<void> _abrirValidacionFacial() async {
    final rutaImagen = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PaginaValidacionFacial()),
    );

    if (!mounted || rutaImagen == null || rutaImagen.isEmpty) {
      return;
    }

    await _controlador.validarRostroConImagen(rutaImagen);
  }

  Future<void> _seleccionarRangoHistorial() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 2),
      lastDate: DateTime(ahora.year + 1),
      initialDateRange: _controlador.rangoHistorialSeleccionado ??
          DateTimeRange(
            start: DateTime(ahora.year, ahora.month, ahora.day),
            end: DateTime(ahora.year, ahora.month, ahora.day),
          ),
      helpText: 'Seleccionar rango del historial',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
    );

    if (rango != null) {
      _controlador.actualizarRangoHistorial(rango);
    }
  }

  Future<void> _abrirProcesoMarcacion(TipoMarcacion tipoMarcacion) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaProcesoMarcacion(
        controlador: _controlador,
        tipoMarcacion: tipoMarcacion,
        onValidarRostro: _abrirValidacionFacial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) {
        final perfil = _controlador.perfilActual;

        final vistas = <Widget>[
          _ModuloInicio(controlador: _controlador),
          _ModuloAsistencia(
            controlador: _controlador,
            onAbrirProcesoMarcacion: _abrirProcesoMarcacion,
          ),
          _ModuloHistorial(
            controlador: _controlador,
            onSeleccionarRango: _seleccionarRangoHistorial,
          ),
          _ModuloAlertas(controlador: _controlador),
          _ModuloPerfil(
            controlador: _controlador,
            correoSesion: widget.usuarioAutenticado?.email,
            onCerrarSesion: widget.onCerrarSesion,
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(_titulos[_indice]),
            actions: [
              IconButton(
                tooltip: 'Actualizar informacion',
                onPressed: _controlador.cargandoPerfil
                    ? null
                    : () => _controlador.cargarPerfil(),
                icon: const Icon(Icons.refresh),
              ),
              if (widget.onCerrarSesion != null)
                IconButton(
                  tooltip: 'Cerrar sesion',
                  onPressed: widget.onCerrarSesion,
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _CabeceraTrabajador(
                  nombre: perfil?.nombreCompleto ??
                      widget.usuarioAutenticado?.displayName ??
                      'Trabajador',
                  sede: perfil?.nombreSede ?? 'Sede pendiente',
                  fecha: _formatearFecha(_controlador.fechaHoraActual),
                  hora: _formatearHora(_controlador.fechaHoraActual),
                ),
                Expanded(child: vistas[_indice]),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _indice,
            onDestinationSelected: (indice) {
              setState(() {
                _indice = indice;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.how_to_reg_outlined),
                selectedIcon: Icon(Icons.how_to_reg),
                label: 'Asistencia',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Historial',
              ),
              NavigationDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning_amber_rounded),
                label: 'Alertas',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}

const List<String> _titulos = [
  'Inicio',
  'Marcar asistencia',
  'Historial',
  'Alertas',
  'Mi perfil',
];

class _ModuloInicio extends StatelessWidget {
  const _ModuloInicio({required this.controlador});
  final ControladorAsistencia controlador;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        if (controlador.cargandoPerfil)
          const _TarjetaCarga(
            mensaje: 'Cargando perfil del trabajador desde Firestore...',
          ),
        if (controlador.mensajePerfil != null) ...[
          _TarjetaMensaje(
            mensaje: controlador.mensajePerfil!,
            color: Colors.orange,
            icono: Icons.info_outline,
          ),
          const SizedBox(height: 12),
        ],
        if (controlador.mensajeEstado != null) ...[
          _TarjetaMensaje(
            mensaje: controlador.mensajeEstado!,
            color: _colorMensaje(controlador.mensajeEstado!),
            icono: _iconoMensaje(controlador.mensajeEstado!),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen general del dia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicio ahora queda como tablero rapido. El proceso real de marcacion vive en el modulo Asistencia.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DatoResumen(
                      titulo: 'Entrada',
                      valor: controlador.ultimaEntrada == null
                          ? 'Pendiente'
                          : _formatearFechaHora(
                              controlador.ultimaEntrada!.fechaHora,
                            ),
                      color: Colors.green,
                      icono: Icons.login,
                    ),
                    _DatoResumen(
                      titulo: 'Salida',
                      valor: controlador.ultimaSalida == null
                          ? 'Pendiente'
                          : _formatearFechaHora(
                              controlador.ultimaSalida!.fechaHora,
                            ),
                      color: Colors.orange,
                      icono: Icons.logout,
                    ),
                    _DatoResumen(
                      titulo: 'Ubicacion',
                      valor: controlador.dentroDeZona
                          ? 'Dentro de zona'
                          : 'Fuera de zona',
                      color:
                          controlador.dentroDeZona ? Colors.teal : Colors.red,
                      icono: Icons.my_location,
                    ),
                    _DatoResumen(
                      titulo: 'Rostro',
                      valor: controlador.rostroValidado ? 'Listo' : 'Pendiente',
                      color: controlador.rostroValidado
                          ? Colors.indigo
                          : Colors.deepOrange,
                      icono: Icons.face_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _TarjetaMensaje(
                  mensaje:
                      'Si deseas registrar tu asistencia, entra al modulo Asistencia y elige Entrada o Salida.',
                  color: Colors.blue,
                  icono: Icons.arrow_forward_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuloAsistencia extends StatelessWidget {
  const _ModuloAsistencia({
    required this.controlador,
    required this.onAbrirProcesoMarcacion,
  });

  final ControladorAsistencia controlador;
  final Future<void> Function(TipoMarcacion tipoMarcacion)
      onAbrirProcesoMarcacion;

  @override
  Widget build(BuildContext context) {
    final entrada = controlador.ultimaEntrada;
    final salida = controlador.ultimaSalida;
    final totalCompletados = (entrada != null ? 1 : 0) + (salida != null ? 1 : 0);
    final progreso = totalCompletados / 2;
    final textoProgreso = '$totalCompletados/2';

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Progreso del dia',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.1,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      textoProgreso,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 10,
                    backgroundColor: Colors.blueGrey.withOpacity(0.12),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    totalCompletados == 2
                        ? 'Jornada completada'
                        : '$totalCompletados completados',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus horarios de hoy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                _TarjetaHorarioDia(
                  entrada: entrada == null
                      ? 'Pendiente'
                      : _formatearSoloHora(entrada.fechaHora),
                  salida: salida == null
                      ? 'Pendiente'
                      : _formatearSoloHora(salida.fechaHora),
                ),
                const SizedBox(height: 12),
                if (entrada == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          onAbrirProcesoMarcacion(TipoMarcacion.entrada),
                      icon: const Icon(Icons.login),
                      label: const Text('Registrar entrada'),
                    ),
                  )
                else if (salida == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          onAbrirProcesoMarcacion(TipoMarcacion.salida),
                      icon: const Icon(Icons.logout),
                      label: const Text('Registrar salida'),
                    ),
                  )
                else
                  const _TarjetaMensaje(
                    mensaje:
                        'La entrada y la salida de hoy ya fueron registradas correctamente.',
                    color: Colors.green,
                    icono: Icons.check_circle_outline,
                  ),
                const SizedBox(height: 10),
                const _TarjetaMensaje(
                  mensaje:
                      'El detalle completo de ubicacion, rostro y confirmacion se muestra al abrir la tarjeta de Entrada o Salida.',
                  color: Colors.blue,
                  icono: Icons.open_in_new_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuloHistorial extends StatelessWidget {
  const _ModuloHistorial({
    required this.controlador,
    required this.onSeleccionarRango,
  });

  final ControladorAsistencia controlador;
  final Future<void> Function() onSeleccionarRango;

  @override
  Widget build(BuildContext context) {
    final resumenes = _agruparPorDia(controlador.historialFiltrado);
    final rangoActual = controlador.rangoHistorialSeleccionado;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Text(
          'Informe de mis Asistencias',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _BotonInforme(
                      icono: Icons.table_view,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _BotonInforme(
                      icono: Icons.picture_as_pdf_outlined,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CampoFiltroFecha(
                        valor: rangoActual == null
                            ? 'Inicio'
                            : _formatearFecha(rangoActual.start),
                        onTap: onSeleccionarRango,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CampoFiltroFecha(
                        valor: rangoActual == null
                            ? 'Fin'
                            : _formatearFecha(rangoActual.end),
                        onTap: onSeleccionarRango,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: FilledButton.tonal(
                        onPressed: controlador.cargandoHistorial
                            ? null
                            : () => controlador.cargarHistorial(),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFFE7F0F8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'Registros encontrados: ${resumenes.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0D4876),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (controlador.cargandoHistorial)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (resumenes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: _TarjetaMensaje(
                    mensaje: 'No hay marcaciones para el filtro seleccionado.',
                    color: Colors.blue,
                    icono: Icons.inbox_outlined,
                  ),
                )
              else
                _TablaInformeAsistencias(resumenes: resumenes),
            ],
          ),
        ),
      ],
    );
  }

  List<_ResumenDiaHistorial> _agruparPorDia(List<Asistencia> asistencias) {
    final agrupado = <String, List<Asistencia>>{};

    for (final asistencia in asistencias) {
      final llave = _soloFechaLlave(asistencia.fechaHora);
      agrupado.putIfAbsent(llave, () => []).add(asistencia);
    }

    final resumenes = <_ResumenDiaHistorial>[];
    for (final entry in agrupado.entries) {
      entry.value.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      Asistencia? entrada;
      Asistencia? salida;

      for (final asistencia in entry.value) {
        if (asistencia.tipoMarcacion == TipoMarcacion.entrada && entrada == null) {
          entrada = asistencia;
        }
        if (asistencia.tipoMarcacion == TipoMarcacion.salida) {
          salida = asistencia;
        }
      }

      resumenes.add(
        _ResumenDiaHistorial(
          fecha: entry.value.first.fechaHora,
          entrada: entrada,
          salida: salida,
        ),
      );
    }

    resumenes.sort((a, b) => b.fecha.compareTo(a.fecha));
    return resumenes;
  }

  String _soloFechaLlave(DateTime fechaHora) {
    final dia = fechaHora.day.toString().padLeft(2, '0');
    final mes = fechaHora.month.toString().padLeft(2, '0');
    final anio = fechaHora.year.toString();
    return '$anio-$mes-$dia';
  }
}

class _ModuloAlertas extends StatelessWidget {
  const _ModuloAlertas({required this.controlador});
  final ControladorAsistencia controlador;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controlador.cargandoAlertas)
                  const _TarjetaCarga(
                    mensaje: 'Consultando alertas del trabajador...',
                  )
                else if (controlador.alertasRecientes.isEmpty)
                  const _TarjetaMensaje(
                    mensaje: 'No hay alertas recientes para este trabajador.',
                    color: Colors.blue,
                    icono: Icons.info_outline,
                  )
                else
                  ...controlador.alertasRecientes.map(
                    (alerta) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TarjetaAlerta(alerta: alerta),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuloPerfil extends StatelessWidget {
  const _ModuloPerfil({
    required this.controlador,
    required this.correoSesion,
    required this.onCerrarSesion,
  });

  final ControladorAsistencia controlador;
  final String? correoSesion;
  final Future<void> Function()? onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final perfil = controlador.perfilActual;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _FilaInformacion(
                  icono: Icons.person_outline,
                  etiqueta: 'Nombre completo',
                  valor: perfil?.nombreCompleto ?? 'Pendiente',
                ),
                _FilaInformacion(
                  icono: Icons.badge_outlined,
                  etiqueta: 'Rol o cargo',
                  valor: perfil?.rolOCargo ?? 'Pendiente',
                ),
                _FilaInformacion(
                  icono: Icons.location_city_outlined,
                  etiqueta: 'Sede asignada',
                  valor: perfil?.nombreSede ?? 'Pendiente',
                ),
                _FilaInformacion(
                  icono: Icons.email_outlined,
                  etiqueta: 'Correo',
                  valor: perfil?.correoNotificacion.isNotEmpty == true
                      ? perfil!.correoNotificacion
                      : (correoSesion ?? 'Sin correo disponible'),
                ),
              ],
            ),
          ),
        ),
        if (onCerrarSesion != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesion'),
          ),
        ],
      ],
    );
  }
}

// Esta hoja inferior concentra el flujo de una marcacion concreta.
// Aqui el trabajador ve claramente que esta intentando registrar
// y puede validar ubicacion, rostro y confirmar la accion final.
class _HojaProcesoMarcacion extends StatelessWidget {
  const _HojaProcesoMarcacion({
    required this.controlador,
    required this.tipoMarcacion,
    required this.onValidarRostro,
  });

  final ControladorAsistencia controlador;
  final TipoMarcacion tipoMarcacion;
  final Future<void> Function() onValidarRostro;

  @override
  Widget build(BuildContext context) {
    final esEntrada = tipoMarcacion == TipoMarcacion.entrada;
    final color = esEntrada ? Colors.green : Colors.orange;
    final titulo = esEntrada ? 'Registrar entrada' : 'Registrar salida';
    final puedeConfirmar = controlador.tienePerfilCargado &&
        !controlador.guardando &&
        !controlador.validandoUbicacion &&
        !controlador.validandoRostro &&
        controlador.dentroDeZona &&
        controlador.rostroValidado;

    return AnimatedBuilder(
      animation: controlador,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.12),
                            foregroundColor: color,
                            child: Icon(
                              esEntrada ? Icons.login : Icons.logout,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                Text(
                                  _formatearFechaHora(
                                    controlador.fechaHoraActual,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _EtiquetaPanel(
                        titulo: 'Ubicacion',
                        contenido: controlador.resultadoUbicacion?.mensajeEstado ??
                            'Todavia no se consulto la ubicacion.',
                        accion: SizedBox(
                          height: 52,
                          width: 52,
                          child: FilledButton.tonal(
                            onPressed: controlador.validandoUbicacion
                                ? null
                                : controlador.validarUbicacion,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: controlador.validandoUbicacion
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _EtiquetaPanel(
                        titulo: 'Consideracion',
                        contenido: controlador.dentroDeZona
                            ? 'La ubicacion esta dentro del radio permitido.'
                            : 'La ubicacion aun no cumple la validacion requerida.',
                      ),
                      const SizedBox(height: 12),
                      _EtiquetaPanel(
                        titulo: 'Camara',
                        contenido: controlador.resultadoFacial?.mensajeEstado ??
                            'Todavia no se ha realizado la validacion facial.',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed:
                            controlador.validandoRostro ? null : onValidarRostro,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Validar rostro'),
                      ),
                      const SizedBox(height: 12),
                      if (controlador.resultadoFacial?.rutaImagenCapturada != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Evidencia facial lista',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'La foto ya fue capturada y esta preparada para la siguiente marcacion.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      else
                        const _TarjetaMensaje(
                          mensaje:
                              'Aun no hay una evidencia facial capturada para esta accion.',
                          color: Colors.orange,
                          icono: Icons.camera_alt_outlined,
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: puedeConfirmar
                              ? () async {
                                  await controlador.registrarMarcacion(
                                    tipoMarcacion,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              : null,
                          icon: Icon(esEntrada ? Icons.login : Icons.logout),
                          label: Text(titulo),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CabeceraTrabajador extends StatelessWidget {
  const _CabeceraTrabajador({
    required this.nombre,
    required this.sede,
    required this.fecha,
    required this.hora,
  });

  final String nombre;
  final String sede;
  final String fecha;
  final String hora;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3D6D2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFBC2027),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'UNACHU',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4EB267),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'En linea',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF80848B),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  nombre,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        color: const Color(0xFF20242C),
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFC72B30),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sede,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF2F3035),
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipCabecera(
                      icono: Icons.calendar_today_outlined,
                      texto: fecha,
                      fondo: const Color(0xFFF3EFED),
                      colorTexto: const Color(0xFF5F5754),
                    ),
                    _ChipCabecera(
                      icono: Icons.schedule,
                      texto: hora,
                      fondo: const Color(0xFFF3EFED),
                      colorTexto: const Color(0xFF5F5754),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipCabecera extends StatelessWidget {
  const _ChipCabecera({
    required this.icono,
    required this.texto,
    this.fondo = const Color(0x22FFFFFF),
    this.colorTexto = Colors.white,
  });
  final IconData icono;
  final String texto;
  final Color fondo;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: colorTexto),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: colorTexto,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoResumen extends StatelessWidget {
  const _DatoResumen({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 6),
              Text(titulo),
            ],
          ),
          const SizedBox(height: 8),
          Text(valor, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _TarjetaHorarioDia extends StatelessWidget {
  const _TarjetaHorarioDia({
    required this.entrada,
    required this.salida,
  });

  final String entrada;
  final String salida;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.withOpacity(0.24)),
      ),
      child: Column(
        children: [
          _BloqueHorario(
            etiqueta: 'Entrada',
            valor: entrada,
            color: Colors.green,
            icono: Icons.login,
          ),
          const SizedBox(height: 10),
          _BloqueHorario(
            etiqueta: 'Salida',
            valor: salida,
            color: Colors.orange,
            icono: Icons.logout,
          ),
        ],
      ),
    );
  }
}

class _BloqueHorario extends StatelessWidget {
  const _BloqueHorario({
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.icono,
  });

  final String etiqueta;
  final String valor;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final pendiente = valor == 'Pendiente';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.14),
            foregroundColor: color,
            child: Icon(icono, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1,
                        color: Colors.blueGrey,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pendiente
                  ? Colors.grey.withOpacity(0.12)
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pendiente ? 'PENDIENTE' : 'COMPLETADO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: pendiente ? Colors.grey.shade700 : color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaInformacion extends StatelessWidget {
  const _FilaInformacion({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(valor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaEstadoSimple extends StatelessWidget {
  const _FilaEstadoSimple({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            valor,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaMarcacion extends StatelessWidget {
  const _TarjetaMarcacion({required this.asistencia});
  final Asistencia asistencia;

  @override
  Widget build(BuildContext context) {
    final esEntrada = asistencia.tipoMarcacion == TipoMarcacion.entrada;
    final color = esEntrada ? Colors.green : Colors.orange;
    return _TarjetaMensaje(
      mensaje:
          '${esEntrada ? 'Entrada' : 'Salida'} - ${_formatearFechaHora(asistencia.fechaHora)}',
      color: color,
      icono: esEntrada ? Icons.login_outlined : Icons.logout_outlined,
    );
  }
}

class _ResumenDiaHistorial {
  const _ResumenDiaHistorial({
    required this.fecha,
    required this.entrada,
    required this.salida,
  });

  final DateTime fecha;
  final Asistencia? entrada;
  final Asistencia? salida;

  Duration? get tiempoLaborado {
    if (entrada == null || salida == null) {
      return null;
    }
    return salida!.fechaHora.difference(entrada!.fechaHora);
  }

  bool get completo => entrada != null && salida != null;
}

class _TablaInformeAsistencias extends StatelessWidget {
  const _TablaInformeAsistencias({
    required this.resumenes,
  });

  final List<_ResumenDiaHistorial> resumenes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 820),
        child: Column(
          children: [
            const _FilaCabeceraInforme(),
            ...resumenes.map((resumen) => _FilaInformeAsistencia(resumen: resumen)),
          ],
        ),
      ),
    );
  }
}

class _FilaCabeceraInforme extends StatelessWidget {
  const _FilaCabeceraInforme();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EEF2),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: const Row(
        children: [
          _CeldaCabecera(texto: 'Fecha', ancho: 120),
          _CeldaCabecera(texto: 'H. Entrada', ancho: 110),
          _CeldaCabecera(texto: '', ancho: 60),
          _CeldaCabecera(texto: 'H. Salida', ancho: 110),
          _CeldaCabecera(texto: '', ancho: 60),
          _CeldaCabecera(texto: 'Tardanza', ancho: 110),
          _CeldaCabecera(texto: 'T. Laborado', ancho: 120),
          _CeldaCabecera(texto: 'Descanso (min)', ancho: 120),
          _CeldaCabecera(texto: '', ancho: 70),
        ],
      ),
    );
  }
}

class _CeldaCabecera extends StatelessWidget {
  const _CeldaCabecera({
    required this.texto,
    required this.ancho,
  });

  final String texto;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF3E505E),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _FilaInformeAsistencia extends StatelessWidget {
  const _FilaInformeAsistencia({
    required this.resumen,
  });

  final _ResumenDiaHistorial resumen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE1E5EA)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _CeldaDato(texto: _formatearFecha(resumen.fecha), ancho: 120),
          _CeldaDato(
            texto: resumen.entrada == null
                ? '--:--'
                : _formatearHoraAmPm(resumen.entrada!.fechaHora),
            ancho: 110,
          ),
          _CeldaEstado(completado: resumen.entrada != null, ancho: 60),
          _CeldaDato(
            texto: resumen.salida == null
                ? '--:--'
                : _formatearHoraAmPm(resumen.salida!.fechaHora),
            ancho: 110,
          ),
          _CeldaEstado(completado: resumen.salida != null, ancho: 60),
          _CeldaDato(
            texto: resumen.completo ? '00:00' : '--:--',
            ancho: 110,
          ),
          _CeldaDato(
            texto: resumen.tiempoLaborado == null
                ? '--:--'
                : _formatearDuracion(resumen.tiempoLaborado!),
            ancho: 120,
          ),
          _CeldaDato(
            texto: resumen.completo ? '00:00' : '--:--',
            ancho: 120,
          ),
          const _CeldaAccionImprimir(ancho: 70),
        ],
      ),
    );
  }
}

class _CeldaDato extends StatelessWidget {
  const _CeldaDato({
    required this.texto,
    required this.ancho,
  });

  final String texto;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _CeldaEstado extends StatelessWidget {
  const _CeldaEstado({
    required this.completado,
    required this.ancho,
  });

  final bool completado;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: completado ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            completado ? Icons.check : Icons.priority_high,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _CeldaAccionImprimir extends StatelessWidget {
  const _CeldaAccionImprimir({
    required this.ancho,
  });

  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.print_outlined),
        ),
      ),
    );
  }
}

class _BotonInforme extends StatelessWidget {
  const _BotonInforme({
    required this.icono,
    required this.color,
  });

  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icono, color: color),
    );
  }
}

class _CampoFiltroFecha extends StatelessWidget {
  const _CampoFiltroFecha({
    required this.valor,
    required this.onTap,
  });

  final String valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          valor,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _TarjetaAlerta extends StatelessWidget {
  const _TarjetaAlerta({required this.alerta});
  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    return _TarjetaMensaje(
      mensaje:
          '${_tituloSegunTipo(alerta.tipo)}\n${alerta.mensaje}\n${_formatearFechaHora(alerta.fechaHora)}',
      color: _colorSegunTipo(alerta.tipo),
      icono: Icons.warning_amber_rounded,
    );
  }

  static Color _colorSegunTipo(TipoAlerta tipo) {
    switch (tipo) {
      case TipoAlerta.fueraDeZona:
        return Colors.red;
      case TipoAlerta.rostroNoValido:
        return Colors.orange;
      case TipoAlerta.marcacionRechazada:
        return Colors.deepOrange;
      case TipoAlerta.notificacionPendiente:
        return Colors.blue;
    }
  }

  static String _tituloSegunTipo(TipoAlerta tipo) {
    switch (tipo) {
      case TipoAlerta.fueraDeZona:
        return 'Marcacion fuera de zona';
      case TipoAlerta.rostroNoValido:
        return 'Validacion facial no superada';
      case TipoAlerta.marcacionRechazada:
        return 'Marcacion rechazada';
      case TipoAlerta.notificacionPendiente:
        return 'Notificacion pendiente';
    }
  }
}

class _TarjetaMensaje extends StatelessWidget {
  const _TarjetaMensaje({
    required this.mensaje,
    required this.color,
    required this.icono,
  });

  final String mensaje;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(mensaje)),
        ],
      ),
    );
  }
}

class _EtiquetaPanel extends StatelessWidget {
  const _EtiquetaPanel({
    required this.titulo,
    required this.contenido,
    this.accion,
  });

  final String titulo;
  final String contenido;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        if (accion == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(contenido),
          )
        else
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(contenido),
                ),
              ),
              const SizedBox(width: 10),
              accion!,
            ],
          ),
      ],
    );
  }
}

class _TarjetaCarga extends StatelessWidget {
  const _TarjetaCarga({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Color _colorMensaje(String mensaje) {
  final texto = mensaje.toLowerCase();
  if (texto.contains('correctamente')) return Colors.green;
  if (texto.contains('no pudimos') || texto.contains('primero')) {
    return Colors.red;
  }
  return Colors.blue;
}

IconData _iconoMensaje(String mensaje) {
  final texto = mensaje.toLowerCase();
  if (texto.contains('correctamente')) return Icons.check_circle_outline;
  if (texto.contains('no pudimos') || texto.contains('primero')) {
    return Icons.error_outline;
  }
  return Icons.info_outline;
}

String _formatearFechaHora(DateTime fechaHora) {
  final dia = fechaHora.day.toString().padLeft(2, '0');
  final mes = fechaHora.month.toString().padLeft(2, '0');
  final anio = fechaHora.year.toString();
  final hora = fechaHora.hour.toString().padLeft(2, '0');
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  final segundo = fechaHora.second.toString().padLeft(2, '0');
  return '$dia/$mes/$anio - $hora:$minuto:$segundo';
}

String _formatearFecha(DateTime fechaHora) {
  final dia = fechaHora.day.toString().padLeft(2, '0');
  final mes = fechaHora.month.toString().padLeft(2, '0');
  final anio = fechaHora.year.toString();
  return '$dia/$mes/$anio';
}

String _formatearHora(DateTime fechaHora) {
  final hora = fechaHora.hour.toString().padLeft(2, '0');
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  final segundo = fechaHora.second.toString().padLeft(2, '0');
  return '$hora:$minuto:$segundo';
}

String _formatearSoloHora(DateTime fechaHora) {
  final hora = fechaHora.hour.toString().padLeft(2, '0');
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}

String _formatearHoraAmPm(DateTime fechaHora) {
  final hora24 = fechaHora.hour;
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  final periodo = hora24 >= 12 ? 'PM' : 'AM';
  final hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12;
  return '${hora12.toString().padLeft(2, '0')}:$minuto $periodo';
}

String _formatearDuracion(Duration duracion) {
  final horas = duracion.inHours.toString().padLeft(2, '0');
  final minutos = (duracion.inMinutes % 60).toString().padLeft(2, '0');
  return '$horas:$minutos';
}
