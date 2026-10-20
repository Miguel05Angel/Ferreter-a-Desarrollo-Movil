import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Encabezado de seccion: marca naranja, titulo en mayusculas, linea fina
/// y accion opcional.
class SectionHeader extends StatelessWidget {
  final String titulo;
  final String? textoAccion;
  final VoidCallback? onAccion;

  const SectionHeader({
    super.key,
    required this.titulo,
    this.textoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Row(
        children: [
          Container(width: 6, height: 20, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1.2,
              color: oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro,
            ),
          ),
          if (textoAccion != null && onAccion != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAccion,
              child: Row(
                children: [
                  Text(
                    textoAccion!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: oscuro
                          ? AppTheme.primaryLight
                          : const Color(0xFFD95800),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward,
                      size: 14,
                      color: oscuro
                          ? AppTheme.primaryLight
                          : const Color(0xFFD95800)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
