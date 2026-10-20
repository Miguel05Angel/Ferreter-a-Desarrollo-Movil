import 'package:flutter/material.dart';

/// Da profundidad real a su contenido: al tocar o arrastrar sobre el, la
/// pieza se hunde en el punto tocado (perspectiva 3D) y vuelve a su sitio
/// con un rebote. Usa [Listener], asi que NO compite con el scroll de una
/// lista ni con los toques (InkWell, botones) del contenido.
///
/// El [builder] recibe la inclinacion normalizada (-1 a 1 en cada eje) para
/// que las capas internas puedan desplazarse y crear paralaje.
class Tilt3D extends StatefulWidget {
  final Widget Function(BuildContext context, Offset inclinacion) builder;

  /// Angulo maximo en radianes.
  final double anguloMax;

  /// Radio de las esquinas del brillo, para que no se salga de la tarjeta.
  final double radioBorde;

  /// Muestra un reflejo de luz que sigue al dedo.
  final bool reflejo;

  const Tilt3D({
    super.key,
    required this.builder,
    this.anguloMax = 0.12,
    this.radioBorde = 16,
    this.reflejo = true,
  });

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with SingleTickerProviderStateMixin {
  late final AnimationController _retorno;
  Offset _inclinacion = Offset.zero;
  Offset _desde = Offset.zero;

  @override
  void initState() {
    super.initState();
    _retorno = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        final v = Curves.elasticOut.transform(_retorno.value);
        setState(() => _inclinacion = Offset.lerp(_desde, Offset.zero, v)!);
      });
  }

  @override
  void dispose() {
    _retorno.dispose();
    super.dispose();
  }

  void _actualizar(Offset local) {
    final caja = context.size;
    if (caja == null || caja.width == 0 || caja.height == 0) return;
    final nx = ((local.dx / caja.width) * 2 - 1).clamp(-1.0, 1.0).toDouble();
    final ny = ((local.dy / caja.height) * 2 - 1).clamp(-1.0, 1.0).toDouble();
    _retorno.stop();
    setState(() => _inclinacion = Offset(nx, ny));
  }

  void _soltar() {
    _desde = _inclinacion;
    _retorno.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateX(_inclinacion.dy * widget.anguloMax)
      ..rotateY(-_inclinacion.dx * widget.anguloMax);

    final intensidad = _inclinacion.distance.clamp(0.0, 1.0).toDouble();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _actualizar(e.localPosition),
      onPointerMove: (e) => _actualizar(e.localPosition),
      onPointerUp: (_) => _soltar(),
      onPointerCancel: (_) => _soltar(),
      child: Transform(
        alignment: Alignment.center,
        transform: m,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.builder(context, _inclinacion),
            if (widget.reflejo)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.radioBorde),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(_inclinacion.dx, _inclinacion.dy),
                          radius: 0.9,
                          colors: [
                            Colors.white.withOpacity(0.18 * intensidad),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Entrada en 3D para elementos de una lista: la tarjeta se levanta desde
/// el fondo, girando sobre su borde inferior hasta quedar de frente.
/// Como las listas construyen sus elementos al hacer scroll, cada tarjeta
/// se anima justo cuando aparece en pantalla.
class Entrada3D extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duracion;

  const Entrada3D({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duracion = const Duration(milliseconds: 700),
  });

  @override
  State<Entrada3D> createState() => _Entrada3DState();
}

class _Entrada3DState extends State<Entrada3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curva;
  late final Animation<double> _opacidad;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duracion);
    _curva = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _opacidad = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
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
        final v = _curva.value;
        final resto = 1 - v;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..multiply(Matrix4.translationValues(0, resto * 46, resto * 140))
          ..rotateX(-resto * 0.85);
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
