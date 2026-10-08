class TrabajadorAdminDemo {
  const TrabajadorAdminDemo({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.telefono,
    required this.area,
    required this.cargo,
    required this.rol,
    required this.estadoActivo,
    required this.sede,
    this.sedeId = '',
  });

  final String id;
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String area;
  final String cargo;
  final String rol;
  final bool estadoActivo;
  final String sede;
  final String sedeId;

  bool requiereActualizarAcceso(TrabajadorAdminDemo anterior) =>
      id != anterior.id ||
      correo.trim().toLowerCase() != anterior.correo.trim().toLowerCase() ||
      rol.toLowerCase() != anterior.rol.toLowerCase() ||
      estadoActivo != anterior.estadoActivo;

  TrabajadorAdminDemo copyWith({
    String? id,
    String? nombreCompleto,
    String? correo,
    String? telefono,
    String? area,
    String? cargo,
    String? rol,
    bool? estadoActivo,
    String? sede,
    String? sedeId,
  }) {
    return TrabajadorAdminDemo(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      area: area ?? this.area,
      cargo: cargo ?? this.cargo,
      rol: rol ?? this.rol,
      estadoActivo: estadoActivo ?? this.estadoActivo,
      sede: sede ?? this.sede,
      sedeId: sedeId ?? this.sedeId,
    );
  }
}
