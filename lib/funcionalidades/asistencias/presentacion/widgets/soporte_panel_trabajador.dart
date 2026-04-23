import 'package:flutter/material.dart';
import '../../../../app/diseno_sistema.dart';

class TarjetaMensajePanel extends StatelessWidget {
  const TarjetaMensajePanel({
    super.key,
    required this.mensaje,
    required this.color,
    required this.icono,
  });

  final String mensaje;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MedidasSistema.paddingBloque,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(mensaje)),
        ],
      ),
    );
  }
}

class EtiquetaPanelTrabajador extends StatelessWidget {
  const EtiquetaPanelTrabajador({
    super.key,
    required this.titulo,
    required this.contenido,
    this.accion,
  });

  final String titulo;
  final String contenido;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        if (accion == null)
          Container(
            width: double.infinity,
            padding: MedidasSistema.paddingBloque,
            decoration: BoxDecoration(
              color: ColoresSistema.fondoSuaveAlt,
              borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
              border: Border.all(color: ColoresSistema.bordeCampo),
            ),
            child: Text(contenido),
          )
        else
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: MedidasSistema.paddingBloque,
                  decoration: BoxDecoration(
                    color: ColoresSistema.fondoSuaveAlt,
                    borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
                    border: Border.all(color: ColoresSistema.bordeCampo),
                  ),
                  child: Text(contenido),
                ),
              ),
              const SizedBox(width: 10),
              accion!,
            ],
          ),
      ],
    );
  }
}

Color colorMensajePanel(String mensaje) {
  final texto = mensaje.toLowerCase();
  if (texto.contains('correctamente')) return Colors.green;
  if (texto.contains('no pudimos') || texto.contains('primero')) {
    return Colors.red;
  }
  return Colors.blue;
}

IconData iconoMensajePanel(String mensaje) {
  final texto = mensaje.toLowerCase();
  if (texto.contains('correctamente')) return Icons.check_circle_outline;
  if (texto.contains('no pudimos') || texto.contains('primero')) {
    return Icons.error_outline;
  }
  return Icons.info_outline;
}

bool mensajePerteneceABloquePanel(String mensaje, String bloque) {
  final texto = mensaje.toLowerCase();

  if (bloque == 'ubicacion') {
    return texto.contains('ubicacion') ||
        texto.contains('gps') ||
        texto.contains('fuera del radio') ||
        texto.contains('fuera de zona');
  }

  if (bloque == 'rostro') {
    return texto.contains('rostro') ||
        texto.contains('facial') ||
        texto.contains('foto');
  }

  return false;
}

String formatearFechaHoraPanel(DateTime fechaHora) {
  final dia = fechaHora.day.toString().padLeft(2, '0');
  final mes = fechaHora.month.toString().padLeft(2, '0');
  final anio = fechaHora.year.toString();
  final hora = fechaHora.hour.toString().padLeft(2, '0');
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  final segundo = fechaHora.second.toString().padLeft(2, '0');
  return '$dia/$mes/$anio - $hora:$minuto:$segundo';
}

String formatearFechaPanel(DateTime fechaHora) {
  final dia = fechaHora.day.toString().padLeft(2, '0');
  final mes = fechaHora.month.toString().padLeft(2, '0');
  final anio = fechaHora.year.toString();
  return '$dia/$mes/$anio';
}

String formatearHoraPanel(DateTime fechaHora) {
  final hora = fechaHora.hour.toString().padLeft(2, '0');
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  final segundo = fechaHora.second.toString().padLeft(2, '0');
  return '$hora:$minuto:$segundo';
}

String formatearHoraAmPmPanel(DateTime fechaHora) {
  final hora24 = fechaHora.hour;
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  final periodo = hora24 >= 12 ? 'PM' : 'AM';
  final hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12;
  return '${hora12.toString().padLeft(2, '0')}:$minuto $periodo';
}

String formatearDuracionPanel(Duration duracion) {
  final horas = duracion.inHours.toString().padLeft(2, '0');
  final minutos = (duracion.inMinutes % 60).toString().padLeft(2, '0');
  return '$horas:$minutos';
}
