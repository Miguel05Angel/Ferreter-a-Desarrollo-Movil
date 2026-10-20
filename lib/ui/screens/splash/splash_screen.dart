import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/visual/decor_industrial.dart';

/// Entrada de la app: se dibuja el plano, un engranaje con grosor real gira
/// y se inclina hacia la camara, el nombre sube desde una linea de corte y
/// una franja de señalizacion cierra la escena. Un toque salta la animacion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _timer;
  bool _saliendo = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 3700), _ir);
  }

  void _ir() {
    if (_saliendo || !mounted) return;
    _saliendo = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  double _tramo(double a, double b, [Curve curva = Curves.easeOutCubic]) {
    final v = ((_c.value - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    return curva.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.grafito,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _ir,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final plano = _tramo(0.0, 0.40, Curves.easeOut);
            final entrada = _tramo(0.04, 0.50, Curves.easeOutBack);
            final giro = _tramo(0.0, 0.95, Curves.easeOutCubic);
            final inclinacion = _tramo(0.18, 0.80, Curves.easeInOutCubic);
            final etiqueta = _tramo(0.45, 0.70);
            final nombre1 = _tramo(0.52, 0.78);
            final nombre2 = _tramo(0.60, 0.86);
            final eslogan = _tramo(0.78, 1.0);
            final franja = _tramo(0.72, 1.0, Curves.easeInOutCubic);

            final tam = math.min(MediaQuery.of(context).size.width * 0.62, 260.0);

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: PlanoPainter(progreso: plano)),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 30, 32, 0),
                        child: Opacity(
                          opacity: etiqueta,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              _Mono('FERRETERIA', Paleta.naranja),
                              _Mono('LIMA  -  PERU', Color(0x99EDE8DF)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Opacity(
                            opacity: entrada.clamp(0.0, 1.0).toDouble(),
                            child: Transform.scale(
                              scale: 0.35 + 0.65 * entrada,
                              child: Engranaje3D(
                                size: tam,
                                angulo: giro * math.pi * 3,
                                inclX: 0.95 * inclinacion,
                                inclY: -0.42 * inclinacion,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Corte(
                              valor: nombre1,
                              child: const _Nombre('EL', Paleta.hueso),
                            ),
                            _Corte(
                              valor: nombre2,
                              child:
                                  const _Nombre('CONSTRUCTOR', Paleta.naranja),
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: eslogan,
                              child: Text(
                                AppConstants.eslogan.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  letterSpacing: 3,
                                  color: Color(0x99EDE8DF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      FranjaPeligro(alto: 16, avance: franja),
                    ],
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

class _Mono extends StatelessWidget {
  final String texto;
  final Color color;

  const _Mono(this.texto, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _Nombre extends StatelessWidget {
  final String texto;
  final Color color;

  const _Nombre(this.texto, this.color);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 54,
          height: 0.98,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: color,
        ),
      ),
    );
  }
}

/// Revela su contenido subiendo desde debajo de una linea de corte.
class _Corte extends StatelessWidget {
  final double valor;
  final Widget child;

  const _Corte({required this.valor, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, (1 - valor) * 70),
        child: child,
      ),
    );
  }
}
