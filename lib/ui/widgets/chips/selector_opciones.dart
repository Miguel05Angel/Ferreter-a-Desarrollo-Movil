import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Fila de opciones con animacion al seleccionar (metodos de pago,
/// comprobantes, categorias, etc.).
class SelectorOpciones extends StatelessWidget {
  final List<String> opciones;
  final String seleccionado;
  final Function(String) onSeleccionar;
  final IconData Function(String)? iconoDe;

  const SelectorOpciones({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.onSeleccionar,
    this.iconoDe,
  });

  static IconData iconoPago(String metodo) {
    switch (metodo) {
      case 'Efectivo':
        return Icons.payments_outlined;
      case 'Yape':
        return Icons.phone_iphone;
      case 'Plin':
        return Icons.smartphone;
      case 'Tarjeta':
        return Icons.credit_card;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final borde = oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro;
    final apagado = oscuro ? Colors.grey.shade400 : Colors.grey.shade700;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opciones.map((opcion) {
        final activo = opcion == seleccionado;
        final icono = iconoDe?.call(opcion);
        return GestureDetector(
          onTap: () => onSeleccionar(opcion),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, activo ? -2 : 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: ShapeDecoration(
              color: activo ? AppTheme.primary : Theme.of(context).cardColor,
              shape: BeveledRectangleBorder(
                borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(10)),
                side: BorderSide(
                    color: activo ? AppTheme.primary : borde, width: 1.5),
              ),
              shadows: activo
                  ? const [
                      BoxShadow(
                          color: Color(0xFF8A3A00), offset: Offset(0, 3)),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[
                  Icon(icono,
                      size: 18,
                      color: activo ? AppTheme.grafito : apagado),
                  const SizedBox(width: 7),
                ],
                Text(
                  opcion,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: activo ? FontWeight.w900 : FontWeight.w600,
                    color: activo ? AppTheme.grafito : apagado,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
