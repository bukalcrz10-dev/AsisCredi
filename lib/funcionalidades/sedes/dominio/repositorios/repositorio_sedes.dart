import '../entidades/sede.dart';

// Contrato del modulo de sedes para recuperar la sede asociada al trabajador.
abstract class RepositorioSedes {
  Future<Sede?> obtenerSedePorId(String id);

  Future<void> guardarSede(Sede sede);
}
