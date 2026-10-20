import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/fade_slide.dart';
import '../buttons/animated_button.dart';

/// Estado vacio animado con ilustracion por icono y accion opcional.
class EmptyState extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? onAccion;

  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoBoton,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Center(
      child: FadeSlide(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnilloIcono(icono: icono, color: colorPrimario),
              const SizedBox(height: 20),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              if (textoBoton != null && onAccion != null) ...[
                const SizedBox(height: 24),
                AnimatedButton(
                  texto: textoBoton!,
                  icono: Icons.add,
                  onPressed: onAccion,
                  ancho: 220,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


/// Icono dentro de un anillo punteado que gira lentamente.
class _AnilloIcono extends StatefulWidget {
  final IconData icono;
  final Color color;

  const _AnilloIcono({required this.icono, required this.color});

  @override
  State<_AnilloIcono> createState() => _AnilloIconoState();
}

class _AnilloIconoState extends State<_AnilloIcono>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, v, child) =>
          Transform.scale(scale: v, child: child),
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                size: const Size.square(150),
                painter: _AnilloPainter(_c.value * 2 * math.pi, widget.color),
              ),
            ),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(widget.icono, size: 48, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  final double giro;
  final Color color;

  _AnilloPainter(this.giro, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - 4);
    const tramos = 14;
    const paso = 2 * math.pi / tramos;
    for (var i = 0; i < tramos; i++) {
      canvas.drawArc(rect, giro + i * paso, paso * 0.55, false, p);
    }
  }

  @override
  bool shouldRepaint(_AnilloPainter old) => old.giro != giro;
}
