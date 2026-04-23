import 'package:firebase_auth/firebase_auth.dart';

import '../../../alertas/datos/fuentes_datos/fuente_datos_alertas_firestore.dart';
import '../../../alertas/datos/repositorios/repositorio_alertas_impl.dart';
import '../../../alertas/dominio/casos_de_uso/obtener_alertas_por_usuario.dart';
import '../../../alertas/dominio/casos_de_uso/registrar_alerta.dart';
import '../../../geolocalizacion/datos/fuentes_datos/fuente_datos_geolocalizacion_dispositivo.dart';
import '../../../geolocalizacion/datos/repositorios/repositorio_geolocalizacion_impl.dart';
import '../../../geolocalizacion/dominio/casos_de_uso/validar_ubicacion_actual.dart';
import '../../../reconocimiento_facial/datos/fuentes_datos/fuente_datos_detector_rostro_mlkit.dart';
import '../../../reconocimiento_facial/datos/fuentes_datos/fuente_datos_evidencia_facial_storage.dart';
import '../../../reconocimiento_facial/datos/repositorios/repositorio_evidencia_facial_impl.dart';
import '../../../reconocimiento_facial/datos/repositorios/repositorio_reconocimiento_facial_impl.dart';
import '../../../reconocimiento_facial/dominio/casos_de_uso/subir_evidencia_facial.dart';
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

class DependenciasAsistencia {
  const DependenciasAsistencia({
    required this.controlador,
    required this.repositorioReconocimientoFacial,
  });

  final ControladorAsistencia controlador;
  final RepositorioReconocimientoFacialImpl repositorioReconocimientoFacial;
}

DependenciasAsistencia crearDependenciasAsistencia({
  required User? usuarioAutenticado,
}) {
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
  final repositorioReconocimientoFacial =
      RepositorioReconocimientoFacialImpl(fuenteDatosRostro);

  final controlador = ControladorAsistencia(
    obtenerAlertasPorUsuario: ObtenerAlertasPorUsuario(repositorioAlertas),
    registrarAlerta: RegistrarAlerta(repositorioAlertas),
    registrarAsistencia: RegistrarAsistencia(repositorioAsistencias),
    obtenerAsistenciasPorUsuario:
        ObtenerAsistenciasPorUsuario(repositorioAsistencias),
    obtenerPerfilTrabajadorActual: ObtenerPerfilTrabajadorActual(
      obtenerUsuarioPorId: ObtenerUsuarioPorId(repositorioUsuarios),
      obtenerSedePorId: ObtenerSedePorId(repositorioSedes),
    ),
    subirEvidenciaFacial: SubirEvidenciaFacial(repositorioEvidenciaFacial),
    validarRostroCapturado:
        ValidarRostroCapturado(repositorioReconocimientoFacial),
    validarUbicacionActual:
        ValidarUbicacionActual(repositorioGeolocalizacion),
    usuarioIdAutenticado: usuarioAutenticado?.uid ?? '',
    nombreAutenticado: usuarioAutenticado?.displayName,
    correoAutenticado: usuarioAutenticado?.email,
  );

  return DependenciasAsistencia(
    controlador: controlador,
    repositorioReconocimientoFacial: repositorioReconocimientoFacial,
  );
}
