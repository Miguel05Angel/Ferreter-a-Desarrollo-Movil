import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ilustracion 3D de un producto dibujada con degradados, sombras y
/// brillos para simular profundidad. El tipo define que se dibuja y el
/// color se puede cambiar en tiempo real (ej: el balde de pintura).
class ProductoIlustracion extends StatefulWidget {
  final String tipo;
  final int colorHex;
  final double size;

  /// Si es true, la ilustracion flota suavemente (animacion continua).
  final bool flotante;

  const ProductoIlustracion({
    super.key,
    required this.tipo,
    required this.colorHex,
    this.size = 64,
    this.flotante = false,
  });

  @override
  State<ProductoIlustracion> createState() => _ProductoIlustracionState();
}

class _ProductoIlustracionState extends State<ProductoIlustracion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.flotante) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final escala = 0.85 + (0.15 * curved.value);
        final trasladoY = widget.flotante ? (1 - curved.value) * -6.0 : 0.0;
        return Transform.translate(
          offset: Offset(0, trasladoY),
          child: Transform.scale(
            scale: escala,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _ProductoPainter(
                tipo: widget.tipo,
                color: Color(widget.colorHex),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductoPainter extends CustomPainter {
  final String tipo;
  final Color color;
  final bool sombra;

  _ProductoPainter(
      {required this.tipo, required this.color, this.sombra = true});

  Paint _paint(Color c, {bool stroke = false, double width = 2}) {
    return Paint()
      ..color = c
      ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = width
      ..isAntiAlias = true;
  }

  Paint _degradado(Rect rect, Color base,
      {Color? oscuro, Color? claro, Alignment begin = Alignment.topLeft}) {
    final shader = LinearGradient(
      begin: begin,
      end: Alignment.bottomRight,
      colors: [
        claro ?? HSLColor.fromColor(base).withLightness(0.72).toColor(),
        base,
        oscuro ?? HSLColor.fromColor(base).withLightness(0.45).toColor(),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);
    return Paint()..shader = shader..isAntiAlias = true;
  }

  void _sombra(Canvas canvas, Rect rect) {
    final sombraRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom - 4),
      width: rect.width * 0.7,
      height: rect.height * 0.12,
    );
    canvas.drawOval(
      sombraRect,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _brillo(Canvas canvas, Rect rect) {
    final brillo = Rect.fromLTWH(
      rect.left + rect.width * 0.16,
      rect.top + rect.height * 0.08,
      rect.width * 0.16,
      rect.height * 0.5,
    );
    final rrect = RRect.fromRectAndRadius(brillo, const Radius.circular(12));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (sombra) _sombra(canvas, rect);
    switch (tipo) {
      case 'pintura':
        _dibujarPintura(canvas, rect);
        break;
      case 'taladro':
        _dibujarTaladro(canvas, rect);
        break;
      case 'llaves':
        _dibujarLlaves(canvas, rect);
        break;
      case 'martillo':
        _dibujarMartillo(canvas, rect);
        break;
      case 'pistola':
        _dibujarPistola(canvas, rect);
        break;
      case 'cinta':
        _dibujarCinta(canvas, rect);
        break;
      case 'rodillo':
        _dibujarRodillo(canvas, rect);
        break;
      case 'brocha':
        _dibujarBrocha(canvas, rect);
        break;
      case 'tubo':
        _dibujarTubo(canvas, rect);
        break;
      case 'codo':
        _dibujarCodo(canvas, rect);
        break;
      case 'pega':
        _dibujarPega(canvas, rect);
        break;
      case 'manguera':
        _dibujarManguera(canvas, rect);
        break;
      case 'cable':
        _dibujarCable(canvas, rect);
        break;
      case 'interruptor':
        _dibujarInterruptor(canvas, rect);
        break;
      case 'foco':
        _dibujarFoco(canvas, rect);
        break;
      case 'cemento':
        _dibujarCemento(canvas, rect);
        break;
      case 'fierro':
        _dibujarFierro(canvas, rect);
        break;
      case 'clavos':
        _dibujarClavos(canvas, rect);
        break;
      case 'tornillos':
        _dibujarTornillos(canvas, rect);
        break;
      default:
        _dibujarGenerico(canvas, rect);
    }
  }

  void _dibujarPintura(Canvas canvas, Rect rect) {
    final balde = Rect.fromLTWH(
        rect.left + rect.width * 0.16, rect.top + rect.height * 0.24,
        rect.width * 0.68, rect.height * 0.62);
    // Asa metalica
    final asa = Rect.fromLTWH(
        balde.left + balde.width * 0.05, balde.top - rect.height * 0.10,
        balde.width * 0.9, balde.height * 0.42);
    canvas.drawArc(asa, math.pi, math.pi, false,
        _paint(Colors.blueGrey.shade300, stroke: true, width: 3.5));
    // Cuerpo del balde
    canvas.drawRRect(
      RRect.fromRectAndRadius(balde, const Radius.circular(10)),
      _degradado(balde, Colors.blueGrey.shade500,
          claro: Colors.blueGrey.shade300,
          oscuro: Colors.blueGrey.shade800),
    );
    _brillo(canvas, balde);
    // Pintura derramada arriba (cambia de color)
    final pinturaRect = Rect.fromLTWH(
        balde.left + 3, balde.top + 3, balde.width - 6, balde.height * 0.3);
    final pinturaPath = Path()
      ..moveTo(pinturaRect.left, pinturaRect.top + 10)
      ..quadraticBezierTo(pinturaRect.left + pinturaRect.width * 0.3,
          pinturaRect.top - 8, pinturaRect.left + pinturaRect.width * 0.5,
          pinturaRect.top + 8)
      ..quadraticBezierTo(pinturaRect.left + pinturaRect.width * 0.75,
          pinturaRect.top + 20, pinturaRect.right, pinturaRect.top + 6)
      ..lineTo(pinturaRect.right, pinturaRect.bottom)
      ..quadraticBezierTo(pinturaRect.center.dx, pinturaRect.bottom + 14,
          pinturaRect.left, pinturaRect.bottom)
      ..close();
    canvas.drawPath(pinturaPath, _degradado(pinturaRect, color,
        claro: HSLColor.fromColor(color).withLightness(0.85).toColor()));
    // Gota cayendo
    final gota = Rect.fromLTWH(
        balde.right - 10, balde.bottom - 4, 8, 14);
    canvas.drawOval(gota, _paint(color));
    // Etiqueta
    final etiqueta = Rect.fromLTWH(
        balde.left + balde.width * 0.16, balde.top + balde.height * 0.42,
        balde.width * 0.68, balde.height * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(etiqueta, const Radius.circular(6)),
      _paint(Colors.white.withOpacity(0.92)),
    );
    canvas.drawRect(
      Rect.fromLTWH(etiqueta.left + 6, etiqueta.top + etiqueta.height * 0.3,
          etiqueta.width - 12, 4),
      _paint(color),
    );
    canvas.drawRect(
      Rect.fromLTWH(etiqueta.left + 6, etiqueta.top + etiqueta.height * 0.55,
          (etiqueta.width - 12) * 0.6, 3.5),
      _paint(Colors.grey.shade400),
    );
  }

  void _dibujarTaladro(Canvas canvas, Rect rect) {
    final cuerpo = Rect.fromLTWH(
        rect.left + rect.width * 0.12, rect.top + rect.height * 0.26,
        rect.width * 0.56, rect.height * 0.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cuerpo, const Radius.circular(14)),
      _degradado(cuerpo, color),
    );
    _brillo(canvas, cuerpo);
    // Mango
    final mango = Rect.fromLTWH(
        cuerpo.left + cuerpo.width * 0.18, cuerpo.bottom - 6,
        cuerpo.width * 0.34, rect.height * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mango, const Radius.circular(10)),
      _degradado(mango, HSLColor.fromColor(color).withLightness(0.35).toColor()),
    );
    // Gatillo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(mango.right + 4, cuerpo.bottom + 4, 12, 16),
          const Radius.circular(6)),
      _paint(Colors.grey.shade800),
    );
    // Broca
    final brocaPath = Path()
      ..moveTo(cuerpo.right - 2, cuerpo.center.dy - 6)
      ..lineTo(rect.right - 8, cuerpo.center.dy - 1.5)
      ..lineTo(rect.right - 8, cuerpo.center.dy + 1.5)
      ..lineTo(cuerpo.right - 2, cuerpo.center.dy + 6)
      ..close();
    canvas.drawPath(brocaPath, _paint(Colors.blueGrey.shade300));
    canvas.drawRect(
      Rect.fromLTWH(cuerpo.right - 10, cuerpo.center.dy - 8, 12, 16),
      _paint(Colors.grey.shade700),
    );
  }

  void _dibujarLlaves(Canvas canvas, Rect rect) {
    for (var i = 0; i < 2; i++) {
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(-0.5 + i * 0.55);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      final p = Rect.fromLTWH(
          rect.left + rect.width * 0.2, rect.top + rect.height * 0.14,
          rect.width * 0.16, rect.height * 0.72);
      canvas.drawRRect(
        RRect.fromRectAndRadius(p, const Radius.circular(8)),
        _degradado(p, color),
      );
      // Boca
      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(p.center.dx, rect.top + rect.height * 0.16),
            radius: rect.width * 0.14),
        math.pi * 0.15, math.pi * 1.4, false,
        _paint(HSLColor.fromColor(color).withLightness(0.3).toColor(),
            stroke: true, width: 6),
      );
      // Anillo
      canvas.drawCircle(
        Offset(p.center.dx, rect.bottom - rect.height * 0.12),
        rect.width * 0.11,
        _paint(HSLColor.fromColor(color).withLightness(0.35).toColor()),
      );
      canvas.restore();
    }
  }

  void _dibujarMartillo(Canvas canvas, Rect rect) {
    // Mango
    final mango = Rect.fromLTWH(
        rect.left + rect.width * 0.42, rect.top + rect.height * 0.3,
        rect.width * 0.16, rect.height * 0.56);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.6);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mango, const Radius.circular(8)),
      _degradado(mango, color),
    );
    // Cabeza
    final cabeza = Rect.fromLTWH(
        mango.left - rect.width * 0.2, rect.top + rect.height * 0.1,
        rect.width * 0.56, rect.height * 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabeza, const Radius.circular(8)),
      _degradado(cabeza, Colors.blueGrey.shade600,
          claro: Colors.blueGrey.shade300),
    );
    _brillo(canvas, cabeza);
    canvas.restore();
  }

  void _dibujarPistola(Canvas canvas, Rect rect) {
    final cuerpo = Rect.fromLTWH(
        rect.left + rect.width * 0.14, rect.top + rect.height * 0.22,
        rect.width * 0.6, rect.height * 0.26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cuerpo, const Radius.circular(12)),
      _degradado(cuerpo, color),
    );
    // Boquilla
    canvas.drawRect(
      Rect.fromLTWH(cuerpo.right - 4, cuerpo.top + 6, rect.width * 0.22, 10),
      _paint(Colors.grey.shade700),
    );
    // Mango
    final mango = Rect.fromLTWH(
        cuerpo.left + cuerpo.width * 0.22, cuerpo.bottom - 4,
        cuerpo.width * 0.3, rect.height * 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mango, const Radius.circular(10)),
      _degradado(mango, HSLColor.fromColor(color).withLightness(0.35).toColor()),
    );
    // Aire caliente (ondas)
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromLTWH(cuerpo.right + 2 + i * 7.0, cuerpo.top - 4,
            12 + i * 6.0, cuerpo.height + 8),
        -math.pi / 2.4, math.pi / 1.2, false,
        _paint(Colors.orange.withOpacity(0.6 - i * 0.15),
            stroke: true, width: 2.5),
      );
    }
  }

  void _dibujarCinta(Canvas canvas, Rect rect) {
    final cuerpo = Rect.fromCircle(
        center: rect.center, radius: rect.width * 0.34);
    canvas.drawCircle(
      cuerpo.center,
      cuerpo.width / 2,
      _degradado(cuerpo, color),
    );
    _brillo(canvas, cuerpo);
    canvas.drawCircle(
      cuerpo.center,
      cuerpo.width * 0.32,
      _paint(HSLColor.fromColor(color).withLightness(0.25).toColor()),
    );
    canvas.drawCircle(cuerpo.center, cuerpo.width * 0.14,
        _paint(Colors.white.withOpacity(0.85)));
    // Cinta saliendo
    final cinta = Rect.fromLTWH(
        cuerpo.center.dx, rect.bottom - rect.height * 0.22,
        rect.width * 0.34, 9);
    canvas.drawRect(cinta, _paint(Colors.yellow.shade700));
    canvas.drawRect(
      Rect.fromLTWH(cinta.right - 6, cinta.top - 2, 6, cinta.height + 4),
      _paint(Colors.grey.shade700),
    );
  }

  void _dibujarRodillo(Canvas canvas, Rect rect) {
    // Cilindro
    final rodillo = Rect.fromLTWH(
        rect.left + rect.width * 0.14, rect.top + rect.height * 0.18,
        rect.width * 0.6, rect.height * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rodillo, const Radius.circular(14)),
      _degradado(rodillo, color),
    );
    _brillo(canvas, rodillo);
    // Brazo
    final brazoPath = Path()
      ..moveTo(rodillo.right - 4, rodillo.center.dy)
      ..lineTo(rect.right - rect.width * 0.18, rodillo.center.dy + 4)
      ..lineTo(rect.right - rect.width * 0.18, rect.bottom - rect.height * 0.16);
    canvas.drawPath(
        brazoPath, _paint(Colors.grey.shade600, stroke: true, width: 5));
    // Mango
    final mango = Rect.fromLTWH(
        rect.right - rect.width * 0.28, rect.bottom - rect.height * 0.22,
        rect.width * 0.16, rect.height * 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mango, const Radius.circular(8)),
      _degradado(mango, Colors.brown.shade600),
    );
  }

  void _dibujarBrocha(Canvas canvas, Rect rect) {
    // Mango
    final mango = Rect.fromLTWH(
        rect.center.dx - 5, rect.top + rect.height * 0.12,
        10, rect.height * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mango, const Radius.circular(5)),
      _degradado(mango, Colors.brown.shade600),
    );
    // Union metal
    final union = Rect.fromLTWH(
        rect.center.dx - rect.width * 0.12, mango.bottom - 2,
        rect.width * 0.24, rect.height * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(union, const Radius.circular(4)),
      _degradado(union, Colors.blueGrey.shade500),
    );
    // Cerdas con pintura
    final cerdas = Path()
      ..moveTo(union.left + 2, union.bottom - 2)
      ..lineTo(union.right - 2, union.bottom - 2)
      ..lineTo(union.right + 2, rect.bottom - rect.height * 0.12)
      ..quadraticBezierTo(rect.center.dx, rect.bottom - 2,
          union.left - 2, rect.bottom - rect.height * 0.12)
      ..close();
    canvas.drawPath(cerdas, _degradado(
        Rect.fromLTWH(union.left, union.bottom, union.width,
            rect.height * 0.2),
        color,
        claro: HSLColor.fromColor(color).withLightness(0.8).toColor()));
  }

  void _dibujarTubo(Canvas canvas, Rect rect) {
    final tubo = Rect.fromLTWH(
        rect.left + rect.width * 0.1, rect.top + rect.height * 0.3,
        rect.width * 0.8, rect.height * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tubo, const Radius.circular(10)),
      _degradado(tubo, color, claro: Colors.white,
          oscuro: Colors.blueGrey.shade300),
    );
    _brillo(canvas, tubo);
    // Extremos
    canvas.drawOval(
      Rect.fromLTWH(tubo.left - 6, tubo.top + 2, 14, tubo.height - 4),
      _paint(Colors.grey.shade400),
    );
    canvas.drawOval(
      Rect.fromLTWH(tubo.right - 8, tubo.top + 2, 14, tubo.height - 4),
      _paint(Colors.grey.shade500),
    );
  }

  void _dibujarCodo(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.left + rect.width * 0.18, rect.top + rect.height * 0.2)
      ..lineTo(rect.left + rect.width * 0.48, rect.top + rect.height * 0.2)
      ..quadraticBezierTo(rect.left + rect.width * 0.62,
          rect.top + rect.height * 0.2, rect.left + rect.width * 0.62,
          rect.top + rect.height * 0.4)
      ..lineTo(rect.left + rect.width * 0.62, rect.bottom - rect.height * 0.16)
      ..quadraticBezierTo(rect.left + rect.width * 0.62, rect.bottom - 8,
          rect.left + rect.width * 0.42, rect.bottom - 8)
      ..lineTo(rect.left + rect.width * 0.3, rect.bottom - 8)
      ..quadraticBezierTo(rect.left + rect.width * 0.18, rect.bottom - 8,
          rect.left + rect.width * 0.18, rect.bottom - rect.height * 0.24)
      ..lineTo(rect.left + rect.width * 0.18, rect.top + rect.height * 0.34)
      ..quadraticBezierTo(rect.left + rect.width * 0.18,
          rect.top + rect.height * 0.2, rect.left + rect.width * 0.3,
          rect.top + rect.height * 0.2)
      ..close();
    final bounds = path.getBounds();
    canvas.drawPath(path, _degradado(bounds, color,
        claro: Colors.white, oscuro: Colors.blueGrey.shade300));
    canvas.drawPath(
        path, _paint(Colors.blueGrey.shade400, stroke: true, width: 2));
  }

  void _dibujarPega(Canvas canvas, Rect rect) {
    final lata = Rect.fromLTWH(
        rect.left + rect.width * 0.24, rect.top + rect.height * 0.26,
        rect.width * 0.52, rect.height * 0.56);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lata, const Radius.circular(10)),
      _degradado(lata, color),
    );
    _brillo(canvas, lata);
    canvas.drawRect(
      Rect.fromLTWH(lata.left - 4, lata.top - 8, lata.width + 8, 12),
      _degradado(Rect.fromLTWH(lata.left, lata.top - 8, lata.width, 12),
          HSLColor.fromColor(color).withLightness(0.4).toColor()),
    );
    // Brocha aplicadora
    canvas.drawRect(
      Rect.fromLTWH(lata.center.dx - 4, lata.top - 22, 8, 20),
      _paint(Colors.brown.shade500),
    );
  }

  void _dibujarManguera(Canvas canvas, Rect rect) {
    final centro = rect.center;
    for (var i = 3; i >= 0; i--) {
      final radio = rect.width * (0.14 + i * 0.09);
      canvas.drawCircle(
        centro,
        radio,
        _paint(i == 0
            ? HSLColor.fromColor(color).withLightness(0.3).toColor()
            : color.withOpacity(0.95 - i * 0.08)),
      );
    }
    _brillo(canvas, Rect.fromCircle(center: centro, radius: rect.width * 0.4));
    // Conector
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(centro.dx + rect.width * 0.3, centro.dy - 7, 16, 14),
          const Radius.circular(4)),
      _paint(Colors.grey.shade600),
    );
  }

  void _dibujarCable(Canvas canvas, Rect rect) {
    final centro = rect.center;
    // Flanges
    canvas.drawCircle(
        Offset(centro.dx - rect.width * 0.26, centro.dy),
        rect.width * 0.2,
        _degradado(Rect.fromCircle(
            center: Offset(centro.dx - rect.width * 0.26, centro.dy),
            radius: rect.width * 0.2), Colors.grey.shade600));
    canvas.drawCircle(
        Offset(centro.dx + rect.width * 0.26, centro.dy),
        rect.width * 0.2,
        _degradado(Rect.fromCircle(
            center: Offset(centro.dx + rect.width * 0.26, centro.dy),
            radius: rect.width * 0.2), Colors.grey.shade700));
    // Cable enrollado
    final rollos = Rect.fromLTWH(centro.dx - rect.width * 0.26, centro.dy - 14,
        rect.width * 0.52, 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rollos, const Radius.circular(8)),
      _degradado(rollos, color),
    );
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(rollos.left + (rollos.width / 4) * i, rollos.top + 3),
        Offset(rollos.left + (rollos.width / 4) * i, rollos.bottom - 3),
        _paint(HSLColor.fromColor(color).withLightness(0.3).toColor(),
            stroke: true, width: 2),
      );
    }
  }

  void _dibujarInterruptor(Canvas canvas, Rect rect) {
    final placa = Rect.fromLTWH(
        rect.left + rect.width * 0.2, rect.top + rect.height * 0.14,
        rect.width * 0.6, rect.height * 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(placa, const Radius.circular(12)),
      _degradado(placa, Colors.grey.shade300,
          claro: Colors.white, oscuro: Colors.grey.shade500),
    );
    _brillo(canvas, placa);
    // Boton
    final boton = Rect.fromLTWH(
        placa.center.dx - 9, placa.center.dy - 18, 18, 36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boton, const Radius.circular(6)),
      _degradado(boton, color == 0xFFFAFAFA ? Colors.grey.shade400 : color),
    );
    canvas.drawRect(
      Rect.fromLTWH(boton.left + 3, boton.top + 4, boton.width - 6, 3),
      _paint(Colors.white.withOpacity(0.7)),
    );
  }

  void _dibujarFoco(Canvas canvas, Rect rect) {
    final centro = Offset(rect.center.dx, rect.top + rect.height * 0.38);
    // Resplandor
    canvas.drawCircle(
      centro,
      rect.width * 0.34,
      Paint()
        ..color = color.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Ampolleta
    final focoRect = Rect.fromCircle(center: centro, radius: rect.width * 0.24);
    canvas.drawCircle(
      centro,
      focoRect.width / 2,
      _degradado(focoRect, color,
          claro: Colors.white, oscuro: color.withOpacity(0.8)),
    );
    _brillo(canvas, focoRect);
    // Base
    final base = Rect.fromLTWH(
        centro.dx - rect.width * 0.12, centro.dy + rect.width * 0.2,
        rect.width * 0.24, rect.height * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(6)),
      _degradado(base, Colors.grey.shade500),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(base.left + 3, base.top + 6.0 + i * 7),
        Offset(base.right - 3, base.top + 6.0 + i * 7),
        _paint(Colors.grey.shade700, stroke: true, width: 2),
      );
    }
  }

  void _dibujarCemento(Canvas canvas, Rect rect) {
    final bolsa = Path()
      ..moveTo(rect.left + rect.width * 0.2, rect.top + rect.height * 0.3)
      ..lineTo(rect.left + rect.width * 0.28, rect.top + rect.height * 0.14)
      ..lineTo(rect.right - rect.width * 0.28, rect.top + rect.height * 0.14)
      ..lineTo(rect.right - rect.width * 0.2, rect.top + rect.height * 0.3)
      ..lineTo(rect.right - rect.width * 0.16, rect.bottom - rect.height * 0.1)
      ..quadraticBezierTo(rect.center.dx, rect.bottom - 4,
          rect.left + rect.width * 0.16, rect.bottom - rect.height * 0.1)
      ..close();
    final bounds = bolsa.getBounds();
    canvas.drawPath(
        bolsa,
        _degradado(bounds, Colors.blueGrey.shade400,
            claro: Colors.blueGrey.shade200,
            oscuro: Colors.blueGrey.shade700));
    // Etiqueta
    final etiqueta = Rect.fromLTWH(
        bounds.left + bounds.width * 0.18, bounds.top + bounds.height * 0.3,
        bounds.width * 0.64, bounds.height * 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(etiqueta, const Radius.circular(6)),
      _paint(Colors.white.withOpacity(0.9)),
    );
    canvas.drawRect(
      Rect.fromLTWH(etiqueta.left + 6, etiqueta.top + 7,
          etiqueta.width - 12, 6),
      _paint(color),
    );
    canvas.drawRect(
      Rect.fromLTWH(etiqueta.left + 6, etiqueta.top + 19,
          (etiqueta.width - 12) * 0.7, 4.5),
      _paint(Colors.grey.shade500),
    );
  }

  void _dibujarFierro(Canvas canvas, Rect rect) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.5);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    final barra = Rect.fromLTWH(
        rect.left + 8, rect.center.dy - 7, rect.width - 16, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barra, const Radius.circular(7)),
      _degradado(barra, color, claro: Colors.brown.shade400),
    );
    // Corrugas
    for (var i = 0; i < 6; i++) {
      final x = barra.left + 14.0 + i * ((barra.width - 28) / 5);
      canvas.drawLine(
        Offset(x, barra.top + 1),
        Offset(x, barra.bottom - 1),
        _paint(HSLColor.fromColor(color).withLightness(0.25).toColor(),
            stroke: true, width: 2.5),
      );
    }
    _brillo(canvas, barra);
    canvas.restore();
  }

  void _dibujarClavos(Canvas canvas, Rect rect) {
    final random = math.Random(7);
    for (var i = 0; i < 7; i++) {
      final cx = rect.left + rect.width * (0.2 + random.nextDouble() * 0.6);
      final cy = rect.top + rect.height * (0.25 + random.nextDouble() * 0.5);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(random.nextDouble() * math.pi);
      // Punta y cuerpo
      canvas.drawRect(
        const Rect.fromLTWH(-2, -14, 4, 22),
        _paint(HSLColor.fromColor(color).withLightness(0.45).toColor()),
      );
      // Cabeza
      canvas.drawCircle(const Offset(0, -15), 5, _paint(color));
      canvas.restore();
    }
  }

  void _dibujarTornillos(Canvas canvas, Rect rect) {
    final caja = Rect.fromLTWH(
        rect.left + rect.width * 0.14, rect.top + rect.height * 0.34,
        rect.width * 0.72, rect.height * 0.44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(caja, const Radius.circular(8)),
      _degradado(caja, Colors.grey.shade600,
          claro: Colors.grey.shade400),
    );
    canvas.drawRect(
      Rect.fromLTWH(caja.left, caja.top - 8, caja.width, 10),
      _degradado(Rect.fromLTWH(caja.left, caja.top - 8, caja.width, 10),
          color),
    );
    _brillo(canvas, caja);
    // Tornillos asomando
    final random = math.Random(3);
    for (var i = 0; i < 4; i++) {
      final x = caja.left + 10.0 + i * (caja.width - 20) / 3;
      final y = caja.top - 10 - random.nextDouble() * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.4 + random.nextDouble() * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2.5, -12, 5, 16), const Radius.circular(2.5)),
        _paint(Colors.blueGrey.shade300),
      );
      canvas.drawCircle(const Offset(0, -13), 4.2,
          _paint(Colors.blueGrey.shade400));
      canvas.restore();
    }
  }

  void _dibujarGenerico(Canvas canvas, Rect rect) {
    final caja = Rect.fromLTWH(
        rect.left + rect.width * 0.18, rect.top + rect.height * 0.2,
        rect.width * 0.64, rect.height * 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(caja, const Radius.circular(12)),
      _degradado(caja, color),
    );
    _brillo(canvas, caja);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(caja.left + 10, caja.top + 10,
              caja.width - 20, caja.height * 0.35),
          const Radius.circular(8)),
      _paint(Colors.white.withOpacity(0.25)),
    );
  }

  @override
  bool shouldRepaint(_ProductoPainter oldDelegate) =>
      oldDelegate.tipo != tipo ||
      oldDelegate.color != color ||
      oldDelegate.sombra != sombra;
}

/// Version estatica (sin animacion propia) de la ilustracion. Se usa en
/// los visores 3D, donde la animacion la maneja el contenedor y la
/// ilustracion se dibuja una sola vez y se reutiliza como capa.
class ProductoEstatico extends StatelessWidget {
  final String tipo;
  final int colorHex;
  final double size;
  final bool sombra;

  const ProductoEstatico({
    super.key,
    required this.tipo,
    required this.colorHex,
    this.size = 64,
    this.sombra = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ProductoPainter(
        tipo: tipo,
        color: Color(colorHex),
        sombra: sombra,
      ),
    );
  }
}
