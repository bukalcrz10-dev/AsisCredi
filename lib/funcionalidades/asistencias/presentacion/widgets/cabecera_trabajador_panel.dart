import 'package:flutter/material.dart';
import '../../../../app/diseno_sistema.dart';

class CabeceraTrabajadorPanel extends StatelessWidget {
  const CabeceraTrabajadorPanel({
    super.key,
    required this.nombre,
    required this.sede,
    required this.fecha,
    required this.hora,
  });

  final String nombre;
  final String sede;
  final String fecha;
  final String hora;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioTarjeta),
        border: Border.all(color: ColoresSistema.bordeIntermedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              color: ColoresSistema.rojoInstitucional,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(MedidasSistema.radioTarjeta),
                topRight: Radius.circular(MedidasSistema.radioTarjeta),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'UNACHU',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: ColoresSistema.verdeExito,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'En linea',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ColoresSistema.textoSuave,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  nombre,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        color: ColoresSistema.textoTitulo,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: ColoresSistema.rojoInstitucional,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sede,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: ColoresSistema.textoFuerte,
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipCabecera(
                      icono: Icons.calendar_today_outlined,
                      texto: fecha,
                      fondo: ColoresSistema.fondoChip,
                      colorTexto: ColoresSistema.iconoSuave,
                    ),
                    _ChipCabecera(
                      icono: Icons.schedule,
                      texto: hora,
                      fondo: ColoresSistema.fondoChip,
                      colorTexto: ColoresSistema.iconoSuave,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipCabecera extends StatelessWidget {
  const _ChipCabecera({
    required this.icono,
    required this.texto,
    this.fondo = const Color(0x22FFFFFF),
    this.colorTexto = Colors.white,
  });

  final IconData icono;
  final String texto;
  final Color fondo;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: colorTexto),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: colorTexto,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
