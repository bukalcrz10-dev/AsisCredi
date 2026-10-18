import '../../../sedes/datos/fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../../../sedes/datos/modelos/modelo_sede.dart';
import '../../../sedes/dominio/entidades/sede.dart';
import 'dialogo_biometria_admin.dart';
import 'listado_trabajadores_admin.dart';
import 'ficha_trabajador_admin.dart';
import 'modulo_asistencias_admin.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../datos/servicios/servicio_trabajadores_firebase.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../../presentacion/modelos/trabajador_admin.dart';
import 'contenedor_modulo_admin.dart';
import '../../../../app/diseno_sistema.dart';

enum VistaTrabajadoresAdmin { gestion, crear, vigentes }

class ModuloTrabajadoresAdmin extends StatefulWidget {
  const ModuloTrabajadoresAdmin({
    super.key,
    this.vista = VistaTrabajadoresAdmin.gestion,
    this.trabajadorInicialId,
  });

  final VistaTrabajadoresAdmin vista;
  final String? trabajadorInicialId;

  @override
  State<ModuloTrabajadoresAdmin> createState() =>
      _ModuloTrabajadoresAdminState();
}

class _ModuloTrabajadoresAdminState extends State<ModuloTrabajadoresAdmin> {
  final _fuenteSedes = FuenteDatosSedesFirestore();
  List<Sede> _sedes = [];

  final RepositorioUsuariosImpl _repositorioUsuarios = RepositorioUsuariosImpl(
    FuenteDatosUsuariosFirestore(),
  );
  final ServicioTrabajadoresFirebase _servicioTrabajadores =
      ServicioTrabajadoresFirebase();
  final TextEditingController _busquedaController = TextEditingController();

  List<TrabajadorAdmin> _trabajadores = const [];
  bool _cargando = true;
  bool _hayMasTrabajadores = false;
  QueryDocumentSnapshot<Map<String, dynamic>>? _ultimoTrabajador;
  bool _guardando = false;
  String _busqueda = '';
  String? _mensajeError;
  bool? _estadoFiltrado = true;
  int _versionFormulario = 0;
  String? _trabajadorSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _trabajadorSeleccionadoId = widget.trabajadorInicialId;
    _cargarTrabajadores();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarTrabajadores({bool cargarMas = false}) async {
    if (_cargando && cargarMas) return;
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      if (!cargarMas) {
        final documentosSedes = await _fuenteSedes.obtenerSedes();
        _sedes = documentosSedes
            .map((e) => ModeloSede.desdeMapa(e.value, e.key).aEntidad())
            .toList();
      }
      if (widget.vista == VistaTrabajadoresAdmin.vigentes) {
        final usuarios = await _repositorioUsuarios.obtenerUsuarios();
        if (!mounted) return;
        setState(() {
          _trabajadores = usuarios.map(_mapearUsuarioATrabajador).toList();
          _hayMasTrabajadores = false;
          _cargando = false;
          _guardando = false;
        });
        return;
      }
      final pagina = await _repositorioUsuarios.obtenerPaginaUsuarios(
        despuesDe: cargarMas ? _ultimoTrabajador : null,
      );
      final trabajadores = pagina.usuarios
          .map<TrabajadorAdmin>(_mapearUsuarioATrabajador)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _trabajadores = [if (cargarMas) ..._trabajadores, ...trabajadores];
        _ultimoTrabajador = pagina.ultimoDocumento;
        _hayMasTrabajadores = pagina.hayMas;
        _cargando = false;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;
        _guardando = false;
        _mensajeError =
            'No se pudieron cargar los trabajadores desde Firestore.';
      });
    }
  }

  TrabajadorAdmin _mapearUsuarioATrabajador(Usuario usuario) {
    return TrabajadorAdmin(
      id: usuario.id,
      nombreCompleto: usuario.nombreCompleto,
      correo: usuario.correo,
      telefono: usuario.telefono,
      area: usuario.area,
      cargo: _etiquetaCargo(usuario.cargo),
      rol: usuario.rol == RolUsuario.administrador
          ? 'Administrador'
          : 'Trabajador',
      estadoActivo: usuario.activo,
      fechaInicioLabores: usuario.fechaInicioLabores,
      sedeId: usuario.sedeAsignadaId,
      sede:
          _sedes
              .where((s) => s.id == usuario.sedeAsignadaId)
              .map((s) => s.nombre)
              .firstOrNull ??
          usuario.sedeAsignadaId,
    );
  }

  Future<void> _guardarTrabajador(TrabajadorAdmin trabajador) async {
    if (_guardando) return;
    setState(() {
      _guardando = true;
      _mensajeError = null;
    });

    try {
      await _servicioTrabajadores.actualizarTrabajador(
        uid: trabajador.id,
        fechaInicioLabores: trabajador.fechaInicioLabores,
        nombreCompleto: trabajador.nombreCompleto,
        correo: trabajador.correo,
        telefono: trabajador.telefono,
        area: trabajador.area,
        cargo: trabajador.cargo,
        rol: trabajador.rol,
        activo: trabajador.estadoActivo,
        sedeAsignadaId: trabajador.sedeId,
      );
      await _cargarTrabajadores();
      if (mounted && _mensajeError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios del trabajador guardados.')),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _mensajeError =
            'No se pudo confirmar el guardado a tiempo. Revisa tu conexión y actualiza la lista antes de reintentar.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      final partes = <String>[
        if ((error.code).trim().isNotEmpty) 'Codigo: ${error.code}',
        if ((error.message ?? '').trim().isNotEmpty)
          'Mensaje: ${error.message}',
      ];

      setState(() {
        _guardando = false;
        _mensajeError = partes.isNotEmpty
            ? partes.join(' | ')
            : 'No se pudo actualizar el trabajador.';
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _mensajeError = error.code == 'permission-denied'
            ? 'Tu sesión no tiene permiso para editar trabajadores. Verifica que el usuario sea administrador activo.'
            : 'No se pudo guardar el perfil (${error.code}). Revisa tu conexión y actualiza la lista.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
        _mensajeError = 'No se pudo actualizar el trabajador.';
      });
    }
  }

  Future<void> _crearTrabajadorConAcceso(
    ResultadoFormularioTrabajadorAdmin resultado,
  ) async {
    if (_guardando) return;
    setState(() {
      _guardando = true;
      _mensajeError = null;
    });

    try {
      await _servicioTrabajadores.crearTrabajadorConAcceso(
        nombreCompleto: resultado.trabajador.nombreCompleto,
        correo: resultado.trabajador.correo,
        telefono: resultado.trabajador.telefono,
        area: resultado.trabajador.area,
        cargo: resultado.trabajador.cargo,
        rol: resultado.trabajador.rol,
        activo: resultado.trabajador.estadoActivo,
        sedeAsignadaId: resultado.trabajador.sedeId,
        password: resultado.password,
        fechaInicioLabores: resultado.trabajador.fechaInicioLabores,
      );
      await _cargarTrabajadores();
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Error creando trabajador desde panel admin: '
        'code=${error.code}, message=${error.message}',
      );

      if (!mounted) {
        return;
      }

      final partes = <String>[
        if ((error.code).trim().isNotEmpty) 'Codigo: ${error.code}',
        if ((error.message ?? '').trim().isNotEmpty)
          'Mensaje: ${error.message}',
      ];

      setState(() {
        _guardando = false;
        _mensajeError = partes.isNotEmpty
            ? partes.join(' | ')
            : 'No se pudo crear el trabajador en Authentication.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
        _mensajeError =
            'No se pudo crear el trabajador en Authentication: $error';
      });
    }
  }

  Future<void> _abrirDialogoNuevoTrabajador() async {
    final resultado = await showDialog<ResultadoFormularioTrabajadorAdmin>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FormularioTrabajadorAdmin(sedes: _sedes),
    );

    if (resultado == null || !mounted) {
      return;
    }

    setState(() {
      _busqueda = '';
      _busquedaController.clear();
    });
    await _crearTrabajadorConAcceso(resultado);
  }

  Future<void> _abrirDialogoEditarTrabajador(TrabajadorAdmin trabajador) async {
    final resultado = await showDialog<ResultadoFormularioTrabajadorAdmin>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FormularioTrabajadorAdmin(
        trabajadorInicial: trabajador,
        sedes: _sedes,
      ),
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _guardarTrabajador(resultado.trabajador);
  }

  Future<void> _alternarEstadoTrabajador(TrabajadorAdmin trabajador) async {
    await _guardarTrabajador(
      trabajador.copyWith(estadoActivo: !trabajador.estadoActivo),
    );
  }

  Future<void> _restablecerContrasenaTrabajador(
    TrabajadorAdmin trabajador,
  ) async {
    if (_guardando) return;
    setState(() {
      _guardando = true;
      _mensajeError = null;
    });

    try {
      await _servicioTrabajadores.restablecerContrasenaTrabajador(
        uid: trabajador.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
        _mensajeError = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud enviada. El trabajador debe revisar su correo y la carpeta de spam.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      final partes = <String>[
        if ((error.code).trim().isNotEmpty) 'Codigo: ${error.code}',
        if ((error.message ?? '').trim().isNotEmpty)
          'Mensaje: ${error.message}',
      ];

      setState(() {
        _guardando = false;
        _mensajeError = partes.isNotEmpty
            ? partes.join(' | ')
            : 'No se pudo restablecer la contrasena del trabajador.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
        _mensajeError = 'No se pudo restablecer la contrasena del trabajador.';
      });
    }
  }

  Future<void> _abrirDialogoRestablecerContrasena(
    TrabajadorAdmin trabajador,
  ) async {
    final enviar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Text(
          'Se enviará un enlace a ${trabajador.correo} para que el trabajador elija su nueva contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
    if (enviar != true || !mounted || _guardando) return;
    await _restablecerContrasenaTrabajador(trabajador);
  }

  List<TrabajadorAdmin> get _trabajadoresFiltrados {
    final consulta = _busqueda.trim().toLowerCase();
    final candidatos = widget.vista == VistaTrabajadoresAdmin.vigentes
        ? _trabajadores
              .where(
                (item) =>
                    _estadoFiltrado == null ||
                    item.estadoActivo == _estadoFiltrado,
              )
              .toList()
        : _trabajadores;
    if (consulta.isEmpty) {
      return candidatos;
    }

    return candidatos.where((trabajador) {
      return trabajador.nombreCompleto.toLowerCase().contains(consulta) ||
          trabajador.correo.toLowerCase().contains(consulta) ||
          trabajador.telefono.toLowerCase().contains(consulta) ||
          trabajador.area.toLowerCase().contains(consulta) ||
          trabajador.id.toLowerCase().contains(consulta) ||
          trabajador.cargo.toLowerCase().contains(consulta) ||
          trabajador.rol.toLowerCase().contains(consulta) ||
          trabajador.sede.toLowerCase().contains(consulta);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vista == VistaTrabajadoresAdmin.crear) {
      return ContenedorModuloAdmin(
        titulo: 'Crear trabajador',
        descripcion: 'Completa los datos para crear su cuenta de acceso.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mensajeError != null) ...[
              Text(
                _mensajeError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            if (_cargando)
              const CircularProgressIndicator()
            else if (_mensajeError != null && _sedes.isEmpty)
              OutlinedButton.icon(
                onPressed: () => _cargarTrabajadores(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar carga'),
              )
            else
              FormularioTrabajadorAdmin(
                key: ValueKey(_versionFormulario),
                sedes: _sedes,
                guardando: _guardando,
                onRestablecer: () => setState(() => _versionFormulario++),
                onGuardar: (resultado) async {
                  await _crearTrabajadorConAcceso(resultado);
                  if (!mounted || !context.mounted || _mensajeError != null) {
                    return;
                  }
                  setState(() => _versionFormulario++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trabajador creado correctamente.'),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }
    if (widget.vista == VistaTrabajadoresAdmin.vigentes) {
      final seleccionado = _trabajadores
          .where((t) => t.id == _trabajadorSeleccionadoId)
          .firstOrNull;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Offstage(
            offstage: seleccionado != null,
            child: ListadoTrabajadoresAdmin(
              trabajadores: _trabajadores,
              cargando: _cargando,
              error: _mensajeError,
              onActualizar: _cargando || _guardando
                  ? null
                  : () => _cargarTrabajadores(),
              onSeleccionar: (trabajador) =>
                  setState(() => _trabajadorSeleccionadoId = trabajador.id),
            ),
          ),
          if (seleccionado != null) ...[
            if (_cargando || _guardando) const LinearProgressIndicator(),
            FichaTrabajadorAdmin(
              trabajador: seleccionado,
              construirResumenAsistencia: (_) => ModuloAsistenciasAdmin(
                key: ValueKey('resumen-asistencia-${seleccionado.id}'),
                trabajadorId: seleccionado.id,
                vista: VistaAsistenciasAdmin.resumen,
              ),
              construirAsistencia: (_) => ModuloAsistenciasAdmin(
                key: ValueKey('asistencia-${seleccionado.id}'),
                trabajadorId: seleccionado.id,
                vista: VistaAsistenciasAdmin.registros,
              ),
              error: _mensajeError,
              onVolver: () => setState(() => _trabajadorSeleccionadoId = null),
              onEditar: _guardando || _cargando
                  ? null
                  : () => _abrirDialogoEditarTrabajador(seleccionado),
              onRecuperar: _guardando || _cargando
                  ? null
                  : () => _abrirDialogoRestablecerContrasena(seleccionado),
              onEstado: _guardando || _cargando
                  ? null
                  : () => _alternarEstadoTrabajador(seleccionado),
              construirBiometria: (_) => AbsorbPointer(
                absorbing: _guardando || _cargando,
                child: DialogoBiometriaAdmin(
                  key: ValueKey(seleccionado.id),
                  uid: seleccionado.id,
                  nombre: seleccionado.nombreCompleto,
                  integrado: true,
                ),
              ),
            ),
          ],
        ],
      );
    }
    final trabajadores = _trabajadoresFiltrados;
    final activos = _trabajadores.where((item) => item.estadoActivo).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContenedorModuloAdmin(
          titulo: 'Gestion de trabajadores',
          descripcion:
              'Vista administrativa conectada a Firestore para gestionar el personal.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ChipInfoAdmin(
                    icono: Icons.groups_2_outlined,
                    etiqueta: 'Total registrados',
                    valor: '${_trabajadores.length}',
                  ),
                  _ChipInfoAdmin(
                    icono: Icons.verified_user_outlined,
                    etiqueta: 'Cuentas activas',
                    valor: '$activos',
                  ),
                  const _ChipInfoAdmin(
                    icono: Icons.account_balance_outlined,
                    etiqueta: 'Sede principal',
                    valor: 'CREDIASCIENDE',
                  ),
                ],
              ),
              if (_mensajeError != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ColoresPanel.turquesa.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      MedidasSistema.radioCampo,
                    ),
                    border: Border.all(color: ColoresSistema.bordeIntermedio),
                  ),
                  child: Text(
                    _mensajeError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresSistema.rojoInstitucionalOscuro,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColoresSistema.fondoTarjeta,
            borderRadius: BorderRadius.circular(MedidasSistema.radioTarjeta),
            border: Border.all(color: ColoresSistema.bordeSuave),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.vista == VistaTrabajadoresAdmin.vigentes
                    ? switch (_estadoFiltrado) {
                        true => 'Trabajadores vigentes',
                        false => 'Trabajadores inactivos',
                        null => 'Todos los trabajadores',
                      }
                    : 'Listado de trabajadores',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Busca entre los trabajadores cargados; puedes cargar más resultados.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresSistema.textoSecundario,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _busquedaController,
                onChanged: (valor) {
                  setState(() {
                    _busqueda = valor;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar trabajador...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.vista == VistaTrabajadoresAdmin.vigentes) ...[
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    initialValue: 'vigentes',
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(
                        value: 'vigentes',
                        child: Text('Vigentes'),
                      ),
                      DropdownMenuItem(
                        value: 'inactivos',
                        child: Text('Inactivos'),
                      ),
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    ],
                    onChanged: (valor) => setState(() {
                      _estadoFiltrado = switch (valor) {
                        'vigentes' => true,
                        'inactivos' => false,
                        _ => null,
                      };
                    }),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.vista == VistaTrabajadoresAdmin.gestion)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : _abrirDialogoNuevoTrabajador,
                    icon: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Nuevo trabajador'),
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Trabajadores cargados: ${_trabajadores.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColoresSistema.rojoInstitucionalOscuro,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar trabajadores',
                    onPressed: _cargando || _guardando
                        ? null
                        : () => _cargarTrabajadores(),
                    icon: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_cargando && _trabajadores.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (trabajadores.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ColoresSistema.fondoSuave,
                    borderRadius: BorderRadius.circular(
                      MedidasSistema.radioBloque,
                    ),
                    border: Border.all(color: ColoresSistema.bordeIntermedio),
                  ),
                  child: Text(
                    _trabajadores.isEmpty
                        ? 'No hay trabajadores registrados en Firestore.'
                        : 'No hay coincidencias en los trabajadores cargados. Revisa el filtro o carga más resultados.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresSistema.textoSecundario,
                    ),
                  ),
                )
              else ...[
                ...trabajadores.map(
                  (trabajador) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TarjetaTrabajadorAdmin(
                      trabajador: trabajador,
                      onEditar: _guardando
                          ? null
                          : () => _abrirDialogoEditarTrabajador(trabajador),
                      onRestablecerContrasena: _guardando
                          ? null
                          : () =>
                                _abrirDialogoRestablecerContrasena(trabajador),
                      onAlternarEstado: _guardando
                          ? null
                          : () => _alternarEstadoTrabajador(trabajador),
                    ),
                  ),
                ),
              ],
              if (_hayMasTrabajadores && !_cargando) ...[
                const SizedBox(height: 4),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _cargarTrabajadores(cargarMas: true),
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Cargar más trabajadores'),
                  ),
                ),
              ],
              if (_cargando && _trabajadores.isNotEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

String _etiquetaCargo(String cargo) {
  final normalizado = cargo.trim().toLowerCase();
  if (normalizado == 'plataforma' || normalizado == 'auxiliar de operaciones') {
    return 'Auxiliar de operaciones';
  }
  if (normalizado == 'asesora') return 'Asesor';
  return cargo;
}

class FormularioTrabajadorAdmin extends StatefulWidget {
  const FormularioTrabajadorAdmin({
    super.key,
    this.trabajadorInicial,
    required this.sedes,
    this.onGuardar,
    this.onRestablecer,
    this.guardando = false,
  });
  final List<Sede> sedes;
  final Future<void> Function(ResultadoFormularioTrabajadorAdmin)? onGuardar;
  final VoidCallback? onRestablecer;
  final bool guardando;

  final TrabajadorAdmin? trabajadorInicial;

  @override
  State<FormularioTrabajadorAdmin> createState() =>
      _FormularioTrabajadorAdminState();
}

class _FormularioTrabajadorAdminState extends State<FormularioTrabajadorAdmin> {
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _areaController;
  late String _cargo;
  String? _sedeId;
  late final TextEditingController _passwordController;
  late String _rol;
  late bool _estadoActivo;
  bool _mostrarPassword = false;
  DateTime? _fechaInicioLabores;

  @override
  void initState() {
    super.initState();
    final trabajador = widget.trabajadorInicial;
    _fechaInicioLabores = trabajador?.fechaInicioLabores;
    _nombreController = TextEditingController(
      text: trabajador?.nombreCompleto ?? '',
    );
    _correoController = TextEditingController(text: trabajador?.correo ?? '');
    _telefonoController = TextEditingController(
      text: trabajador?.telefono ?? '',
    );
    _areaController = TextEditingController(text: trabajador?.area ?? '');
    _cargo = _etiquetaCargo(trabajador?.cargo ?? 'Asesor');
    _sedeId = trabajador?.sedeId.isNotEmpty == true ? trabajador!.sedeId : null;
    _passwordController = TextEditingController();
    _rol = trabajador?.rol ?? 'Trabajador';
    _estadoActivo = trabajador?.estadoActivo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _areaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _errorFormulario;

  void _guardar() {
    if (widget.guardando) return;
    final editando = widget.trabajadorInicial != null;
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final telefono = _telefonoController.text.trim();
    final area = _areaController.text.trim();
    final cargo = _cargo.trim();
    final sede = widget.sedes.where((s) => s.id == _sedeId).firstOrNull;
    final password = _passwordController.text;

    final faltantes = <String>[
      if (nombre.isEmpty) 'nombre',
      if (correo.isEmpty) 'correo',
      if (!editando && telefono.isEmpty) 'teléfono',
      if (!editando && area.isEmpty) 'área',
      if (cargo.isEmpty) 'cargo',
      if (_sedeId == null || _sedeId!.isEmpty) 'sede',
      if (!editando && password.isEmpty) 'contraseña',
    ];
    if (faltantes.isNotEmpty) {
      setState(() => _errorFormulario = 'Completa: ${faltantes.join(', ')}.');
      return;
    }
    if (!editando && password.length < 6) {
      setState(
        () => _errorFormulario =
            'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    final trabajador = TrabajadorAdmin(
      id: widget.trabajadorInicial?.id ?? _generarId(nombre),
      nombreCompleto: nombre,
      correo: correo,
      telefono: telefono,
      area: area,
      cargo: cargo,
      rol: _rol,
      estadoActivo: _estadoActivo,
      sede: sede?.nombre ?? widget.trabajadorInicial?.sede ?? '',
      sedeId: _sedeId!,
      fechaInicioLabores: _fechaInicioLabores,
    );

    final resultado = ResultadoFormularioTrabajadorAdmin(
      trabajador: trabajador,
      password: password,
    );
    if (widget.onGuardar != null) {
      widget.onGuardar!(resultado);
    } else {
      Navigator.of(context).pop(resultado);
    }
  }

  String _generarId(String nombre) {
    final iniciales = nombre
        .split(' ')
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte[0].toUpperCase())
        .join()
        .padRight(2, 'X');
    final sufijo = DateTime.now().millisecondsSinceEpoch.toString().substring(
      9,
    );
    return 'TR-$iniciales-$sufijo';
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.trabajadorInicial != null;

    Widget campo(String etiqueta, Widget control) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF123847),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        control,
      ],
    );

    Widget entrada(
      String etiqueta,
      TextEditingController controller, {
      bool soloLectura = false,
      String? ayuda,
    }) => campo(
      etiqueta,
      TextField(
        key: ValueKey(etiqueta),
        controller: controller,
        readOnly: soloLectura,
        decoration: InputDecoration(
          hintText: switch (etiqueta) {
            'Nombre completo' => 'Nombres y apellidos',
            'Correo institucional' => 'nombre@empresa.com',
            'Teléfono' => 'Número de contacto',
            'Área' => 'Nombre del área',
            _ => etiqueta,
          },
          helperText: ayuda,
        ),
      ),
    );

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_errorFormulario != null) ...[
          Text(
            _errorFormulario!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
        ],
        _SeccionFormularioTrabajador(
          titulo: 'Datos personales y contacto',
          icono: Icons.person_outline_rounded,
          maximoColumnas: 4,
          children: [
            entrada('Nombre completo', _nombreController),
            entrada(
              'Correo institucional',
              _correoController,
              soloLectura: editando,
              ayuda: editando
                  ? 'El correo de acceso no se modifica desde el panel.'
                  : null,
            ),
            entrada('Teléfono', _telefonoController),
            entrada('Área', _areaController),
          ],
        ),
        const SizedBox(height: 16),
        _SeccionFormularioTrabajador(
          titulo: 'Asignación laboral',
          icono: Icons.work_outline_rounded,
          maximoColumnas: 4,
          children: [
            campo(
              'Fecha de inicio de labores',
              OutlinedButton.icon(
                key: const ValueKey('fecha-inicio-labores'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFC8DBE1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  _fechaInicioLabores == null
                      ? 'Seleccionar fecha'
                      : '${_fechaInicioLabores!.day.toString().padLeft(2, '0')}/${_fechaInicioLabores!.month.toString().padLeft(2, '0')}/${_fechaInicioLabores!.year}',
                ),
                onPressed: widget.guardando
                    ? null
                    : () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaInicioLabores ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        if (fecha != null && mounted) {
                          setState(() => _fechaInicioLabores = fecha);
                        }
                      },
              ),
            ),
            campo(
              'Cargo',
              DropdownButtonFormField<String>(
                initialValue: _cargo,
                isExpanded: true,
                decoration: InputDecoration(
                  helperMaxLines: 2,
                  helperText: _cargo == 'Asesor'
                      ? 'Jornada continua'
                      : _cargo == 'Auxiliar de operaciones'
                      ? 'Jornada partida'
                      : null,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'Asesor',
                    child: Text('Asesor'),
                  ),
                  const DropdownMenuItem(
                    value: 'Auxiliar de operaciones',
                    child: Text('Auxiliar de operaciones'),
                  ),
                  if (_cargo.isNotEmpty &&
                      !const [
                        'Asesor',
                        'Auxiliar de operaciones',
                      ].contains(_cargo))
                    DropdownMenuItem(value: _cargo, child: Text(_cargo)),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _cargo = valor);
                },
              ),
            ),
            campo(
              'Sede asignada',
              DropdownButtonFormField<String>(
                key: const ValueKey('Sede asignada'),
                initialValue: _sedeId,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Seleccionar sede'),
                items: [
                  for (final sede in widget.sedes.where(
                    (s) => s.activa || s.id == _sedeId,
                  ))
                    DropdownMenuItem(value: sede.id, child: Text(sede.nombre)),
                  if (_sedeId != null &&
                      !widget.sedes.any((s) => s.id == _sedeId))
                    DropdownMenuItem(
                      value: _sedeId,
                      child: Text('Sede anterior ($_sedeId)'),
                    ),
                ],
                onChanged: (valor) => setState(() => _sedeId = valor),
              ),
            ),
            campo(
              'Rol',
              DropdownButtonFormField<String>(
                initialValue: _rol,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'Trabajador',
                    child: Text('Trabajador'),
                  ),
                  DropdownMenuItem(
                    value: 'Administrador',
                    child: Text('Administrador'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _rol = valor);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SeccionFormularioTrabajador(
          titulo: 'Acceso al sistema',
          icono: Icons.lock_outline_rounded,
          maximoColumnas: 2,
          children: [
            if (!editando)
              campo(
                'Contraseña inicial',
                TextField(
                  key: const ValueKey('Contraseña inicial'),
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  decoration: InputDecoration(
                    hintText: 'Contraseña inicial',
                    helperText: 'Mínimo 6 caracteres.',
                    suffixIcon: IconButton(
                      tooltip: _mostrarPassword
                          ? 'Ocultar contraseña'
                          : 'Mostrar contraseña',
                      onPressed: () =>
                          setState(() => _mostrarPassword = !_mostrarPassword),
                      icon: Icon(
                        _mostrarPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                title: const Text('Cuenta activa'),
                subtitle: const Text('Acceso habilitado al sistema'),
                value: _estadoActivo,
                onChanged: (valor) => setState(() => _estadoActivo = valor),
              ),
            ),
          ],
        ),
      ],
    );
    final acciones = <Widget>[
      OutlinedButton(
        onPressed: widget.guardando
            ? null
            : widget.onGuardar != null
            ? widget.onRestablecer
            : () => Navigator.of(context).pop(),
        child: Text(
          widget.onGuardar != null ? 'Limpiar formulario' : 'Cancelar',
        ),
      ),
      FilledButton.icon(
        onPressed: widget.guardando ? null : _guardar,
        icon: const Icon(Icons.save_outlined),
        label: Text(
          widget.guardando
              ? 'Guardando…'
              : editando
              ? 'Guardar cambios'
              : widget.onGuardar != null
              ? 'Crear trabajador'
              : 'Guardar',
        ),
      ),
    ];
    if (widget.onGuardar == null) {
      return AlertDialog(
        title: Text(editando ? 'Editar trabajador' : 'Nuevo trabajador'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: contenido),
        ),
        actions: acciones,
      );
    }
    return AbsorbPointer(
      absorbing: widget.guardando,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          contenido,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 8, runSpacing: 8, children: acciones),
          ),
        ],
      ),
    );
  }
}

class _SeccionFormularioTrabajador extends StatelessWidget {
  const _SeccionFormularioTrabajador({
    required this.titulo,
    required this.children,
    required this.maximoColumnas,
    required this.icono,
  });
  final String titulo;
  final List<Widget> children;
  final int maximoColumnas;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFCFD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0EAEE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icono,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final escala = (MediaQuery.textScalerOf(context).scale(14) / 14)
                .clamp(1.0, 2.0);
            const espacio = 16.0;
            final columnas =
                ((constraints.maxWidth + espacio) / (220 * escala + espacio))
                    .floor()
                    .clamp(1, maximoColumnas);
            final ancho =
                (constraints.maxWidth - espacio * (columnas - 1)) / columnas;
            return Wrap(
              spacing: espacio,
              runSpacing: 16,
              children: [
                for (final child in children)
                  SizedBox(width: ancho, child: child),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class ResultadoFormularioTrabajadorAdmin {
  const ResultadoFormularioTrabajadorAdmin({
    required this.trabajador,
    required this.password,
  });

  final TrabajadorAdmin trabajador;
  final String password;
}

class _ChipInfoAdmin extends StatelessWidget {
  const _ChipInfoAdmin({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoSuave,
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        border: Border.all(color: ColoresSistema.bordeIntermedio),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: ColoresPanel.turquesa),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ColoresSistema.textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ColoresSistema.textoTitulo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaTrabajadorAdmin extends StatelessWidget {
  const _TarjetaTrabajadorAdmin({
    required this.trabajador,
    required this.onEditar,
    required this.onRestablecerContrasena,
    required this.onAlternarEstado,
  });

  final TrabajadorAdmin trabajador;
  final VoidCallback? onEditar;
  final VoidCallback? onRestablecerContrasena;
  final VoidCallback? onAlternarEstado;

  @override
  Widget build(BuildContext context) {
    final colorEstado = trabajador.estadoActivo
        ? const Color(0xFF146C43)
        : ColoresSistema.rojoInstitucional;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoSuave,
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: ColoresSistema.bordeIntermedio),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final informacion = _informacionTrabajador(context);
          final estado = _estadoTrabajador(context, colorEstado);
          final acciones = _accionesTrabajador(context);

          if (constraints.maxWidth < 900 ||
              MediaQuery.textScalerOf(context).scale(15) > 20) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconoTrabajador(),
                    const SizedBox(width: 12),
                    Expanded(child: informacion),
                  ],
                ),
                const SizedBox(height: 12),
                estado,
                const SizedBox(height: 8),
                acciones,
              ],
            );
          }

          return Row(
            children: [
              _iconoTrabajador(),
              const SizedBox(width: 14),
              Expanded(child: informacion),
              const SizedBox(width: 12),
              estado,
              const SizedBox(width: 8),
              acciones,
            ],
          );
        },
      ),
    );
  }

  Widget _iconoTrabajador() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: ColoresPanel.turquesa.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.person_outline, color: ColoresPanel.turquesa),
    );
  }

  Widget _informacionTrabajador(BuildContext context) {
    final estilo = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: ColoresSistema.textoBase);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trabajador.nombreCompleto,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: ColoresSistema.textoTitulo,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text('Correo: ${trabajador.correo}', style: estilo),
            Text('Teléfono: ${trabajador.telefono}', style: estilo),
            Text('Área: ${trabajador.area}', style: estilo),
            Text(
              'Cargo: ${trabajador.cargo}',
              style: estilo?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Text(
          '${trabajador.rol} - ${trabajador.sede}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColoresSistema.textoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _estadoTrabajador(BuildContext context, Color colorEstado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorEstado.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
      ),
      child: Text(
        trabajador.estadoActivo ? 'Activo' : 'Inactivo',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorEstado,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _accionesTrabajador(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 2,
      runSpacing: 2,
      children: [
        IconButton(
          tooltip: 'Editar trabajador',
          onPressed: onEditar,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Rostro y celular autorizado',
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => DialogoBiometriaAdmin(
              uid: trabajador.id,
              nombre: trabajador.nombreCompleto,
            ),
          ),
          icon: const Icon(Icons.phonelink_lock),
        ),
        IconButton(
          tooltip: 'Restablecer contrasena',
          onPressed: onRestablecerContrasena,
          icon: const Icon(Icons.lock_reset_outlined),
        ),
        IconButton(
          tooltip: trabajador.estadoActivo
              ? 'Desactivar trabajador'
              : 'Activar trabajador',
          onPressed: onAlternarEstado,
          icon: Icon(
            trabajador.estadoActivo
                ? Icons.toggle_on_outlined
                : Icons.toggle_off_outlined,
          ),
        ),
      ],
    );
  }
}
