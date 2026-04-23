import '../../datos/fuentes_datos/fuente_datos_autenticacion_firebase.dart';
import '../../datos/repositorios/repositorio_autenticacion_impl.dart';
import '../../dominio/casos_de_uso/iniciar_sesion.dart';
import 'controlador_inicio_sesion.dart';

ControladorInicioSesion crearControladorInicioSesion() {
  final fuenteDatos = FuenteDatosAutenticacionFirebase();
  final repositorio = RepositorioAutenticacionImpl(fuenteDatos);
  final casoUso = IniciarSesion(repositorio);

  return ControladorInicioSesion(
    iniciarSesion: casoUso,
  );
}
