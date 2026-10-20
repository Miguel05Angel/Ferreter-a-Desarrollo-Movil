import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paleta del "taller": grafito, acero, naranja de seguridad y amarillo de
/// señalización. Se usa en splash, bienvenida y visor 3D.
class Paleta {
  Paleta._();

  static const Color grafito = Color(0xFF15181B);
  static const Color acero = Color(0xFF22272C);
  static const Color linea = Color(0xFF3A4148);
  static const Color naranja = Color(0xFFFF6D00);
  static const Color amarillo = Color(0xFFFFC400);
  static const Color hueso = Color(0xFFEDE8DF);
}

/// Cuadricula de plano tecnico con marcas de registro (+) en las esquinas.
/// [progreso] va de 0 a 1 y dibuja las lineas poco a poco.
class PlanoPainter extends CustomPainter {
  final double progreso;

  PlanoPainter({this.progreso = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final fino = Paint()
      ..color = Paleta.linea.withOpacity(0.38)
      ..strokeWidth = 1;
    const paso = 28.0;

    final columnas = (size.width / paso).ceil();
    for (var i = 0; i <= columnas; i++) {
      final x = i * paso;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * progreso), fino);
    }
    final filas = (size.height / paso).ceil();
    for (var j = 0; j <= filas; j++) {
      final y = j * paso;
      canvas.drawLine(Offset(0, y), Offset(size.width * progreso, y), fino);
    }

    final marca = Paint()
      ..color = Paleta.naranja.withOpacity(0.85 * progreso)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void cruz(Offset c) {
      canvas.drawLine(c.translate(-8, 0), c.translate(8, 0), marca);
      canvas.drawLine(c.translate(0, -8), c.translate(0, 8), marca);
    }

    const m = 18.0;
    cruz(const Offset(m, m));
    cruz(Offset(size.width - m, m));
    cruz(Offset(m, size.height - m));
    cruz(Offset(size.width - m, size.height - m));
  }

  @override
  bool shouldRepaint(PlanoPainter oldDelegate) =>
      oldDelegate.progreso != progreso;
}

/// Franja diagonal amarilla y negra de señalizacion de obra.
/// [avance] (0 a 1) la descubre de izquierda a derecha.
class FranjaPeligro extends StatelessWidget {
  final double alto;
  final double avance;

  const FranjaPeligro({super.key, this.alto = 14, this.avance = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      width: double.infinity,
      child: CustomPaint(painter: _FranjaPainter(avance)),
    );
  }
}

class _FranjaPainter extends CustomPainter {
  final double avance;

  _FranjaPainter(this.avance);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * avance, size.height));
    canvas.drawRect(Offset.zero & size, Paint()..color = Paleta.amarillo);

    final negro = Paint()..color = Paleta.grafito;
    final h = size.height;
    final w = h;
    for (double x = -h; x < size.width + h; x += w * 2) {
      final path = Path()
        ..moveTo(x, h)
        ..lineTo(x + w, h)
        ..lineTo(x + w + h, 0)
        ..lineTo(x + h, 0)
        ..close();
      canvas.drawPath(path, negro);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FranjaPainter oldDelegate) =>
      oldDelegate.avance != avance;
}

/// Contorno de engranaje con [dientes] dientes. Hueco central en el centro.
Path trazoEngranaje(Offset centro, double radio, int dientes,
    {double profundidad = 0.16, double hueco = 0.28}) {
  final path = Path();
  final paso = 2 * math.pi / dientes;
  final punta = radio * (1 + profundidad);

  Offset polar(double r, double a) =>
      Offset(centro.dx + r * math.cos(a), centro.dy + r * math.sin(a));

  for (var i = 0; i < dientes; i++) {
    final a = i * paso;
    final p1 = polar(radio, a);
    final p2 = polar(punta, a + paso * 0.14);
    final p3 = polar(punta, a + paso * 0.36);
    final p4 = polar(radio, a + paso * 0.50);
    if (i == 0) {
      path.moveTo(p1.dx, p1.dy);
    } else {
      path.lineTo(p1.dx, p1.dy);
    }
    path
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy);
  }
  path.close();

  // Hueco central
  path.addOval(Rect.fromCircle(center: centro, radius: radio * hueco));
  path.fillType = PathFillType.evenOdd;
  return path;
}

/// Una cara del engranaje. [cara] true = tapa frontal con brillo y detalles;
/// false = lado (capa de grosor) con color plano oscuro.
class EngranajePainter extends CustomPainter {
  final bool cara;
  final Color color;

  EngranajePainter({required this.cara, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width * 0.38;
    final path = trazoEngranaje(centro, radio, 12);

    if (!cara) {
      canvas.drawPath(path, Paint()..color = color);
      return;
    }

    final rect = Rect.fromCircle(center: centro, radius: radio * 1.2);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Orificios de aligeramiento
    final hueco = Paint()..color = Paleta.grafito.withOpacity(0.85);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + math.pi / 6;
      final c = Offset(
        centro.dx + radio * 0.62 * math.cos(a),
        centro.dy + radio * 0.62 * math.sin(a),
      );
      canvas.drawCircle(c, radio * 0.12, hueco);
    }

    // Aro interior
    canvas.drawCircle(
      centro,
      radio * 0.42,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(EngranajePainter oldDelegate) =>
      oldDelegate.cara != cara || oldDelegate.color != color;
}

/// Engranaje con grosor real: varias capas apiladas en el eje Z de una
/// perspectiva 3D. [angulo] es el giro sobre su propio eje; [inclX] e
/// [inclY] inclinan el conjunto hacia la camara.
class Engranaje3D extends StatelessWidget {
  final double size;
  final double angulo;
  final double inclX;
  final double inclY;
  final Color color;

  const Engranaje3D({
    super.key,
    required this.size,
    required this.angulo,
    required this.inclX,
    required this.inclY,
    this.color = Paleta.naranja,
  });

  static const int _capas = 9;

  @override
  Widget build(BuildContext context) {
    final lado = Color.lerp(color, Colors.black, 0.55)!;
    final paso = size * 0.012;

    final capas = <Widget>[];
    for (var i = 0; i < _capas; i++) {
      // i = 0 es la capa trasera (z positivo = lejos de la camara)
      final z = ((_capas - 1) / 2 - i) * paso;
      final frontal = i == _capas - 1;
      capas.add(
        Transform(
          transform: Matrix4.translationValues(0, 0, z),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.square(size),
              painter: EngranajePainter(
                cara: frontal,
                color: frontal ? color : lado,
              ),
            ),
          ),
        ),
      );
    }

    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0014)
      ..rotateX(inclX)
      ..rotateY(inclY)
      ..rotateZ(angulo);

    return Transform(
      alignment: Alignment.center,
      transform: m,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(children: capas),
      ),
    );
  }
}
