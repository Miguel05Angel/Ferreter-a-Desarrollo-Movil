import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../productos/productos_page.dart';

/// Categorias: al tocar una se abre el catalogo con sus marcas disponibles.
class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();

    return Scaffold(
      appBar: const AppBarTaller(
          subtitulo: 'Clasificacion', title: Text('Categorias')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.categorias.length,
        itemBuilder: (context, i) {
          final cat = provider.categorias[i];
          final productos =
              provider.productos.where((p) => p.categoriaId == cat.id).toList();
          final marcas = productos.map((p) => p.marca).toSet().length;

          return FadeSlide(
            delay: Duration(milliseconds: i * 60),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cat.color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cat.icono, color: cat.color),
                ),
                title: Text(cat.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${productos.length} productos  ·  $marcas marcas'),
                trailing: Icon(Icons.chevron_right, color: cat.color),
                onTap: () => AppRoutes.push(
                    context, ProductosPage(categoriaInicial: cat.id)),
              ),
            ),
          );
        },
      ),
    );
  }
}
