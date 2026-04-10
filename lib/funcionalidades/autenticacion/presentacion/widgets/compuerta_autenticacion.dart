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

  @override
  void initState() {
    super.initState();
    _fuenteDatos = FuenteDatosAutenticacionFirebase();
    _repositorio = RepositorioAutenticacionImpl(_fuenteDatos);
    _cerrarSesion = CerrarSesion(_repositorio);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _repositorio.sesionIniciada(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          final usuarioAutenticado = _fuenteDatos.obtenerUsuarioActual();

          if (usuarioAutenticado == null) {
            return const PaginaInicioSesion();
          }

          return PaginaInicio(
            usuarioAutenticado: usuarioAutenticado,
            onCerrarSesion: _cerrarSesion.ejecutar,
          );
        }

        return const PaginaInicioSesion();
      },
    );
  }
}
