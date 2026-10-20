import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'decor_industrial.dart';
import 'producto_illustration.dart';

/// Plato giratorio 3D para un producto.
///
/// La ilustracion se apila en varias capas a distintas profundidades (Z)
/// dentro de una perspectiva real, de modo que al girar se ve el grosor de
/// la pieza. Gira sola con suavidad; al arrastrar con el dedo toma el
/// control y, al soltar, conserva la inercia y vuelve poco a poco al giro
/// automatico.
class Visor3D extends StatefulWidget {
  final String tipo;
  final int colorHex;
  final double size;
  final Color acento;

  const Visor3D({
    super.key,
    required this.tipo,
    required this.colorHex,
    this.size = 190,
    this.acento = Paleta.naranja,
  });

  @override
  State<Visor3D> createState() => _Visor3DState();
}

class _Visor3DState extends State<Visor3D> with SingleTickerProviderStateMixin {
  static const int _numCapas = 9;
  static const double _velReposo = 0.55; // rad/s

  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  List<Widget> _capas = const [];
  String _claveCapas = '';

  double _angulo = 0.6;
  double _vel = 0;
  bool _arrastrando = false;
  Duration _ultimo = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _tick(Duration t) {
    final dt = ((t - _ultimo).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _ultimo = t;
    if (!_arrastrando) {
      // La velocidad se acerca de forma exponencial al giro de reposo
      _vel += (_velReposo - _vel) * (1 - math.exp(-1.4 * dt));
      _angulo += _vel * dt;
    }
    _frame.value++;
  }

  void _construirCapas() {
    final clave = '${widget.tipo}-${widget.colorHex}-${widget.size}';
    if (clave == _claveCapas) return;
    _claveCapas = clave;

    final s = widget.size;
    final paso = s * 0.0085;
    final capas = <Widget>[];
    for (var i = 0; i < _numCapas; i++) {
      // i = 0 es la cara trasera (z positivo = lejos de la camara)
      final z = ((_numCapas - 1) / 2 - i) * paso;
      final frontal = i == _numCapas - 1;
      Widget ilustracion = ProductoEstatico(
        tipo: widget.tipo,
        colorHex: widget.colorHex,
        size: s,
      );
      if (!frontal) {
        ilustracion = ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(i == 0 ? 0.40 : 0.55),
            BlendMode.srcATop,
          ),
          child: ilustracion,
        );
      }
      capas.add(
        Transform(
          transform: Matrix4.translationValues(0, 0, z),
          child: RepaintBoundary(child: ilustracion),
        ),
      );
    }
    _capas = capas;
  }

  @override
  Widget build(BuildContext context) {
    _construirCapas();
    final s = widget.size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _arrastrando = true,
      onHorizontalDragUpdate: (d) {
        _angulo += d.delta.dx * 0.013;
      },
      onHorizontalDragEnd: (d) {
        _arrastrando = false;
        _vel = ((d.primaryVelocity ?? 0) * 0.013).clamp(-9.0, 9.0).toDouble();
      },
      onHorizontalDragCancel: () => _arrastrando = false,
      child: SizedBox(
        width: s * 1.5,
        height: s * 1.4,
        child: ValueListenableBuilder<int>(
          valueListenable: _frame,
          builder: (context, _, __) {
            final desdeAtras = math.cos(_angulo) < 0;
            final orden = desdeAtras ? _capas.reversed.toList() : _capas;

            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX(-0.2)
              ..rotateY(_angulo);

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: s * 0.42,
                  child: CustomPaint(
                    painter: _PlatoPainter(
                      angulo: _angulo,
                      acento: widget.acento,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.28),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: SizedBox(
                      width: s,
                      height: s,
                      child: Stack(children: orden),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Plato del visor: sombra de contacto y aro graduado que gira junto con
/// la pieza, para que se note el movimiento.
class _PlatoPainter extends CustomPainter {
  final double angulo;
  final Color acento;

  _PlatoPainter({required this.angulo, required this.acento});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height * 0.46);
    final rx = size.width * 0.40;
    final ry = rx * 0.20;
    final elipse = Rect.fromCenter(
        center: centro, width: rx * 2, height: ry * 2);

    // Sombra de contacto
    canvas.drawOval(
      Rect.fromCenter(center: centro, width: rx * 1.5, height: ry * 1.4),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.black.withOpacity(0.55), Colors.transparent],
        ).createShader(
          Rect.fromCenter(center: centro, width: rx * 1.5, height: ry * 1.4),
        ),
    );

    // Aro exterior
    canvas.drawOval(
      elipse,
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Graduacion que gira con la pieza
    const marcas = 60;
    final tick = Paint()..strokeWidth = 1.6;
    for (var j = 0; j < marcas; j++) {
      final a = angulo + j * 2 * math.pi / marcas;
      final delante = math.sin(a); // >0 = lado cercano a la camara
      final largo = j % 5 == 0 ? 0.12 : 0.06;
      final p1 = Offset(centro.dx + math.cos(a) * rx,
          centro.dy + math.sin(a) * ry);
      final p2 = Offset(centro.dx + math.cos(a) * rx * (1 - largo),
          centro.dy + math.sin(a) * ry * (1 - largo));
      tick.color = (j % 5 == 0 ? acento : Colors.white)
          .withOpacity(0.15 + 0.55 * ((delante + 1) / 2));
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(_PlatoPainter oldDelegate) =>
      oldDelegate.angulo != angulo || oldDelegate.acento != acento;
}
