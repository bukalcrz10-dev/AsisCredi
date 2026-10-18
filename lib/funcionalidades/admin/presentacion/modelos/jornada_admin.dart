import '../../../asistencias/dominio/entidades/asistencia.dart';

/// La sede pertenece a la marca, no a la identidad de la jornada.
String claveJornadaAdmin(Asistencia marca) =>
    '${marca.usuarioId}|${marca.fechaHora.year}-${marca.fechaHora.month}-${marca.fechaHora.day}';
