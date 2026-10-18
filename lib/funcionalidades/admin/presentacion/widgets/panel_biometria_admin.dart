import 'package:flutter/material.dart';

class EstadoBiometriaAdmin extends StatelessWidget {
  const EstadoBiometriaAdmin({
    super.key,
    required this.estado,
    required this.registroHabilitado,
    this.solicitudPendiente = false,
    this.accion,
  });
  final String estado;
  final bool registroHabilitado, solicitudPendiente;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final activo = estado == 'activo';
    final pendiente = !activo && solicitudPendiente;
    final abierto = !activo && !pendiente && registroHabilitado;
    final color = activo
        ? const Color(0xFF078854)
        : pendiente
        ? const Color(0xFFA46518)
        : const Color(0xFF008394);
    return _TarjetaAcceso(
      titulo: 'Rostro',
      descripcion: 'Registro facial para validar la identidad.',
      icono: Icons.face_outlined,
      color: const Color(0xFF078854),
      distintivo: _DistintivoAcceso(
        texto: activo
            ? 'Aprobado'
            : pendiente
            ? 'Por aprobar'
            : abierto
            ? 'Esperando solicitud'
            : 'Sin registrar',
        color: color,
        aprobado: activo,
      ),
      datos: pendiente || abierto || accion != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendiente)
                  const Text(
                    'Verifica su identidad y el código antes de aprobar.',
                  ),
                if (abierto)
                  const Text('En la app: Perfil → Rostro y celular.'),
                ?accion,
              ],
            )
          : null,
    );
  }
}

class SeccionesBiometriaAdmin extends StatelessWidget {
  const SeccionesBiometriaAdmin({
    super.key,
    required this.registro,
    required this.dispositivos,
    required this.registroActivo,
  });
  final Widget registro;
  final List<Widget> dispositivos;
  final bool registroActivo;

  @override
  Widget build(BuildContext context) {
    final celular = dispositivos.isEmpty
        ? _TarjetaAcceso(
            titulo: 'Celular',
            descripcion: 'Dispositivo vinculado a este trabajador.',
            icono: Icons.smartphone_outlined,
            color: const Color(0xFF00899A),
            distintivo: _DistintivoAcceso(
              texto: registroActivo
                  ? 'Datos no disponibles'
                  : 'Sin celular vinculado',
              color: const Color(0xFF607581),
            ),
          )
        : dispositivos.length == 1
        ? dispositivos.single
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < dispositivos.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                dispositivos[i],
              ],
            ],
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final escala = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth >= 850 * escala) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 240 * escala),
                  child: registro,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 240 * escala),
                  child: celular,
                ),
              ),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [registro, const SizedBox(height: 16), celular],
        );
      },
    );
  }
}

class TarjetaDispositivoBiometriaAdmin extends StatelessWidget {
  const TarjetaDispositivoBiometriaAdmin({
    super.key,
    required this.modelo,
    required this.codigo,
    required this.estado,
    this.aprobacion,
  });
  final String modelo, codigo, estado;
  final Widget? aprobacion;

  @override
  Widget build(BuildContext context) {
    final color = estado == 'aprobado'
        ? const Color(0xFF078854)
        : estado == 'pendiente'
        ? const Color(0xFFA46518)
        : const Color(0xFF607581);
    final etiqueta = switch (estado) {
      'aprobado' => 'Aprobado',
      'pendiente' => 'Pendiente',
      'revocado' => 'Retirado',
      _ => estado,
    };
    Widget dato(String titulo, String valor) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(titulo, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: SelectableText(
              valor,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return _TarjetaAcceso(
      titulo: 'Celular',
      descripcion: 'Dispositivo vinculado a este trabajador.',
      icono: Icons.smartphone_outlined,
      color: const Color(0xFF00899A),
      distintivo: _DistintivoAcceso(
        texto: etiqueta,
        color: color,
        aprobado: estado == 'aprobado',
      ),
      datos: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 4),
          dato('Modelo', modelo),
          dato('Código', codigo),
          if (aprobacion != null) ...[const Divider(height: 24), aprobacion!],
        ],
      ),
    );
  }
}

class _DistintivoAcceso extends StatelessWidget {
  const _DistintivoAcceso({
    required this.texto,
    required this.color,
    this.aprobado = false,
  });
  final String texto;
  final Color color;
  final bool aprobado;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (aprobado) ...[
          Icon(Icons.check_circle, color: color, size: 17),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TarjetaAcceso extends StatelessWidget {
  const _TarjetaAcceso({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.distintivo,
    this.datos,
  });
  final String titulo, descripcion;
  final IconData icono;
  final Color color;
  final Widget distintivo;
  final Widget? datos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ilustracion =
          constraints.maxWidth >= 400 &&
          MediaQuery.textScalerOf(context).scale(14) <= 17;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0EBEE)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF154A5A).withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _FondoTarjetaAcceso(
                        color: color,
                        celular: titulo == 'Celular',
                        ilustracion: ilustracion,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  ilustracion ? 118 : 20,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.075),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icono, color: color, size: 29),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                descripcion,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF617887)),
                              ),
                              const SizedBox(height: 12),
                              distintivo,
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (datos != null) ...[const SizedBox(height: 14), datos!],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FondoTarjetaAcceso extends CustomPainter {
  const _FondoTarjetaAcceso({
    required this.color,
    required this.celular,
    required this.ilustracion,
  });
  final Color color;
  final bool celular, ilustracion;
  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()..color = color.withValues(alpha: 0.035);
    canvas.drawCircle(Offset(size.width + 28, size.height * .24), 112, fondo);
    canvas.drawCircle(Offset(size.width - 12, size.height + 30), 145, fondo);
    if (!ilustracion) return;
    final centro = Offset(size.width - 60, size.height * .49);
    final trazo = Paint()
      ..color = color.withValues(alpha: celular ? .42 : .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (celular) {
      final telefono = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centro, width: 60, height: 108),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        telefono,
        Paint()..color = color.withValues(alpha: .045),
      );
      canvas.drawRRect(telefono, trazo);
      canvas.drawLine(
        centro + const Offset(-10, -48),
        centro + const Offset(10, -48),
        trazo,
      );
      final ola = Path()
        ..moveTo(centro.dx - 26, centro.dy + 15)
        ..cubicTo(
          centro.dx - 5,
          centro.dy - 6,
          centro.dx + 4,
          centro.dy + 35,
          centro.dx + 26,
          centro.dy + 2,
        )
        ..lineTo(centro.dx + 26, centro.dy + 48)
        ..lineTo(centro.dx - 26, centro.dy + 48)
        ..close();
      canvas.drawPath(ola, Paint()..color = color.withValues(alpha: .07));
    } else {
      final rostro = Path()
        ..moveTo(centro.dx - 23, centro.dy - 16)
        ..cubicTo(
          centro.dx - 25,
          centro.dy - 46,
          centro.dx + 25,
          centro.dy - 46,
          centro.dx + 23,
          centro.dy - 16,
        )
        ..lineTo(centro.dx + 23, centro.dy + 8)
        ..cubicTo(
          centro.dx + 20,
          centro.dy + 43,
          centro.dx - 20,
          centro.dy + 43,
          centro.dx - 23,
          centro.dy + 8,
        )
        ..close();
      canvas.drawPath(rostro, Paint()..color = color.withValues(alpha: .055));
      canvas.drawPath(rostro, trazo);
      for (final posicion in [
        const Offset(-43, -48),
        const Offset(43, -48),
        const Offset(-43, 48),
        const Offset(43, 48),
      ]) {
        final x = posicion.dx < 0 ? 1.0 : -1.0;
        final y = posicion.dy < 0 ? 1.0 : -1.0;
        final esquina = centro + posicion;
        canvas.drawPath(
          Path()
            ..moveTo(esquina.dx, esquina.dy + 15 * y)
            ..lineTo(esquina.dx, esquina.dy)
            ..lineTo(esquina.dx + 15 * x, esquina.dy),
          trazo,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FondoTarjetaAcceso oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.celular != celular ||
      oldDelegate.ilustracion != ilustracion;
}
