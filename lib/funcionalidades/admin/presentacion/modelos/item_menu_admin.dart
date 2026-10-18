import 'package:flutter/material.dart';

class ItemMenuAdmin {
  const ItemMenuAdmin({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.grupoId,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final IconData icono;
  final String? grupoId;
}
