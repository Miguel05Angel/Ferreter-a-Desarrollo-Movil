import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../carrito/carrito_flotante.dart';
import '../visual/decor_industrial.dart';

/// Barra superior de la app: plano tecnico de fondo, marca naranja que
/// crece, titulo que sube desde una linea de corte, subtitulo tecnico y
/// franja de obra que se despliega. Incluye el boton de carrito.
class AppBarTaller extends StatefulWidget implements PreferredSizeWidget {
  final Widget title;
  final String? subtitulo;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool mostrarCarrito;

  const AppBarTaller({
    super.key,
    required this.title,
    this.subtitulo,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.mostrarCarrito = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  State<AppBarTaller> createState() => _AppBarTallerState();
}

class _AppBarTallerState extends State<AppBarTaller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _tramo(double a, double b, Curve curva) {
    final v = ((_c.value - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    return curva.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final puedeVolver =
        widget.automaticallyImplyLeading && Navigator.of(context).canPop();

    return Theme(
      data: Theme.of(context).copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: AppTheme.hueso),
        ),
      ),
      child: Container(
      color: AppTheme.grafito,
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final marca = _tramo(0.0, 0.45, Curves.easeOutBack);
            final titulo = _tramo(0.12, 0.6, Curves.easeOutCubic);
            final sub = _tramo(0.35, 0.8, Curves.easeOut);
            final franja = _tramo(0.3, 1.0, Curves.easeInOutCubic);

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.55,
                          child: CustomPaint(painter: PlanoPainter()),
                        ),
                      ),
                      Row(
                        children: [
                          if (puedeVolver)
                            _BotonVolver(
                                onTap: () => Navigator.of(context).maybePop())
                          else
                            const SizedBox(width: 18),
                          // marca naranja
                          Container(
                            width: 5,
                            height: 30 * marca.clamp(0.0, 1.2).toDouble(),
                            margin: EdgeInsets.only(
                                left: puedeVolver ? 4 : 0, right: 11),
                            color: AppTheme.primary,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRect(
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - titulo) * 34),
                                    child: DefaultTextStyle(
                                      style: const TextStyle(
                                        fontSize: 21,
                                        height: 1.1,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                        color: AppTheme.hueso,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      child: widget.title,
                                    ),
                                  ),
                                ),
                                if (widget.subtitulo != null)
                                  Opacity(
                                    opacity: sub,
                                    child: Transform.translate(
                                      offset: Offset((1 - sub) * -14, 0),
                                      child: Text(
                                        widget.subtitulo!.toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 9.5,
                                          letterSpacing: 2.6,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ...?widget.actions,
                          if (widget.mostrarCarrito) const BotonCarrito(),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
                FranjaPeligro(alto: 5, avance: franja),
              ],
            );
          },
        ),
      ),
    ),
    );
  }
}

class _BotonVolver extends StatelessWidget {
  final VoidCallback onTap;

  const _BotonVolver({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Container(
          width: 38,
          height: 38,
          decoration: const ShapeDecoration(
            color: Color(0xFF242A30),
            shape: BeveledRectangleBorder(
              borderRadius:
                  BorderRadius.only(bottomRight: Radius.circular(12)),
            ),
          ),
          child: const Icon(Icons.arrow_back, color: AppTheme.hueso, size: 21),
        ),
      ),
    );
  }
}
