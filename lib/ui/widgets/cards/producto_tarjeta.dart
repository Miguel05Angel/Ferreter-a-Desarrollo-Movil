import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/categoria.dart';
import '../../../data/models/producto.dart';
import '../media/producto_imagen.dart';
import '../visual/escala_grises.dart';
import '../visual/producto_illustration.dart';
import '../visual/tilt_3d.dart';

/// Tarjeta del catalogo en cuadricula. Si el producto esta agotado toda la
/// tarjeta pasa a escala de grises y aparece un triangulo de advertencia
/// animado sobre la imagen. La solicitud de reposicion NO esta aqui: solo
/// en la ficha del producto.
class ProductoTarjeta extends StatelessWidget {
  final Producto producto;
  final Categoria categoria;
  final VoidCallback onTap;
  final void Function(Offset origen) onAgregar;

  /// En modo cotizacion se puede agregar un producto sin stock (se avisa
  /// luego en rojo cuanto faltaria).
  final bool permitirAgotado;

  const ProductoTarjeta({
    super.key,
    required this.producto,
    required this.categoria,
    required this.onTap,
    required this.onAgregar,
    this.permitirAgotado = false,
  });

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    final agotado = producto.agotado;
    final stockColor = agotado
        ? Colors.red
        : (producto.critico ? Colors.orange.shade800 : Colors.green);

    return Tilt3D(
      anguloMax: 0.10,
      radioBorde: 16,
      builder: (context, t) => Stack(
        children: [
          EscalaGrises(
            activo: agotado,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'producto-${producto.id}',
                      flightShuttleBuilder: (_, __, ___, ____, _____) =>
                          FittedBox(
                        child: ProductoEstatico(
                          tipo: producto.tipoVisual,
                          colorHex: producto.colorHex,
                          size: 100,
                          sombra: true,
                        ),
                      ),
                      child: Container(
                        height: 108,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoria.color.withOpacity(0.10),
                              categoria.color.withOpacity(0.24),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Transform.translate(
                                offset: Offset(t.dx * -7, t.dy * -7),
                                child: Transform.scale(
                                  scale: 1 + t.distance * 0.12,
                                  child: ProductoImagen(
                                      producto: producto, size: 84),
                                ),
                              ),
                            ),
                            if (producto.critico)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade800,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'STOCK CRITICO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      letterSpacing: 0.6,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  height: 1.15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              producto.marca,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: stockColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    agotado
                                        ? 'Agotado'
                                        : (producto.critico
                                            ? 'Quedan ${producto.stock}'
                                            : 'Stock: ${producto.stock}'),
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: stockColor),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  producto.precioVerificado
                                      ? Icons.verified_outlined
                                      : Icons.help_outline,
                                  size: 14,
                                  color: producto.precioVerificado
                                      ? Colors.green.shade700
                                      : Colors.grey.shade500,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    Formatters.soles(producto.precioVenta),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: primario,
                                    ),
                                  ),
                                ),
                                Builder(
                                  builder: (ctx) => _BotonAgregar(
                                    onTap: (agotado && !permitirAgotado)
                                        ? null
                                        : () {
                                            Offset origen = Offset.zero;
                                            final caja = ctx.findRenderObject();
                                            if (caja is RenderBox &&
                                                caja.hasSize) {
                                              origen = caja.localToGlobal(
                                                  caja.size.center(Offset.zero));
                                            }
                                            onAgregar(origen);
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (agotado)
            const Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Center(child: TrianguloAdvertencia(size: 46)),
            ),
        ],
      ),
    );
  }
}

class _BotonAgregar extends StatelessWidget {
  final VoidCallback? onTap;
  const _BotonAgregar({this.onTap});

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    return Material(
      color: habilitado
          ? Theme.of(context).colorScheme.primary
          : Colors.grey.shade400,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
