import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/cotizacion_borrador_provider.dart';
import '../carrito/carrito_flotante.dart';

/// Boton del listado de cotizacion (reemplaza al carrito en el catalogo
/// cuando se eligen productos para cotizar). El producto "vuela" hasta aqui
/// igual que hacia el carrito, rebota y suelta un "+1".
class BotonListadoCotizacion extends StatefulWidget {
  final VoidCallback onTap;
  const BotonListadoCotizacion({super.key, required this.onTap});

  @override
  State<BotonListadoCotizacion> createState() => _BotonListadoCotizacionState();
}

class _BotonListadoCotizacionState extends State<BotonListadoCotizacion>
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
    final ctx = _llave.currentContext;
    if (ctx == null || !TickerMode.of(ctx)) return;
    _pulso.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final borrador = context.watch<CotizacionBorradorProvider>();
    final unidades = borrador.unidades;
    final lleno = unidades > 0;

    return GestureDetector(
      onTap: widget.onTap,
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
                Transform.rotate(
                  angle: sacudida,
                  child: Transform.scale(scale: escala, child: child),
                ),
                if (v > 0.05 && v < 0.95)
                  Positioned(
                    top: -4 - 26 * v,
                    child: Opacity(
                      opacity: (1 - v).clamp(0.0, 1.0).toDouble(),
                      child: const Text('+1',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary)),
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
                Icon(Icons.request_quote,
                    size: 20,
                    color: lleno ? AppTheme.grafito : AppTheme.primary),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: lleno
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Text(
                              '$unidades',
                              key: ValueKey(unidades),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.grafito,
                              ),
                            ),
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
