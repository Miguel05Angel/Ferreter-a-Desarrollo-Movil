import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Selector de cantidad con botones animados +/- .
class QuantitySelector extends StatefulWidget {
  final int valor;
  final int maximo;
  final Function(int) onCambio;

  const QuantitySelector({
    super.key,
    required this.valor,
    required this.maximo,
    required this.onCambio,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  bool _restarPresionado = false;
  bool _sumarPresionado = false;

  Widget _boton({
    required IconData icono,
    required VoidCallback? onTap,
    required bool presionado,
    required Function(bool) alCambiar,
  }) {
    return GestureDetector(
      onTapDown: onTap == null ? null : (_) => alCambiar(true),
      onTapUp: onTap == null
          ? null
          : (_) {
              alCambiar(false);
              onTap();
            },
      onTapCancel: onTap == null ? null : () => alCambiar(false),
      child: AnimatedScale(
        scale: presionado ? 0.8 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.grey.withOpacity(0.25)
                : AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono,
              color: onTap == null ? Colors.grey : AppTheme.grafito,
              size: 19),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: oscuro ? const Color(0xFF12161A) : const Color(0xFFEFEBE3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _boton(
            icono: Icons.remove,
            onTap: widget.valor > 1
                ? () => widget.onCambio(widget.valor - 1)
                : null,
            presionado: _restarPresionado,
            alCambiar: (v) => setState(() => _restarPresionado = v),
          ),
          SizedBox(
            width: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim, child: FadeTransition(opacity: anim, child: child)),
              child: Text(
                '${widget.valor}',
                key: ValueKey(widget.valor),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 17,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          _boton(
            icono: Icons.add,
            onTap: widget.valor < widget.maximo
                ? () => widget.onCambio(widget.valor + 1)
                : null,
            presionado: _sumarPresionado,
            alCambiar: (v) => setState(() => _sumarPresionado = v),
          ),
        ],
      ),
    );
  }
}
