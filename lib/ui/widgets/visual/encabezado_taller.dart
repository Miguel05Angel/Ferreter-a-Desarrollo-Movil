import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'decor_industrial.dart';

/// Cabecera de las pantallas de acceso: plano tecnico, un engranaje 3D
/// que gira lentamente y el nombre de la tienda en tipografia grande.
class EncabezadoTaller extends StatefulWidget {
  final String linea1;
  final String linea2;
  final String subtitulo;
  final double alto;

  const EncabezadoTaller({
    super.key,
    this.linea1 = 'EL',
    this.linea2 = 'CONSTRUCTOR',
    required this.subtitulo,
    this.alto = 300,
  });

  @override
  State<EncabezadoTaller> createState() => _EncabezadoTallerState();
}

class _EncabezadoTallerState extends State<EncabezadoTaller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _giro;

  @override
  void initState() {
    super.initState();
    _giro = AnimationController(
        vsync: this, duration: const Duration(seconds: 22))
      ..repeat();
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
      height: widget.alto,
      width: double.infinity,
      color: Paleta.grafito,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: PlanoPainter())),
          Positioned(
            right: -70,
            top: 10,
            width: 280,
            height: 280,
            child: AnimatedBuilder(
              animation: _giro,
              builder: (context, _) => Engranaje3D(
                size: 280,
                angulo: _giro.value * 2 * math.pi,
                inclX: 0.75,
                inclY: -0.35,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subtitulo.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                      color: Paleta.naranja,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.linea1,
                    style: const TextStyle(
                      fontSize: 50,
                      height: 0.98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: Paleta.hueso,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.linea2,
                      style: const TextStyle(
                        fontSize: 50,
                        height: 0.98,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: Paleta.naranja,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
