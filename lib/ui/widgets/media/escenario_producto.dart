import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/producto.dart';
import '../../../providers/media_provider.dart';
import 'galeria_fotos.dart';

/// Escenario superior del detalle del producto.
/// Muestra la galería de fotos reales. Si el producto no cuenta con 
/// fotos registradas, muestra un aviso de "FALTA IMAGEN".
class EscenarioProducto extends StatefulWidget {
  final Producto producto;
  final int colorHex;
  final Color acento;

  const EscenarioProducto({
    super.key,
    required this.producto,
    required this.colorHex,
    required this.acento,
  });

  @override
  State<EscenarioProducto> createState() => _EscenarioProductoState();
}

class _EscenarioProductoState extends State<EscenarioProducto> {
  
  // Widget de respaldo cuando no hay fotos reales.
  Widget _faltaImagen() => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.grafito.withValues(alpha: 0.5),
          border: Border.all(
            color: AppTheme.bordeOscuro,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: AppTheme.hueso.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'FALTA IMAGEN',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.hueso.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final providerMedia = context.watch<MediaProvider>();
    final media = providerMedia.de(widget.producto.codigo);

    // Si no hay media o no hay fotos, mostramos el aviso.
    if (media == null || !media.tieneFotos) {
      return _faltaImagen();
    }

    // Vista principal: Galería de fotos a pantalla completa.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey('f-${widget.producto.codigo}'),
        child: GaleriaFotos(
          ids: media.fotos,
          referencial: media.fotoReferencial,
        ),
      ),
    );
  }
}