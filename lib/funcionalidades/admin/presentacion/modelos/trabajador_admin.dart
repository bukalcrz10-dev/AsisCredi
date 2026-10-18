class TrabajadorAdmin {
  const TrabajadorAdmin({
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
    this.fechaInicioLabores,
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
  final DateTime? fechaInicioLabores;

  bool requiereActualizarAcceso(TrabajadorAdmin anterior) =>
      id != anterior.id ||
      correo.trim().toLowerCase() != anterior.correo.trim().toLowerCase() ||
      rol.toLowerCase() != anterior.rol.toLowerCase() ||
      estadoActivo != anterior.estadoActivo;

  TrabajadorAdmin copyWith({
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
    DateTime? fechaInicioLabores,
  }) {
    return TrabajadorAdmin(
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
      fechaInicioLabores: fechaInicioLabores ?? this.fechaInicioLabores,
    );
  }
}
