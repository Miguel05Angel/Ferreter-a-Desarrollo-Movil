import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../productos/producto_detalle_screen.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.categorias.length,
        itemBuilder: (context, i) {
          final cat = provider.categorias[i];
          final productos =
              provider.productos.where((p) => p.categoriaId == cat.id).toList();

          return FadeSlide(
            delay: Duration(milliseconds: i * 60),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cat.color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icono, color: cat.color),
                  ),
                  title: Text(cat.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${productos.length} productos'),
                  children: productos
                      .map(
                        (p) => ListTile(
                          dense: true,
                          title: Text(p.nombre),
                          subtitle: Text(
                              '${p.marca}  |  Stock: ${p.stock}'),
                          trailing: Text('S/ ${p.precioVenta}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          onTap: () => AppRoutes.push(
                            context,
                            ProductoDetalleScreen(productoId: p.id),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
