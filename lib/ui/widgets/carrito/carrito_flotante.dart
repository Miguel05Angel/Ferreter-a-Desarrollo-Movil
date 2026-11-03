import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/carrito_provider.dart';
import '../../screens/main/main_shell_screen.dart';
import '../visual/producto_illustration.dart';

/// Llave del navegador principal.
final GlobalKey<NavigatorState> navegadorGlobal = GlobalKey<NavigatorState>();

/// Registro de los botones de carrito que hay en pantalla. El producto que
/// "vuela" al carrito apunta al boton visible en ese momento.
class CarritoFlotante {
  CarritoFlotante._();

  /// Se incrementa cada vez que un producto llega al carrito.
  static final ValueNotifier<int> rebote = ValueNotifier<int>(0);

  static final List<GlobalKey> _claves = [];

  static GlobalKey registrar() {
    final k = GlobalKey();
    _claves.add(k);
    return k;
  }

  static void liberar(GlobalKey k) => _claves.remove(k);

  /// Centro (en pantalla) del boton de carrito visible, o null si no hay.
  static Offset? destino() {
    for (final k in _claves.reversed) {
      final ctx = k.currentContext;
      if (ctx == null) continue;
      if (!TickerMode.of(ctx)) continue; // pestanas ocultas
      final ruta = ModalRoute.of(ctx);
      if (ruta != null && !ruta.isCurrent) continue; // pantallas tapadas
      final caja = ctx.findRenderObject();
      if (caja is RenderBox && caja.hasSize && caja.attached) {
        return caja.localToGlobal(caja.size.center(Offset.zero));
      }
    }
    return null;
  }
}

/// Boton de carrito para barras superiores y cabeceras. Muestra cuantas
/// unidades hay y el total; cuando llega un producto vuela hacia el, rebota,
/// se sacude y suelta un "+1".
class BotonCarrito extends StatefulWidget {
  const BotonCarrito({super.key});

  @override
  State<BotonCarrito> createState() => _BotonCarritoState();
}

class _BotonCarritoState extends State<BotonCarrito>
    with SingleTickerProviderStateMixin {
  late final GlobalKey _llave = CarritoFlotante.registrar();
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    CarritoFlotante.rebote.addListener(_alRebotar);
  }

  @override
  void dispose() {
    CarritoFlotante.rebote.removeListener(_alRebotar);
    CarritoFlotante.liberar(_llave);
    _pulso.dispose();
    super.dispose();
  }

  void _alRebotar() {
    // Solo reacciona el boton que esta a la vista
    final ctx = _llave.currentContext;
    if (ctx == null || !TickerMode.of(ctx)) return;
    _pulso.forward(from: 0);
  }

  void _irAlCarrito() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    ShellNavegacion.irA(3);
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final unidades = carrito.items.fold<int>(0, (a, i) => a + i.cantidad);
    final total = carrito.subtotal * 1.18;
    final lleno = unidades > 0;

    return GestureDetector(
      onTap: _irAlCarrito,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedBuilder(
          animation: _pulso,
          builder: (context, child) {
            final v = _pulso.value;
            final rebote = Curves.elasticOut.transform(v);
            final escala = v == 0 ? 1.0 : 1 + 0.30 * (1 - rebote);
            final sacudida = v == 0 ? 0.0 : math.sin(v * 22) * 0.10 * (1 - v);
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Halo que se expande al llegar el producto
                if (v > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: (1 - v).clamp(0.0, 1.0).toDouble() * 0.7,
                      child: Transform.scale(
                        scale: 1 + v * 0.9,
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: BeveledRectangleBorder(
                              borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(12)),
                              side: BorderSide(
                                  color: AppTheme.primary, width: 2.5 * (1 - v)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Transform.rotate(
                  angle: sacudida,
                  child: Transform.scale(scale: escala, child: child),
                ),
                // +1 que sube
                if (v > 0.05 && v < 0.95)
                  Positioned(
                    top: -4 - 26 * v,
                    child: Opacity(
                      opacity: (1 - v).clamp(0.0, 1.0).toDouble(),
                      child: const Text(
                        '+1',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          child: AnimatedContainer(
            key: _llave,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: lleno ? 11 : 9),
            decoration: ShapeDecoration(
              color: lleno ? AppTheme.primary : Colors.transparent,
              shape: BeveledRectangleBorder(
                borderRadius:
                    const BorderRadius.only(bottomRight: Radius.circular(12)),
                side: BorderSide(
                    color: AppTheme.primary, width: lleno ? 0 : 1.8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart,
                    size: 20,
                    color: lleno ? AppTheme.grafito : AppTheme.primary),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: lleno
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (c, a) =>
                                    ScaleTransition(scale: a, child: c),
                                child: Text(
                                  '$unidades',
                                  key: ValueKey(unidades),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.0,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.grafito,
                                  ),
                                ),
                              ),
                              Text(
                                'S/ ${total.toStringAsFixed(total >= 100 ? 0 : 1)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.grafito,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: 0, height: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animacion del producto 3D volando hacia el boton del carrito.
class VueloAlCarrito {
  VueloAlCarrito._();

  /// [desde] es el punto (en coordenadas de pantalla) donde empieza el vuelo.
  static void lanzar(
    BuildContext context, {
    required String tipo,
    required int colorHex,
    required Offset desde,
    double tam = 110,
    String? imagenUrl,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final mq = MediaQuery.of(context);

    final hasta = CarritoFlotante.destino() ??
        Offset(mq.size.width - 52, mq.padding.top + 32);

    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (_) => _Vuelo(
        tipo: tipo,
        colorHex: colorHex,
        desde: desde,
        hasta: hasta,
        tam: tam,
        imagenUrl: imagenUrl,
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
  final String? imagenUrl;
  final VoidCallback alTerminar;

  const _Vuelo({
    required this.tipo,
    required this.colorHex,
    required this.desde,
    required this.hasta,
    required this.tam,
    required this.imagenUrl,
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
    final control = Offset((a.dx + b.dx) / 2 - 40, math.min(a.dy, b.dy) - 90);
    final u = 1 - t;
    return a * (u * u) + control * (2 * u * t) + b * (t * t);
  }

  Widget _pieza(double t, double opacidad) {
    final pos = _curva(t);
    final escala = 1 - 0.80 * Curves.easeIn.transform(t);
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
            child: widget.imagenUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.imagenUrl!,
                    width: widget.tam,
                    height: widget.tam,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => ProductoEstatico(
                      tipo: widget.tipo,
                      colorHex: widget.colorHex,
                      size: widget.tam,
                      sombra: true,
                    ),
                  )
                : ProductoEstatico(
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
