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
    final mediaQuery = MediaQuery.of(context);
    final compacto = mediaQuery.orientation == Orientation.landscape;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(12, compacto ? 6 : 10, 12, 0),
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
            padding: EdgeInsets.symmetric(
              horizontal: compacto ? 14 : 18,
              vertical: compacto ? 2 : 3,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColoresPanel.verde,
                  ColoresPanel.turquesa,
                  ColoresPanel.azul,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(MedidasSistema.radioTarjeta),
                topRight: Radius.circular(MedidasSistema.radioTarjeta),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'CREDIASCIENDE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: compacto ? 1.0 : 1.2,
                    fontWeight: FontWeight.w800,
                    fontSize: compacto ? 12 : null,
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
                        fontSize: compacto ? 16 : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compacto ? 14 : 18,
              compacto ? 12 : 18,
              compacto ? 14 : 18,
              compacto ? 12 : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compacto) ...[
                  Text(
                    'Bienvenido',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColoresSistema.textoSuave,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  nombre,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: compacto ? 20 : 24,
                    color: ColoresSistema.textoTitulo,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: compacto ? 5 : 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: ColoresPanel.turquesa,
                      size: compacto ? 20 : 22,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        sede,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: ColoresSistema.textoFuerte,
                              fontSize: compacto ? 16 : 17,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: colorTexto),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: colorTexto,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
