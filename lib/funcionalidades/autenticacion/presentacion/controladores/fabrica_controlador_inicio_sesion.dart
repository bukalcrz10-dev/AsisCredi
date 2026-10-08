import '../../datos/fuentes_datos/fuente_datos_autenticacion_firebase.dart';
import '../../datos/repositorios/repositorio_autenticacion_impl.dart';
import '../../dominio/casos_de_uso/iniciar_sesion.dart';
import 'controlador_inicio_sesion.dart';
import 'sesion_trabajador.dart';

ControladorInicioSesion crearControladorInicioSesion({bool trabajador = false}) {
  final fuenteDatos = FuenteDatosAutenticacionFirebase();
  final repositorio = RepositorioAutenticacionImpl(fuenteDatos);
  final casoUso = IniciarSesion(repositorio);

  return ControladorInicioSesion(
    iniciarSesion: casoUso,
    iniciarConPolitica: trabajador ? (mantener, ingresar) =>
      SesionTrabajador.instancia.autenticar(
        mantener: mantener,
        ingresar: ingresar,
        usuarioActual: () => fuenteDatos.obtenerUsuarioActual()?.uid,
        cerrar: fuenteDatos.cerrarSesion,
      ) : null,
  );
}
