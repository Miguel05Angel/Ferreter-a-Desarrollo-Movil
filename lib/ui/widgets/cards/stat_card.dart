import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tarjeta de estadistica estilo ficha: barra de color a la izquierda,
/// etiqueta en mayusculas y cifra grande con contador animado.
class StatCard extends StatelessWidget {
  final String titulo;
  final double valor;
  final String prefijo;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;
  final bool esMoneda;

  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.prefijo = '',
    this.onTap,
    this.esMoneda = false,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icono, color: color, size: 17),
                          const SizedBox(width: 6),
                          Text(
                            titulo.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: valor),
                        duration: const Duration(milliseconds: 1300),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) {
                          final texto = esMoneda
                              ? '$prefijo${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}'
                              : v.toStringAsFixed(0);
                          return Text(
                            texto,
                            style: const TextStyle(
                              fontSize: 28,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
