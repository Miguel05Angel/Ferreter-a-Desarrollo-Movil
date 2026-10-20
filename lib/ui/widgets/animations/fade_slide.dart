import 'package:flutter/material.dart';

/// Entrada de cualquier bloque con perspectiva 3D: el elemento se levanta
/// desde el fondo girando sobre su borde inferior hasta quedar de frente.
/// Admite retardos para crear entradas escalonadas en listas.
///
/// Mantiene la misma API que la version anterior (desvanecido +
/// deslizamiento), asi que todas las pantallas que ya lo usan reciben la
/// nueva animacion automaticamente.
class FadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duracion;
  final Offset inicio;

  const FadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duracion = const Duration(milliseconds: 650),
    this.inicio = const Offset(0, 0.15),
  });

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curva;
  late final Animation<double> _opacidad;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duracion);
    _curva = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacidad = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final resto = 1 - _curva.value;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..multiply(Matrix4.translationValues(
              widget.inicio.dx * 220 * resto,
              widget.inicio.dy * 260 * resto,
              resto * 90))
          ..rotateX(-resto * 0.45);
        return Opacity(
          opacity: _opacidad.value.clamp(0.0, 1.0).toDouble(),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: m,
            child: child,
          ),
        );
      },
    );
  }
}
