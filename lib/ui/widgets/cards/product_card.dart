import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/categoria.dart';
import '../../../data/models/producto.dart';
import '../visual/producto_illustration.dart';
import '../visual/tilt_3d.dart';

/// Tarjeta de producto con ilustracion 3D y Hero al detalle.
class ProductCard extends StatelessWidget {
  final Producto producto;
  final Categoria categoria;
  final VoidCallback onTap;
  /// Recibe el punto de pantalla (la miniatura) desde donde sale la
  /// animacion de vuelo hacia el carrito.
  final void Function(Offset origen) onAgregar;

  const ProductCard({
    super.key,
    required this.producto,
    required this.categoria,
    required this.onTap,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final stockColor = producto.agotado
        ? Colors.red
        : (producto.stockBajo ? Colors.orange : Colors.green);

    return Tilt3D(
      anguloMax: 0.10,
      radioBorde: 16,
      builder: (context, t) => Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'producto-${producto.id}',
                  flightShuttleBuilder: (_, __, ___, ____, _____) => FittedBox(
                    child: ProductoEstatico(
                      tipo: producto.tipoVisual,
                      colorHex: producto.colorHex,
                      size: 100,
                      sombra: true,
                    ),
                  ),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoria.color.withOpacity(0.10),
                          categoria.color.withOpacity(0.22),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Paralaje: la pieza "sale" de la tarjeta al tocarla
                    child: Transform.translate(
                      offset: Offset(t.dx * -6, t.dy * -6),
                      child: Transform.scale(
                        scale: 1 + t.distance * 0.14,
                        child: ProductoIlustracion(
                          tipo: producto.tipoVisual,
                          colorHex: producto.colorHex,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${producto.marca}  |  ${producto.codigo}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stockColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        producto.agotado
                            ? 'Agotado'
                            : 'Stock: ${producto.stock} ${producto.unidad.toLowerCase()}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stockColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.soles(producto.precioVenta),
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BotonAgregar(
                    onTap: producto.agotado
                        ? null
                        : () {
                            Offset origen = Offset.zero;
                            final caja = context.findRenderObject();
                            if (caja is RenderBox && caja.hasSize) {
                              origen = caja.localToGlobal(
                                  Offset(48, caja.size.height / 2));
                            }
                            onAgregar(origen);
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _BotonAgregar extends StatefulWidget {
  final VoidCallback? onTap;
  const _BotonAgregar({this.onTap});

  @override
  State<_BotonAgregar> createState() => _BotonAgregarState();
}

class _BotonAgregarState extends State<_BotonAgregar> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onTap != null;
    return GestureDetector(
      onTapDown: habilitado ? (_) => setState(() => _presionado = true) : null,
      onTapUp: habilitado
          ? (_) {
              setState(() => _presionado = false);
              widget.onTap!();
            }
          : null,
      onTapCancel:
          habilitado ? () => setState(() => _presionado = false) : null,
      child: AnimatedScale(
        scale: _presionado ? 0.8 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: habilitado
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.add_shopping_cart,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
