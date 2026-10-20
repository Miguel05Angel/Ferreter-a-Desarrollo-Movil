import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/producto.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/producto_illustration.dart';

/// Pantalla de bienvenida: los productos de la tienda orbitan en 3D sobre un
/// plato giratorio. Se puede arrastrar para girarlos; el producto que queda
/// al frente muestra su ficha tecnica debajo.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  static const double _velReposo = 0.30; // rad/s
  static const double _duracionEntrada = 2.2; // s

  late final AnimationController _intro;
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  final ValueNotifier<int> _frente = ValueNotifier<int>(0);
  late final List<Producto> _items;

  double _rot = 0.9;
  double _vel = 3.4; // arranca girando rapido y frena hasta el reposo
  double _entrada = 0;
  bool _arrastrando = false;
  bool _tocado = false;
  Duration _ultimo = Duration.zero;

  int get _n => _items.length;

  @override
  void initState() {
    super.initState();
    _items = _elegir(context.read<ProductoProvider>().productos);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _ticker = createTicker(_tick)..start();
  }

  /// Un producto por tipo de ilustracion, hasta 8, para que el anillo sea
  /// variado.
  List<Producto> _elegir(List<Producto> todos) {
    final vistos = <String>{};
    final res = <Producto>[];
    for (final p in todos) {
      if (vistos.add(p.tipoVisual)) res.add(p);
      if (res.length == 8) break;
    }
    return res.isEmpty ? todos.take(8).toList() : res;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _intro.dispose();
    _frame.dispose();
    _frente.dispose();
    super.dispose();
  }

  void _tick(Duration t) {
    final dt = ((t - _ultimo).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _ultimo = t;
    if (!_arrastrando) {
      _vel += (_velReposo - _vel) * (1 - math.exp(-1.8 * dt));
      _rot += _vel * dt;
    }
    _entrada =
        (t.inMicroseconds / 1e6 / _duracionEntrada).clamp(0.0, 1.0).toDouble();

    if (_n > 0) {
      final paso = 2 * math.pi / _n;
      final idx = (-_rot / paso).round() % _n;
      if (_frente.value != idx) _frente.value = idx;
    }
    _frame.value++;
  }

  double _tramo(double a, double b, [Curve curva = Curves.easeOutCubic]) {
    final v = ((_intro.value - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    return curva.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.grafito,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) => CustomPaint(
                painter: PlanoPainter(progreso: _tramo(0, 0.5, Curves.easeOut)),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                final cabecera = _tramo(0.0, 0.25);
                final titulo1 = _tramo(0.08, 0.38);
                final titulo2 = _tramo(0.16, 0.46);
                final pie = _tramo(0.55, 0.90);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
                      child: Opacity(
                        opacity: cabecera,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                    width: 10, height: 10, color: Paleta.naranja),
                                const SizedBox(width: 8),
                                const _Mono('EL CONSTRUCTOR', Paleta.hueso),
                              ],
                            ),
                            _Mono('${_n.toString().padLeft(2, '0')} REFERENCIAS',
                                const Color(0x99EDE8DF)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Corte(
                            valor: titulo1,
                            child: const _Titular('TODO PARA', Paleta.hueso),
                          ),
                          _Corte(
                            valor: titulo2,
                            child: const _Titular(
                                'TU CONSTRUCCION', Paleta.naranja),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _escenario()),
                    Opacity(
                      opacity: pie,
                      child: Transform.translate(
                        offset: Offset(0, (1 - pie) * 30),
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: SizedBox(height: 86, child: _ficha()),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: _BotonBiselado(
                                texto: 'ENTRAR A LA TIENDA',
                                onTap: () => Navigator.of(context)
                                    .pushReplacementNamed(AppRoutes.main),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const FranjaPeligro(alto: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- escenario

  Widget _escenario() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final radio = w * 0.35;
        final tam = math.min(w * 0.36, h * 0.58);
        final ry = math.min(h * 0.09, 30.0);
        final cx = w / 2;
        final sueloY = h * 0.70;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            _arrastrando = true;
            if (!_tocado) setState(() => _tocado = true);
          },
          onHorizontalDragUpdate: (d) => _rot += d.delta.dx * 0.011,
          onHorizontalDragEnd: (d) {
            _arrastrando = false;
            _vel = ((d.primaryVelocity ?? 0) * 0.011).clamp(-9.0, 9.0).toDouble();
          },
          onHorizontalDragCancel: () => _arrastrando = false,
          child: ValueListenableBuilder<int>(
            valueListenable: _frame,
            builder: (context, _, __) {
              final hijos = <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PlatoPainter(
                      rot: _rot,
                      centro: Offset(cx, sueloY),
                      rx: radio * 1.22,
                      ry: ry * 1.55,
                      k: Curves.easeOut.transform(_entrada),
                    ),
                  ),
                ),
              ];

              if (_n > 0) {
                final paso = 2 * math.pi / _n;
                final orden = List<int>.generate(_n, (i) => i);
                orden.sort((a, b) => math.cos(_rot + a * paso)
                    .compareTo(math.cos(_rot + b * paso)));

                // Escalonado de la entrada: cada pieza sale del centro a su
                // turno.
                final salto = _n > 1 ? 0.35 / (_n - 1) : 0.0;
                final ventana = 1 - (_n - 1) * salto;

                for (final i in orden) {
                  final p = _items[i];
                  final a = _rot + i * paso;
                  final d = math.cos(a); // 1 = al frente
                  final prof = (d + 1) / 2; // 0 atras, 1 al frente

                  final vi =
                      ((_entrada - i * salto) / ventana).clamp(0.0, 1.0).toDouble();
                  final k = Curves.easeOutBack.transform(vi);

                  final x = math.sin(a) * radio * k;
                  final piso = sueloY + d * ry * k;
                  final escala = (0.55 + 0.45 * prof) * k.clamp(0.0, 1.15);
                  final opacidad = (0.30 + 0.70 * prof) * vi;

                  // Sombra de contacto
                  hijos.add(Positioned(
                    left: cx + x - tam * 0.5,
                    top: piso - tam * 0.07,
                    width: tam,
                    height: tam * 0.14,
                    child: Opacity(
                      opacity: (0.7 * opacidad).clamp(0.0, 1.0).toDouble(),
                      child: Transform.scale(
                        scale: escala,
                        child: const _Sombra(),
                      ),
                    ),
                  ));

                  // Pieza
                  hijos.add(Positioned(
                    left: cx + x - tam / 2,
                    top: piso - tam * 0.42 * escala - tam / 2 + tam * 0.08,
                    width: tam,
                    height: tam,
                    child: Opacity(
                      opacity: opacidad.clamp(0.0, 1.0).toDouble(),
                      child: Transform.scale(
                        scale: escala,
                        child: RepaintBoundary(
                          child: ProductoEstatico(
                            tipo: p.tipoVisual,
                            colorHex: p.colorHex,
                            size: tam,
                          ),
                        ),
                      ),
                    ),
                  ));
                }
              }

              // Mira fija sobre la posicion frontal
              final frenteY = sueloY + ry - tam * 0.42 + tam * 0.08;
              hijos.add(Positioned(
                left: cx - tam * 0.58,
                top: frenteY - tam * 0.58,
                width: tam * 1.16,
                height: tam * 1.16,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: Curves.easeIn
                        .transform(((_entrada - 0.6) / 0.4).clamp(0.0, 1.0).toDouble()),
                    child: CustomPaint(painter: _MiraPainter()),
                  ),
                ),
              ));

              hijos.add(Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _tocado ? 0 : 1,
                  child: const Center(
                    child: _Mono('<  ARRASTRA PARA GIRAR  >', Color(0x99EDE8DF)),
                  ),
                ),
              ));

              return Stack(children: hijos);
            },
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------- ficha

  Widget _ficha() {
    return ValueListenableBuilder<int>(
      valueListenable: _frente,
      builder: (context, i, _) {
        if (_items.isEmpty) return const SizedBox.shrink();
        final p = _items[i.clamp(0, _items.length - 1).toInt()];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _Ficha(
            key: ValueKey(p.id),
            producto: p,
            indice: i,
            total: _items.length,
          ),
        );
      },
    );
  }
}

class _Ficha extends StatelessWidget {
  final Producto producto;
  final int indice;
  final int total;

  const _Ficha({
    super.key,
    required this.producto,
    required this.indice,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Mono('REF. ${producto.codigo}', Paleta.naranja),
            _Mono(
              '${(indice + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
              const Color(0x99EDE8DF),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          producto.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Paleta.hueso,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.soles(producto.precioVenta),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Paleta.naranja,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: _Mono(
                  producto.marca.toUpperCase(), const Color(0x99EDE8DF)),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- componentes

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
        letterSpacing: 2.2,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _Titular extends StatelessWidget {
  final String texto;
  final Color color;

  const _Titular(this.texto, this.color);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 38,
          height: 1.0,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
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
        offset: Offset(0, (1 - valor) * 50),
        child: child,
      ),
    );
  }
}

/// Boton de esquina cortada (bisel), como una chapa de herramienta.
class _BotonBiselado extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _BotonBiselado({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BiselClipper(),
      child: Material(
        color: Paleta.naranja,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Paleta.grafito,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward,
                    color: Paleta.grafito, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BiselClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const corte = 16.0;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - corte)
      ..lineTo(size.width - corte, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_BiselClipper oldClipper) => false;
}

class _Sombra extends StatelessWidget {
  const _Sombra();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.elliptical(200, 60)),
        gradient: RadialGradient(
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
        ),
      ),
    );
  }
}

/// Aro graduado del plato giratorio, en perspectiva.
class _PlatoPainter extends CustomPainter {
  final double rot;
  final Offset centro;
  final double rx;
  final double ry;
  final double k;

  _PlatoPainter({
    required this.rot,
    required this.centro,
    required this.rx,
    required this.ry,
    required this.k,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rx = this.rx * k;
    final ry = this.ry * k;
    if (rx < 1) return;

    final linea = Paint()
      ..color = Paleta.linea
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawOval(
        Rect.fromCenter(center: centro, width: rx * 2, height: ry * 2), linea);
    canvas.drawOval(
        Rect.fromCenter(
            center: centro, width: rx * 2 * 0.62, height: ry * 2 * 0.62),
        linea..color = Paleta.linea.withOpacity(0.6));

    const marcas = 72;
    final tick = Paint()..strokeWidth = 1.5;
    for (var j = 0; j < marcas; j++) {
      final a = rot + j * 2 * math.pi / marcas;
      final delante = (math.sin(a) + 1) / 2;
      final largo = j % 6 == 0 ? 0.11 : 0.055;
      final p1 = Offset(centro.dx + math.cos(a) * rx * 1.0,
          centro.dy + math.sin(a) * ry * 1.0);
      final p2 = Offset(centro.dx + math.cos(a) * rx * (1 - largo),
          centro.dy + math.sin(a) * ry * (1 - largo));
      tick.color = (j % 6 == 0 ? Paleta.naranja : Paleta.hueso)
          .withOpacity(0.10 + 0.55 * delante);
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(_PlatoPainter old) =>
      old.rot != rot || old.k != k || old.centro != centro;
}

/// Esquinas de mira alrededor del producto que esta al frente.
class _MiraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Paleta.naranja
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    const l = 18.0;
    final r = Offset.zero & size;

    void esquina(Offset c, double dx, double dy) {
      canvas.drawLine(c, c.translate(dx * l, 0), p);
      canvas.drawLine(c, c.translate(0, dy * l), p);
    }

    esquina(r.topLeft, 1, 1);
    esquina(r.topRight, -1, 1);
    esquina(r.bottomLeft, 1, -1);
    esquina(r.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(_MiraPainter old) => false;
}
