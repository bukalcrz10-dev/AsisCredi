// Dobles de Firestore para verificar el mapa enviado sin acceder a Firebase.
// ignore_for_file: subtype_of_sealed_class

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/trabajador_admin_demo.dart';
import 'package:asistencia_app/funcionalidades/usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  final coleccion = _Coleccion();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'usuarios');
    return coleccion;
  }
}

class _Coleccion extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final documento = _Documento();
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    expect(path, 'trabajador-1');
    return documento;
  }
}

class _Documento extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final actualizado = <Object, Object?>{};
  @override
  Future<void> update(Map<Object, Object?> data) async {
    actualizado.addAll(data);
  }
}

void main() {
  const anterior = TrabajadorAdminDemo(
    id: 'trabajador-1',
    nombreCompleto: 'Ana',
    correo: 'ana@example.com',
    telefono: '123',
    area: 'Atención',
    cargo: 'Trabajador',
    rol: 'Trabajador',
    estadoActivo: true,
    sede: 'Sede Principal',
  );

  test('Editar cargo y perfil no requiere modificar la cuenta de acceso', () {
    expect(
      anterior
          .copyWith(
            cargo: 'Plataforma',
            nombreCompleto: 'Ana Pérez',
            telefono: '456',
            area: 'Ventas',
          )
          .requiereActualizarAcceso(anterior),
      isFalse,
    );
  });
  test('Cambios de correo, rol o estado conservan la ruta de acceso', () {
    for (final editado in [
      anterior.copyWith(correo: 'otro@example.com'),
      anterior.copyWith(rol: 'Administrador'),
      anterior.copyWith(estadoActivo: false),
    ]) {
      expect(editado.requiereActualizarAcceso(anterior), isTrue);
    }
  });
  test(
    'Cambiar sede guarda su identificador sin modificar la cuenta de acceso',
    () async {
      final editado = anterior.copyWith(sede: 'Satipo', sedeId: 'sede_satipo');
      expect(editado.requiereActualizarAcceso(anterior), isFalse);
      final firestore = _Firestore();
      await FuenteDatosUsuariosFirestore(
        firestore: firestore,
      ).actualizarDatosLaborales(
        id: 'trabajador-1',
        nombreCompleto: 'Ana',
        telefono: '123',
        area: 'Ventas',
        cargo: 'Asesor',
        sedeAsignadaId: editado.sedeId,
      );
      expect(
        firestore.coleccion.documento.actualizado['sedeAsignadaId'],
        'sede_satipo',
      );
      expect(
        firestore.coleccion.documento.actualizado.containsKey('rol'),
        isFalse,
      );
    },
  );
  test(
    'La actualización parcial no reemplaza fotografía, sede ni permisos',
    () async {
      final firestore = _Firestore();
      await FuenteDatosUsuariosFirestore(
        firestore: firestore,
      ).actualizarDatosLaborales(
        id: 'trabajador-1',
        nombreCompleto: 'Ana Pérez',
        telefono: '456',
        area: 'Ventas',
        cargo: 'Plataforma',
      );
      expect(firestore.coleccion.documento.actualizado, {
        'nombreCompleto': 'Ana Pérez',
        'telefono': '456',
        'area': 'Ventas',
        'cargo': 'Plataforma',
      });
    },
  );
}
