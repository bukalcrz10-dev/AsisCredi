import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/repositorios/repositorio_sedes.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/casos_de_uso/obtener_sede_por_id.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/rol_usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/repositorios/repositorio_usuarios.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/casos_de_uso/obtener_usuario_por_id.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/casos_de_uso/obtener_perfil_trabajador_actual.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_marcacion_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/dialogo_sedes_admin.dart';

class _Usuarios extends Fake implements RepositorioUsuarios {
  _Usuarios(this.sede);
  final String sede;
  @override
  Future<Usuario?> obtenerUsuarioPorId(String id) async => Usuario(id:id,nombreCompleto:'Ana',correo:'a@example.com',cargo:'Asesor',rol:RolUsuario.trabajador,sedeAsignadaId:sede);
}
class _Sedes extends Fake implements RepositorioSedes {
  _Sedes(this.sedes);
  final Map<String,Sede> sedes;
  @override
  Future<Sede?> obtenerSedePorId(String id) async => sedes[id];
}

void main() {
  // Coordenadas sintéticas de prueba; no se usan para configurar oficinas reales.
  const huancayo=Sede(id:'sede_huancayo',nombre:'Huancayo',latitud:-12,longitud:-75,radioPermitidoMetros:40);
  const satipo=Sede(id:'sede_satipo',nombre:'Satipo',latitud:-11,longitud:-74,radioPermitidoMetros:60);
  final sedes={huancayo.id:huancayo,satipo.id:satipo};
  for(final sede in [huancayo,satipo]) {
    test('El perfil usa exclusivamente coordenadas y radio de ${sede.nombre}',() async {
      final perfil=await ObtenerPerfilTrabajadorActual(obtenerUsuarioPorId:ObtenerUsuarioPorId(_Usuarios(sede.id)),obtenerSedePorId:ObtenerSedePorId(_Sedes(sedes))).ejecutar(usuarioId:'u1');
      expect(perfil!.sedeId,sede.id);
      expect(perfil.nombreSede,sede.nombre);
      expect(perfil.latitudSede,sede.latitud);
      expect(perfil.longitudSede,sede.longitud);
      expect(perfil.radioPermitidoMetros,sede.radioPermitidoMetros);
      expect(perfil.cargo,'Asesor');
    });
  }
  test('Sede inexistente no redirige a Huancayo ni Satipo',() async {
    final perfil=await ObtenerPerfilTrabajadorActual(obtenerUsuarioPorId:ObtenerUsuarioPorId(_Usuarios('desconocida')),obtenerSedePorId:ObtenerSedePorId(_Sedes(sedes))).ejecutar(usuarioId:'u1');
    expect(perfil!.sede,isNull);
    expect(obtenerRechazoContextoBasicoMarcacion(perfil:perfil,validandoUbicacion:false),isNotNull);
  });
  test('Sede inactiva no permite marcar',() async {
    const inactiva=Sede(id:'sede_satipo',nombre:'Satipo',latitud:-11,longitud:-74,radioPermitidoMetros:60,activa:false);
    final perfil=await ObtenerPerfilTrabajadorActual(obtenerUsuarioPorId:ObtenerUsuarioPorId(_Usuarios(inactiva.id)),obtenerSedePorId:ObtenerSedePorId(_Sedes({inactiva.id:inactiva}))).ejecutar(usuarioId:'u1');
    expect(obtenerRechazoContextoBasicoMarcacion(perfil:perfil,validandoUbicacion:false)!.mensaje,contains('inactiva'));
  });
  test('La configuración rechaza coordenadas fuera de rango y radios inválidos',() {
    expect(validarNumeroSede('91',-90,90),isNotNull);
    expect(validarNumeroSede('NaN',-180,180),isNotNull);
    expect(validarNumeroSede('0',0.01,double.infinity),isNotNull);
    expect(validarNumeroSede('Infinity',0.01,double.infinity),isNotNull);
    expect(validarNumeroSede('-12,34',-90,90),isNull);
  });
}
