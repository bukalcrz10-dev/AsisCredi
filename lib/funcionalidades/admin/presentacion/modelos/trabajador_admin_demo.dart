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
    );
  }
}
