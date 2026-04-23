import 'package:flutter/material.dart';

import '../../../autenticacion/datos/fuentes_datos/fuente_datos_autenticacion_firebase.dart';
import '../../../autenticacion/datos/repositorios/repositorio_autenticacion_impl.dart';
import '../../../autenticacion/dominio/casos_de_uso/cerrar_sesion.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../paginas/pagina_inicio_sesion_admin.dart';
import '../paginas/pagina_panel_admin.dart';

class CompuertaAdmin extends StatefulWidget {
  const CompuertaAdmin({super.key});

  @override
  State<CompuertaAdmin> createState() => _CompuertaAdminState();
}

class _CompuertaAdminState extends State<CompuertaAdmin> {
  late final FuenteDatosAutenticacionFirebase _fuenteDatosAutenticacion;
  late final RepositorioAutenticacionImpl _repositorioAutenticacion;
  late final RepositorioUsuariosImpl _repositorioUsuarios;
  late final CerrarSesion _cerrarSesion;

  String? _mensajeAcceso;
  bool _cerrandoSesionForzada = false;

  @override
  void initState() {
    super.initState();
    _fuenteDatosAutenticacion = FuenteDatosAutenticacionFirebase();
    _repositorioAutenticacion = RepositorioAutenticacionImpl(
      _fuenteDatosAutenticacion,
    );
    _repositorioUsuarios = RepositorioUsuariosImpl(
      FuenteDatosUsuariosFirestore(),
    );
    _cerrarSesion = CerrarSesion(_repositorioAutenticacion);
  }

  Future<void> _forzarSalidaConMensaje(String mensaje) async {
    if (_cerrandoSesionForzada) {
      return;
    }

    _cerrandoSesionForzada = true;
    setState(() {
      _mensajeAcceso = mensaje;
    });

    await _cerrarSesion.ejecutar();

    if (!mounted) {
      return;
    }

    setState(() {
      _cerrandoSesionForzada = false;
    });
  }

  Widget _buildCargando() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _repositorioAutenticacion.sesionIniciada(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _cerrandoSesionForzada) {
          return _buildCargando();
        }

        if (snapshot.data != true) {
          return PaginaInicioSesionAdmin(mensajeInicial: _mensajeAcceso);
        }

        final usuarioAuth = _fuenteDatosAutenticacion.obtenerUsuarioActual();
        if (usuarioAuth == null) {
          return PaginaInicioSesionAdmin(mensajeInicial: _mensajeAcceso);
        }

        return FutureBuilder<Usuario?>(
          future: _repositorioUsuarios.obtenerUsuarioPorId(usuarioAuth.uid),
          builder: (context, perfilSnapshot) {
            if (perfilSnapshot.connectionState == ConnectionState.waiting) {
              return _buildCargando();
            }

            final perfil = perfilSnapshot.data;

            if (perfil == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _forzarSalidaConMensaje(
                  'Tu cuenta autenticada no tiene perfil administrativo registrado en Firestore.',
                );
              });
              return _buildCargando();
            }

            if (!perfil.activo) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _forzarSalidaConMensaje(
                  'Tu cuenta administrativa esta inactiva. Contacta con el responsable del sistema.',
                );
              });
              return _buildCargando();
            }

            if (perfil.rol != RolUsuario.administrador) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _forzarSalidaConMensaje(
                  'Esta cuenta no tiene permisos para ingresar al panel administrativo.',
                );
              });
              return _buildCargando();
            }

            if (_mensajeAcceso != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _mensajeAcceso = null;
                });
              });
            }

            return PaginaPanelAdmin(
              usuarioAdministrador: perfil,
              onCerrarSesion: _cerrarSesion.ejecutar,
            );
          },
        );
      },
    );
  }
}
