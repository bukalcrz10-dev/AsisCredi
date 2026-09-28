import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../datos/servicios/servicio_trabajadores_auth_functions.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../../presentacion/modelos/trabajador_admin_demo.dart';
import 'contenedor_modulo_admin.dart';
import '../../../../app/diseno_sistema.dart';

class ModuloTrabajadoresAdmin extends StatefulWidget {
  const ModuloTrabajadoresAdmin({super.key});

  @override
  State<ModuloTrabajadoresAdmin> createState() =>
      _ModuloTrabajadoresAdminState();
}

class _ModuloTrabajadoresAdminState extends State<ModuloTrabajadoresAdmin> {
  static const _sedePrincipalId = 'sede_principal';
  static const _sedePrincipalNombre = 'Sede Principal';

  final RepositorioUsuariosImpl _repositorioUsuarios =
      RepositorioUsuariosImpl(FuenteDatosUsuariosFirestore());
  final ServicioTrabajadoresAuthFunctions _servicioAuthFunctions =
      ServicioTrabajadoresAuthFunctions();
  final TextEditingController _busquedaController = TextEditingController();

  List<TrabajadorAdminDemo> _trabajadores = const [];
  bool _cargando = true;
  bool _guardando = false;
  String _busqueda = '';
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarTrabajadores();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarTrabajadores() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      final usuarios = await _repositorioUsuarios.obtenerUsuarios();
      final trabajadores = usuarios
          .map<TrabajadorAdminDemo>(_mapearUsuarioATrabajador)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _trabajadores = trabajadores;
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

  TrabajadorAdminDemo _mapearUsuarioATrabajador(Usuario usuario) {
    return TrabajadorAdminDemo(
      id: usuario.id,
      nombreCompleto: usuario.nombreCompleto,
      correo: usuario.correo,
      telefono: usuario.telefono,
      area: usuario.area,
      cargo: usuario.cargo,
      rol: usuario.rol == RolUsuario.administrador
          ? 'Administrador'
          : 'Trabajador',
      estadoActivo: usuario.activo,
      sede: usuario.sedeAsignadaId == _sedePrincipalId
          ? _sedePrincipalNombre
          : (usuario.sedeAsignadaId.isEmpty
              ? _sedePrincipalNombre
              : usuario.sedeAsignadaId),
    );
  }

  Future<void> _guardarTrabajador(TrabajadorAdminDemo trabajador) async {
    setState(() {
      _guardando = true;
      _mensajeError = null;
    });

    try {
      await _servicioAuthFunctions.actualizarTrabajador(
        uid: trabajador.id,
        nombreCompleto: trabajador.nombreCompleto,
        correo: trabajador.correo,
        telefono: trabajador.telefono,
        area: trabajador.area,
        cargo: trabajador.cargo,
        rol: trabajador.rol,
        activo: trabajador.estadoActivo,
        sedeAsignadaId: _sedePrincipalId,
      );
      await _cargarTrabajadores();
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
    _ResultadoDialogoTrabajadorAdmin resultado,
  ) async {
    setState(() {
      _guardando = true;
      _mensajeError = null;
    });

    try {
      await _servicioAuthFunctions.crearTrabajadorConAcceso(
        nombreCompleto: resultado.trabajador.nombreCompleto,
        correo: resultado.trabajador.correo,
        telefono: resultado.trabajador.telefono,
        area: resultado.trabajador.area,
        cargo: resultado.trabajador.cargo,
        rol: resultado.trabajador.rol,
        activo: resultado.trabajador.estadoActivo,
        sedeAsignadaId: _sedePrincipalId,
        password: resultado.password,
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
        _mensajeError =
            partes.isNotEmpty
                ? partes.join(' | ')
                : 'No se pudo crear el trabajador en Authentication.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
        _mensajeError =
            'No se pudo crear el trabajador en Authentication.';
      });
    }
  }

  Future<void> _abrirDialogoNuevoTrabajador() async {
    final resultado = await showDialog<_ResultadoDialogoTrabajadorAdmin>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DialogoTrabajadorAdmin(),
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

  Future<void> _abrirDialogoEditarTrabajador(
    TrabajadorAdminDemo trabajador,
  ) async {
    final resultado = await showDialog<_ResultadoDialogoTrabajadorAdmin>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoTrabajadorAdmin(
        trabajadorInicial: trabajador,
      ),
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _guardarTrabajador(resultado.trabajador);
  }

  Future<void> _alternarEstadoTrabajador(TrabajadorAdminDemo trabajador) async {
    await _guardarTrabajador(
      trabajador.copyWith(
        estadoActivo: !trabajador.estadoActivo,
      ),
    );
  }

  Future<void> _restablecerContrasenaTrabajador(
    TrabajadorAdminDemo trabajador,
    String nuevaContrasena,
  ) async {
    setState(() {
      _guardando = true;
      _mensajeError = null;
    });

    try {
      await _servicioAuthFunctions.restablecerContrasenaTrabajador(
        uid: trabajador.id,
        password: nuevaContrasena,
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
          content: Text('Contrasena restablecida correctamente.'),
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
    TrabajadorAdminDemo trabajador,
  ) async {
    final nuevaContrasena = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoRestablecerContrasenaTrabajador(
        nombreTrabajador: trabajador.nombreCompleto,
      ),
    );

    if (nuevaContrasena == null || !mounted) {
      return;
    }

    await _restablecerContrasenaTrabajador(trabajador, nuevaContrasena);
  }

  List<TrabajadorAdminDemo> get _trabajadoresFiltrados {
    final consulta = _busqueda.trim().toLowerCase();
    if (consulta.isEmpty) {
      return _trabajadores;
    }

    return _trabajadores.where((trabajador) {
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
                    valor: 'UNACHU',
                  ),
                ],
              ),
              if (_mensajeError != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ColoresSistema.rojoInstitucional.withValues(
                      alpha: 0.08,
                    ),
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
                'Listado de trabajadores',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Busca por nombre, correo, telefono, area, cargo, rol o sede.',
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Registros encontrados: ${trabajadores.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ColoresSistema.rojoInstitucionalOscuro,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 18),
              if (_cargando)
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
                        : 'No se encontraron trabajadores con esa busqueda.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColoresSistema.textoSecundario,
                        ),
                  ),
                )
              else
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
                          : () => _abrirDialogoRestablecerContrasena(
                              trabajador,
                            ),
                      onAlternarEstado: _guardando
                          ? null
                          : () => _alternarEstadoTrabajador(trabajador),
                    ),
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

class _DialogoTrabajadorAdmin extends StatefulWidget {
  const _DialogoTrabajadorAdmin({
    this.trabajadorInicial,
  });

  final TrabajadorAdminDemo? trabajadorInicial;

  @override
  State<_DialogoTrabajadorAdmin> createState() => _DialogoTrabajadorAdminState();
}

class _DialogoTrabajadorAdminState extends State<_DialogoTrabajadorAdmin> {
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _areaController;
  late final TextEditingController _cargoController;
  late final TextEditingController _sedeController;
  late final TextEditingController _passwordController;
  late String _rol;
  late bool _estadoActivo;
  bool _mostrarPassword = false;

  @override
  void initState() {
    super.initState();
    final trabajador = widget.trabajadorInicial;
    _nombreController = TextEditingController(
      text: trabajador?.nombreCompleto ?? '',
    );
    _correoController = TextEditingController(
      text: trabajador?.correo ?? '',
    );
    _telefonoController = TextEditingController(
      text: trabajador?.telefono ?? '',
    );
    _areaController = TextEditingController(
      text: trabajador?.area ?? '',
    );
    _cargoController = TextEditingController(
      text: trabajador?.cargo ?? '',
    );
    _sedeController = TextEditingController(
      text: trabajador?.sede ?? _ModuloTrabajadoresAdminState._sedePrincipalNombre,
    );
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
    _cargoController.dispose();
    _sedeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _guardar() {
    final editando = widget.trabajadorInicial != null;
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final telefono = _telefonoController.text.trim();
    final area = _areaController.text.trim();
    final cargo = _cargoController.text.trim();
    final sede = _sedeController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty ||
        correo.isEmpty ||
        telefono.isEmpty ||
        area.isEmpty ||
        cargo.isEmpty ||
        sede.isEmpty ||
        (!editando && password.isEmpty)) {
      return;
    }

    if (!editando && password.length < 6) {
      return;
    }

    final trabajador = TrabajadorAdminDemo(
      id: widget.trabajadorInicial?.id ?? _generarId(nombre),
      nombreCompleto: nombre,
      correo: correo,
      telefono: telefono,
      area: area,
      cargo: cargo,
      rol: _rol,
      estadoActivo: _estadoActivo,
      sede: sede,
    );

    Navigator.of(context).pop(
      _ResultadoDialogoTrabajadorAdmin(
        trabajador: trabajador,
        password: password,
      ),
    );
  }

  String _generarId(String nombre) {
    final iniciales = nombre
        .split(' ')
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte[0].toUpperCase())
        .join()
        .padRight(2, 'X');
    final sufijo = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(9);
    return 'TR-$iniciales-$sufijo';
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.trabajadorInicial != null;

    return AlertDialog(
      title: Text(
        editando ? 'Editar trabajador' : 'Nuevo trabajador',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editando
                    ? 'Actualiza los datos base del trabajador seleccionado.'
                    : 'Ingresa los datos base para registrar un trabajador con acceso al sistema.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresSistema.textoSecundario,
                    ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cargoController,
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                ),
              ),
              if (!editando) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contrasena inicial',
                    helperText:
                        'Minimo 6 caracteres. La definira el administrador.',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _mostrarPassword = !_mostrarPassword;
                        });
                      },
                      icon: Icon(
                        _mostrarPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _rol,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                      ),
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
                        if (valor == null) {
                          return;
                        }
                        setState(() {
                          _rol = valor;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _sedeController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Sede asignada',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cuenta activa'),
                subtitle: const Text('Estado actual del trabajador.'),
                value: _estadoActivo,
                onChanged: (valor) {
                  setState(() {
                    _estadoActivo = valor;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: Text(editando ? 'Guardar cambios' : 'Guardar'),
        ),
      ],
    );
  }
}

class _ResultadoDialogoTrabajadorAdmin {
  const _ResultadoDialogoTrabajadorAdmin({
    required this.trabajador,
    required this.password,
  });

  final TrabajadorAdminDemo trabajador;
  final String password;
}

class _DialogoRestablecerContrasenaTrabajador extends StatefulWidget {
  const _DialogoRestablecerContrasenaTrabajador({
    required this.nombreTrabajador,
  });

  final String nombreTrabajador;

  @override
  State<_DialogoRestablecerContrasenaTrabajador> createState() =>
      _DialogoRestablecerContrasenaTrabajadorState();
}

class _DialogoRestablecerContrasenaTrabajadorState
    extends State<_DialogoRestablecerContrasenaTrabajador> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmacionController;
  bool _mostrarPassword = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmacionController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmacionController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final password = _passwordController.text.trim();
    final confirmacion = _confirmacionController.text.trim();

    if (password.isEmpty || confirmacion.isEmpty) {
      return;
    }

    if (password.length < 6 || password != confirmacion) {
      return;
    }

    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Restablecer contrasena',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Define una nueva contrasena para ${widget.nombreTrabajador}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresSistema.textoSecundario,
                    ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _passwordController,
                obscureText: !_mostrarPassword,
                decoration: InputDecoration(
                  labelText: 'Nueva contrasena',
                  helperText: 'Minimo 6 caracteres.',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _mostrarPassword = !_mostrarPassword;
                      });
                    },
                    icon: Icon(
                      _mostrarPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmacionController,
                obscureText: !_mostrarPassword,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contrasena',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _confirmar,
          icon: const Icon(Icons.lock_reset_outlined),
          label: const Text('Restablecer'),
        ),
      ],
    );
  }
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
          Icon(icono, size: 18, color: ColoresSistema.rojoInstitucional),
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

  final TrabajadorAdminDemo trabajador;
  final VoidCallback? onEditar;
  final VoidCallback? onRestablecerContrasena;
  final VoidCallback? onAlternarEstado;

  @override
  Widget build(BuildContext context) {
    final colorEstado = trabajador.estadoActivo
        ? ColoresSistema.verdeInstitucional
        : ColoresSistema.rojoInstitucional;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoSuave,
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: ColoresSistema.bordeIntermedio),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ColoresSistema.rojoInstitucional.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline,
              color: ColoresSistema.rojoInstitucional,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
                Text(
                  'Correo: ${trabajador.correo}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.textoBase,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Telefono: ${trabajador.telefono}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.textoBase,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Area: ${trabajador.area}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.textoBase,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cargo: ${trabajador.cargo}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.textoBase,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trabajador.rol} - ${trabajador.sede}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.textoSecundario,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
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
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Editar trabajador',
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Restablecer contrasena',
            onPressed: onRestablecerContrasena,
            icon: const Icon(Icons.lock_reset_outlined),
          ),
          const SizedBox(width: 4),
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
      ),
    );
  }
}
