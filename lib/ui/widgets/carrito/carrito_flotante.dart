import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/carrito_provider.dart';
import '../../screens/main/main_shell_screen.dart';
import '../visual/producto_illustration.dart';

/// Llave del navegador principal: permite que el carrito flotante (que vive
/// por encima de todas las pantallas) navegue.
final GlobalKey<NavigatorState> navegadorGlobal = GlobalKey<NavigatorState>();

/// Carrito flotante: burbuja que se puede arrastrar y que se pega al borde
/// de la pantalla. Muestra cuantos articulos hay y el total, y rebota cuando
/// un producto "aterriza" en ella.
class CarritoFlotante extends StatefulWidget {
  const CarritoFlotante({super.key});

  /// El shell lo activa cuando el usuario ya esta dentro de la tienda.
  static final ValueNotifier<bool> activo = ValueNotifier<bool>(false);

  /// Pantallas que necesitan ocultarlo temporalmente (por ejemplo el pago).
  static final ValueNotifier<int> bloqueos = ValueNotifier<int>(0);

  /// Se incrementa cada vez que un producto llega al carrito.
  static final ValueNotifier<int> rebote = ValueNotifier<int>(0);

  /// Para ubicar la burbuja en pantalla y apuntar la animacion de vuelo.
  static final GlobalKey llave = GlobalKey();

  static void bloquear() {
    WidgetsBinding.instance.addPostFrameCallback((_) => bloqueos.value++);
  }

  static void desbloquear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bloqueos.value > 0) bloqueos.value--;
    });
  }

  @override
  State<CarritoFlotante> createState() => _CarritoFlotanteState();
}

class _CarritoFlotanteState extends State<CarritoFlotante>
    with SingleTickerProviderStateMixin {
  static const double _tam = 64;

  late final AnimationController _pulso;
  Offset? _pos;
  bool _arrastrando = false;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    CarritoFlotante.rebote.addListener(_alRebotar);
  }

  @override
  void dispose() {
    CarritoFlotante.rebote.removeListener(_alRebotar);
    _pulso.dispose();
    super.dispose();
  }

  void _alRebotar() => _pulso.forward(from: 0);

  void _irAlCarrito() {
    navegadorGlobal.currentState?.popUntil((r) => r.isFirst);
    ShellNavegacion.irA(3);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: CarritoFlotante.activo,
      builder: (context, activo, _) => ValueListenableBuilder<int>(
        valueListenable: CarritoFlotante.bloqueos,
        builder: (context, bloqueos, __) {
          final visible = activo && bloqueos == 0;
          return LayoutBuilder(
            builder: (context, c) {
              final mq = MediaQuery.of(context);
              final minY = mq.padding.top + 12;
              final maxY = c.maxHeight - mq.padding.bottom - 66 - _tam - 14;
              final maxX = c.maxWidth - _tam - 12;

              _pos ??= Offset(maxX, c.maxHeight * 0.52);
              final pos = Offset(
                _pos!.dx.clamp(12.0, maxX).toDouble(),
                _pos!.dy.clamp(minY, math.max(minY, maxY)).toDouble(),
              );

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: _arrastrando
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    left: pos.dx,
                    top: pos.dy,
                    width: _tam,
                    height: _tam + 32,
                    child: IgnorePointer(
                      ignoring: !visible,
                      child: AnimatedScale(
                        scale: visible ? 1 : 0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        child: GestureDetector(
                          onTap: _irAlCarrito,
                          onPanStart: (_) =>
                              setState(() => _arrastrando = true),
                          onPanUpdate: (d) =>
                              setState(() => _pos = pos + d.delta),
                          onPanEnd: (_) {
                            final alIzq = (pos.dx + _tam / 2) < c.maxWidth / 2;
                            setState(() {
                              _arrastrando = false;
                              _pos = Offset(alIzq ? 12 : maxX, pos.dy);
                            });
                          },
                          child: _Burbuja(pulso: _pulso),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final Animation<double> pulso;

  const _Burbuja({required this.pulso});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final total = carrito.subtotal * 1.18;
    final cantidad = carrito.items.fold<int>(0, (a, i) => a + i.cantidad);

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: pulso,
        builder: (context, child) {
          final v = Curves.elasticOut.transform(pulso.value);
          final escala = pulso.isAnimating || pulso.value > 0
              ? 1 + 0.32 * (1 - v)
              : 1.0;
          return Transform.scale(scale: escala, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: CarritoFlotante.llave,
                  width: 64,
                  height: 64,
                  decoration: const ShapeDecoration(
                    color: AppTheme.grafito,
                    shape: BeveledRectangleBorder(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(20)),
                      side: BorderSide(color: AppTheme.primary, width: 2.4),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shopping_cart,
                      color: AppTheme.primary, size: 30),
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: AnimatedScale(
                    scale: cantidad > 0 ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 22, minHeight: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppTheme.grafito, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$cantidad',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.grafito),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: cantidad > 0
                  ? Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'S/ ${total.toStringAsFixed(total >= 100 ? 0 : 1)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.grafito,
                        ),
                      ),
                    )
                  : const SizedBox(height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animacion del producto 3D volando hacia el carrito flotante.
class VueloAlCarrito {
  VueloAlCarrito._();

  /// [desde] es el punto (en coordenadas de pantalla) donde empieza el vuelo.
  static void lanzar(
    BuildContext context, {
    required String tipo,
    required int colorHex,
    required Offset desde,
    double tam = 110,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final size = MediaQuery.of(context).size;

    Offset hasta = Offset(size.width - 44, size.height * 0.55);
    final caja = CarritoFlotante.llave.currentContext?.findRenderObject();
    if (caja is RenderBox && caja.hasSize && caja.attached) {
      hasta = caja.localToGlobal(caja.size.center(Offset.zero));
    }

    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (_) => _Vuelo(
        tipo: tipo,
        colorHex: colorHex,
        desde: desde,
        hasta: hasta,
        tam: tam,
        alTerminar: () {
          entrada.remove();
          CarritoFlotante.rebote.value++;
        },
      ),
    );
    overlay.insert(entrada);
  }
}

class _Vuelo extends StatefulWidget {
  final String tipo;
  final int colorHex;
  final Offset desde;
  final Offset hasta;
  final double tam;
  final VoidCallback alTerminar;

  const _Vuelo({
    required this.tipo,
    required this.colorHex,
    required this.desde,
    required this.hasta,
    required this.tam,
    required this.alTerminar,
  });

  @override
  State<_Vuelo> createState() => _VueloState();
}

class _VueloState extends State<_Vuelo> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.alTerminar();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _curva(double t) {
    final a = widget.desde;
    final b = widget.hasta;
    final control = Offset((a.dx + b.dx) / 2 - 40, math.min(a.dy, b.dy) - 150);
    final u = 1 - t;
    return a * (u * u) + control * (2 * u * t) + b * (t * t);
  }

  Widget _pieza(double t, double opacidad) {
    final pos = _curva(t);
    final escala = 1 - 0.78 * Curves.easeIn.transform(t);
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..rotateY(t * math.pi * 3)
      ..rotateZ(-t * 0.7);
    return Positioned(
      left: pos.dx - widget.tam / 2,
      top: pos.dy - widget.tam / 2,
      width: widget.tam,
      height: widget.tam,
      child: Opacity(
        opacity: opacidad.clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(
          scale: escala,
          child: Transform(
            alignment: Alignment.center,
            transform: m,
            child: ProductoEstatico(
              tipo: widget.tipo,
              colorHex: widget.colorHex,
              size: widget.tam,
              sombra: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final fin = _c.value > 0.88 ? (1 - _c.value) / 0.12 : 1.0;
          return Stack(
            children: [
              // estela
              for (var k = 3; k >= 1; k--)
                if (t - k * 0.045 > 0)
                  _pieza(t - k * 0.045, (0.22 - k * 0.05) * fin),
              _pieza(t, fin),
            ],
          );
        },
      ),
    );
  }
}
