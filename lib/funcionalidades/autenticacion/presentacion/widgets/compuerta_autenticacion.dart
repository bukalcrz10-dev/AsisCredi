import 'package:cloud_firestore/cloud_firestore.dart';
import 'acceso_perfil_activo.dart';
import 'package:flutter/material.dart';

import '../../datos/fuentes_datos/fuente_datos_autenticacion_firebase.dart';
import '../../datos/repositorios/repositorio_autenticacion_impl.dart';
import '../../dominio/casos_de_uso/cerrar_sesion.dart';
import '../../../asistencias/presentacion/paginas/pagina_inicio.dart';
import '../paginas/pagina_inicio_sesion.dart';

// Widget raiz que decide si mostrar login o la pantalla principal.
// Escucha el estado de Firebase Auth para no depender de rutas manuales
// al entrar o salir del sistema.
class CompuertaAutenticacion extends StatefulWidget {
  const CompuertaAutenticacion({super.key});

  @override
  State<CompuertaAutenticacion> createState() => _CompuertaAutenticacionState();
}

class _CompuertaAutenticacionState extends State<CompuertaAutenticacion> {
  late final FuenteDatosAutenticacionFirebase _fuenteDatos;
  late final RepositorioAutenticacionImpl _repositorio;
  late final CerrarSesion _cerrarSesion;
  late final Stream<bool> _sesiones;
  String? _perfilUid;
  Stream<EstadoPerfilActivo>? _perfil;

  @override
  void initState() {
    super.initState();
    _fuenteDatos = FuenteDatosAutenticacionFirebase();
    _repositorio = RepositorioAutenticacionImpl(_fuenteDatos);
    _cerrarSesion = CerrarSesion(_repositorio);
    _sesiones = _repositorio.sesionIniciada();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _sesiones,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          final usuarioAutenticado = _fuenteDatos.obtenerUsuarioActual();

          if (usuarioAutenticado == null) {
            return const PaginaInicioSesion();
          }

          if (_perfilUid != usuarioAutenticado.uid) {
            _perfilUid = usuarioAutenticado.uid;
            _perfil = FirebaseFirestore.instance
                .collection('usuarios')
                .doc(usuarioAutenticado.uid)
                .snapshots(includeMetadataChanges: true)
                .map(
                  (doc) => evaluarPerfilActivo(
                    desdeCache: doc.metadata.isFromCache,
                    existe: doc.exists,
                    activo: doc.data()?['activo'] == true,
                  ),
                );
          }
          return AccesoPerfilActivo(
            key: ValueKey(usuarioAutenticado.uid),
            permisos: _perfil!,
            onCerrarSesion: _cerrarSesion.ejecutar,
            child: PaginaInicio(
              usuarioAutenticado: usuarioAutenticado,
              onCerrarSesion: _cerrarSesion.ejecutar,
            ),
          );
        }

        _perfilUid = null;
        _perfil = null;
        return const PaginaInicioSesion();
      },
    );
  }
}
