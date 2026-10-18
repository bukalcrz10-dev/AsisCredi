import 'package:firebase_auth/firebase_auth.dart';

import '../../../geolocalizacion/datos/fuentes_datos/fuente_datos_geolocalizacion_dispositivo.dart';
import '../../../geolocalizacion/datos/repositorios/repositorio_geolocalizacion_impl.dart';
import '../../../geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import '../../../reconocimiento_facial/seguridad/servicio_seguridad_biometrica.dart';
import '../../../reconocimiento_facial/datos/repositorios/repositorio_reconocimiento_facial_impl.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/validar_rostro_capturado.dart';
import '../../../sedes/datos/fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../../../sedes/datos/repositorios/repositorio_sedes_impl.dart';
import '../../../sedes/dominio/casos_de_uso/obtener_sede_por_id.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../../usuarios/dominio/casos_de_uso/obtener_usuario_por_id.dart';
import '../../datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../../datos/repositorios/repositorio_asistencias_impl.dart';
import '../../dominio/casos_de_uso/obtener_asistencias_por_usuario.dart';
import '../../dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import '../../dominio/casos_de_uso/registrar_asistencia.dart';
import 'controlador_asistencia.dart';
import 'monitor_conexion.dart';

class DependenciasAsistencia {
  const DependenciasAsistencia({
    required this.controlador,
    required this.repositorioReconocimientoFacial,
    this.seguridad,
  });

  final ControladorAsistencia controlador;
  final ServicioSeguridadBiometrica? seguridad;
  final RepositorioReconocimientoFacialImpl repositorioReconocimientoFacial;
}

DependenciasAsistencia crearDependenciasAsistencia({
  required User? usuarioAutenticado,
}) {
  final seguridad = ServicioSeguridadBiometrica(usuarioAutenticado?.uid ?? '');
  final fuenteDatosAsistencias = FuenteDatosAsistenciasFirestore(
    guardarConSeguridad: seguridad.guardarMarcacion,
  );
  final repositorioAsistencias = RepositorioAsistenciasImpl(
    fuenteDatosAsistencias,
    marcacionUnicaPorBloque: true,
  );
  final fuenteDatosUsuarios = FuenteDatosUsuariosFirestore(soloServidor: true);
  final repositorioUsuarios = RepositorioUsuariosImpl(fuenteDatosUsuarios);
  final fuenteDatosSedes = FuenteDatosSedesFirestore(soloServidor: true);
  final repositorioSedes = RepositorioSedesImpl(fuenteDatosSedes);
  final fuenteDatosGeolocalizacion = FuenteDatosGeolocalizacionDispositivo();
  final repositorioGeolocalizacion = RepositorioGeolocalizacionImpl(
    fuenteDatosGeolocalizacion,
  );
  final repositorioReconocimientoFacial =
      RepositorioReconocimientoFacialImpl.seguro(seguridad.resultadoPara);

  final controlador = ControladorAsistencia(
    comprobarSeguridad: seguridad.comprobarValidacion,
    alLimpiarRostro: seguridad.limpiar,
    monitorConexion: MonitorConexion(
      comprobar: () async {
        final uid = usuarioAutenticado?.uid;
        if (uid == null) return false;
        // Esta fuente exige Source.server; la caché no confirma conectividad.
        await fuenteDatosUsuarios.obtenerUsuarioPorId(uid);
        return true;
      },
    ),
    registrarAsistencia: RegistrarAsistencia(repositorioAsistencias),
    obtenerAsistenciasPorUsuario: ObtenerAsistenciasPorUsuario(
      repositorioAsistencias,
    ),
    obtenerPerfilTrabajadorActual: ObtenerPerfilTrabajadorActual(
      obtenerUsuarioPorId: ObtenerUsuarioPorId(repositorioUsuarios),
      obtenerSedePorId: ObtenerSedePorId(repositorioSedes),
    ),
    validarRostroCapturado: ValidarRostroCapturado(
      repositorioReconocimientoFacial,
    ),
    validarUbicacionActual: ValidarUbicacionActual(repositorioGeolocalizacion),
    usuarioIdAutenticado: usuarioAutenticado?.uid ?? '',
    nombreAutenticado: usuarioAutenticado?.displayName,
    correoAutenticado: usuarioAutenticado?.email,
  );

  return DependenciasAsistencia(
    seguridad: seguridad,
    controlador: controlador,
    repositorioReconocimientoFacial: repositorioReconocimientoFacial,
  );
}
