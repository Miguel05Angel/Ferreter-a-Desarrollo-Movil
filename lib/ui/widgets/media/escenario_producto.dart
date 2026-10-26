import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/producto.dart';
import '../../../providers/media_provider.dart';
import '../visual/producto_illustration.dart';
import '../visual/visor_3d.dart';
import 'galeria_fotos.dart';
import 'vista_360.dart';
import 'visor_modelo_3d.dart';

enum _Modo { modelo, giro, fotos, ilustracion }

/// Escenario superior del detalle del producto. Si el producto tiene
/// recursos reales en Google Drive muestra un selector con Modelo 3D,
/// Vista 360 y Fotos; si no, muestra la ilustracion 3D integrada.
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
  _Modo? _modo;

  Widget _ilustracion() => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Hero(
            tag: 'producto-${widget.producto.id}',
            flightShuttleBuilder: (_, __, ___, ____, _____) => FittedBox(
              child: ProductoEstatico(
                tipo: widget.producto.tipoVisual,
                colorHex: widget.colorHex,
                size: 100,
                sombra: true,
              ),
            ),
            child: Visor3D(
              tipo: widget.producto.tipoVisual,
              colorHex: widget.colorHex,
              size: 190,
              acento: widget.acento,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final providerMedia = context.watch<MediaProvider>();
    
    // ==========================================
    // ESPÍAS PARA LA CONSOLA (Mira VS Code)
    // ==========================================
    print('====================================');
    print('ESTADO DEL JSON: ${providerMedia.estado}');
    print('BUSCANDO CODIGO: "${widget.producto.codigo}"');
    
    final media = providerMedia.de(widget.producto.codigo);
    
    print('RESULTADO: ${media == null ? "NO ENCONTRADO (Mostrará ícono 3D)" : "¡ENCONTRADO! (Mostrará foto)"}');
    print('====================================');

    if (media == null) return _ilustracion();

    final modos = <(_Modo, String, IconData)>[
      if (media.tieneModelo) (_Modo.modelo, '3D', Icons.view_in_ar_outlined),
      if (media.tieneGiro) (_Modo.giro, '360', Icons.threesixty),
      if (media.tieneFotos) (_Modo.fotos, 'FOTOS', Icons.photo_library_outlined),
      (_Modo.ilustracion, 'DISENO', Icons.auto_awesome_outlined),
    ];
    final actual = modos.any((m) => m.$1 == _modo) ? _modo! : modos.first.$1;

    Widget contenido;
    switch (actual) {
      case _Modo.modelo:
        contenido = VisorModelo3D(
          key: ValueKey('m-${widget.producto.codigo}'),
          codigo: widget.producto.codigo,
          idModelo: media.modelo3d!,
        );
        break;
      case _Modo.giro:
        contenido = Vista360(
          key: ValueKey('g-${widget.producto.codigo}'),
          ids: media.giro360,
        );
        break;
      case _Modo.fotos:
        contenido = GaleriaFotos(
          key: ValueKey('f-${widget.producto.codigo}'),
          ids: media.fotos,
        );
        break;
      case _Modo.ilustracion:
        contenido = _ilustracion();
        break;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 34),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(key: ValueKey(actual), child: contenido),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final m in modos)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _modo = m.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: actual == m.$1
                            ? AppTheme.primary
                            : AppTheme.grafito.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: actual == m.$1
                              ? AppTheme.primary
                              : AppTheme.bordeOscuro,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(m.$3,
                              size: 15,
                              color: actual == m.$1
                                  ? AppTheme.grafito
                                  : AppTheme.hueso),
                          const SizedBox(width: 5),
                          Text(
                            m.$2,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w900,
                              color: actual == m.$1
                                  ? AppTheme.grafito
                                  : AppTheme.hueso,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}