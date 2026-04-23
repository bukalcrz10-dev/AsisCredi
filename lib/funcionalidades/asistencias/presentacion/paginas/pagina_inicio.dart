import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../reconocimiento_facial/datos/repositorios/repositorio_reconocimiento_facial_impl.dart';
import '../../../reconocimiento_facial/presentacion/paginas/pagina_validacion_facial.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../controladores/controlador_asistencia.dart';
import '../controladores/fabrica_controlador_asistencia.dart';
import '../widgets/cabecera_trabajador_panel.dart';
import '../widgets/hoja_proceso_marcacion.dart';
import '../widgets/modulo_asistencia_trabajador.dart';
import '../widgets/modulo_historial_trabajador.dart';
import '../widgets/modulo_perfil_trabajador.dart';
import '../widgets/soporte_panel_trabajador.dart';

// Esta pantalla ahora agrupa la experiencia del trabajador en modulos.
// La logica principal sigue en el controlador, pero la UI se separa
// para evitar una vista unica demasiado larga y dificil de recorrer.
class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key, this.usuarioAutenticado, this.onCerrarSesion});

  final User? usuarioAutenticado;
  final Future<void> Function()? onCerrarSesion;

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio>
    with WidgetsBindingObserver {
  late final ControladorAsistencia _controlador;
  late final RepositorioReconocimientoFacialImpl
      _repositorioReconocimientoFacial;
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final dependencias = crearDependenciasAsistencia(
      usuarioAutenticado: widget.usuarioAutenticado,
    );
    _controlador = dependencias.controlador;
    _repositorioReconocimientoFacial =
        dependencias.repositorioReconocimientoFacial;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controlador.cargarPerfil();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador.dispose();
    _repositorioReconocimientoFacial.cerrar();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _controlador.tienePerfilCargado &&
        !_controlador.validandoUbicacion &&
        _controlador.resultadoUbicacion != null &&
        (!_controlador.resultadoUbicacion!.servicioHabilitado ||
            !_controlador.resultadoUbicacion!.permisoConcedido)) {
      _controlador.validarUbicacion();
    }
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
      initialDateRange:
          _controlador.rangoHistorialSeleccionado ??
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
    // Abrimos la hoja de inmediato para que el boton responda rapido
    // y ejecutamos la validacion de ubicacion en paralelo. Si falta
    // permiso, Android seguira mostrando su dialogo real.
    _controlador.validarUbicacion();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HojaProcesoMarcacion(
        controlador: _controlador,
        tipoMarcacion: tipoMarcacion,
        onValidarRostro: _abrirValidacionFacial,
      ),
    );
  }

  Widget _crearVistaActual() {
    switch (_indice) {
      case 0:
        return ModuloAsistenciaTrabajador(
          controlador: _controlador,
          onAbrirProcesoMarcacion: _abrirProcesoMarcacion,
        );
      case 1:
        return ModuloHistorialTrabajador(
          controlador: _controlador,
          onSeleccionarRango: _seleccionarRangoHistorial,
        );
      default:
        return ModuloPerfilTrabajador(
          controlador: _controlador,
          correoSesion: widget.usuarioAutenticado?.email,
          onCerrarSesion: widget.onCerrarSesion,
        );
    }
  }

  PreferredSizeWidget _crearAppBar() {
    return AppBar(
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
    );
  }

  Widget? _crearCabeceraTrabajador() {
    if (!_debeMostrarCabeceraTrabajador(_indice)) {
      return null;
    }

    final perfil = _controlador.perfilActual;
    return CabeceraTrabajadorPanel(
      nombre:
          perfil?.nombreCompleto ??
          widget.usuarioAutenticado?.displayName ??
          'Trabajador',
      sede: perfil?.nombreSede ?? 'Sede pendiente',
      fecha: formatearFechaPanel(_controlador.fechaHoraActual),
      hora: formatearHoraPanel(_controlador.fechaHoraActual),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) {
        final cabeceraTrabajador = _crearCabeceraTrabajador();
        final cabeceraTrabajadorWidgets = cabeceraTrabajador == null
            ? const <Widget>[]
            : <Widget>[cabeceraTrabajador];

        return Scaffold(
          appBar: _crearAppBar(),
          body: SafeArea(
            child: Column(
              children: [
                ...cabeceraTrabajadorWidgets,
                Expanded(child: _crearVistaActual()),
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

bool _debeMostrarCabeceraTrabajador(int indiceModulo) {
  // El historial funciona mejor como vista de informe, sin repetir
  // la cabecera del trabajador que ya aparece en modulos mas personales.
  // El perfil tambien queda mejor sin ese encabezado para enfocarse
  // directamente en la informacion del usuario.
  return indiceModulo != 1 && indiceModulo != 2;
}

const List<String> _titulos = ['Marcar asistencia', 'Historial', 'Mi perfil'];
