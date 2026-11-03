import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Pasa todo lo que contiene a escala de grises cuando [activo] es true
/// (producto agotado).
class EscalaGrises extends StatelessWidget {
  final bool activo;
  final Widget child;

  const EscalaGrises({super.key, required this.activo, required this.child});

  static const ColorFilter _gris = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    if (!activo) return child;
    return ColorFiltered(colorFilter: _gris, child: child);
  }
}

/// Triangulo de advertencia animado que se coloca sobre la imagen de un
/// producto agotado.
class TrianguloAdvertencia extends StatefulWidget {
  final double size;
  const TrianguloAdvertencia({super.key, this.size = 46});

  @override
  State<TrianguloAdvertencia> createState() => _TrianguloAdvertenciaState();
}

class _TrianguloAdvertenciaState extends State<TrianguloAdvertencia>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 0.88 + 0.22 * t,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.amarilloSenal.withValues(alpha: 0.25 + 0.45 * t),
                    blurRadius: 10 + 16 * t,
                    spreadRadius: 1 + 3 * t,
                  ),
                ],
              ),
              child: Icon(Icons.warning_rounded,
                  size: widget.size, color: AppTheme.amarilloSenal),
            ),
          );
        },
      ),
    );
  }
}
