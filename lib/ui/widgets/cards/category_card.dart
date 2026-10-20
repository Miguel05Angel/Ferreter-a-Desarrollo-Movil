import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/categoria.dart';
import '../visual/tilt_3d.dart';

/// Ficha de categoria con inclinacion 3D al tocarla.
class CategoryCard extends StatelessWidget {
  final Categoria categoria;
  final int cantidad;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.categoria,
    required this.cantidad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Tilt3D(
      anguloMax: 0.16,
      radioBorde: 14,
      builder: (context, t) => Material(
        color: Theme.of(context).cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 124,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(height: 4, color: categoria.color),
                ),
                Positioned(
                  right: -10,
                  bottom: -14,
                  child: Transform.translate(
                    offset: Offset(t.dx * -6, t.dy * -6),
                    child: Icon(categoria.icono,
                        size: 84, color: categoria.color.withOpacity(0.10)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: categoria.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(categoria.icono,
                            color: categoria.color, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cantidad.toString().padLeft(2, '0')} PROD.',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              letterSpacing: 1,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
