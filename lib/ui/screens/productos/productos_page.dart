import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/producto.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/carrito/carrito_flotante.dart';
import '../../widgets/visual/tilt_3d.dart';
import 'producto_detalle_screen.dart';
import 'producto_form_screen.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _busquedaController = TextEditingController();
  String _filtroCategoria = 'todas';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(List<Producto> productos) {
    final texto = _busquedaController.text.trim().toLowerCase();
    return productos.where((p) {
      final coincideCategoria =
          _filtroCategoria == 'todas' || p.categoriaId == _filtroCategoria;
      final coincideTexto = texto.isEmpty ||
          p.nombre.toLowerCase().contains(texto) ||
          p.codigo.toLowerCase().contains(texto) ||
          p.marca.toLowerCase().contains(texto);
      return coincideCategoria && coincideTexto;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final filtrados = _filtrar(provider.productos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: 'Agregar producto',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                AppRoutes.push(context, const ProductoFormScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRoutes.push(context, const ProductoFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busquedaController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, codigo o marca...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filtro de categorias
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _ChipFiltro(
                  texto: 'Todas',
                  activo: _filtroCategoria == 'todas',
                  onTap: () => setState(() => _filtroCategoria = 'todas'),
                ),
                ...provider.categorias.map(
                  (c) => _ChipFiltro(
                    texto: c.nombre,
                    activo: _filtroCategoria == c.id,
                    color: c.color,
                    onTap: () => setState(() => _filtroCategoria = c.id),
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: filtrados.isEmpty
                ? EmptyState(
                    icono: Icons.search_off,
                    titulo: 'Sin resultados',
                    mensaje: 'No se encontraron productos que coincidan '
                        'con la busqueda o el filtro seleccionado.',
                    textoBoton: 'Agregar producto',
                    onAccion: () =>
                        AppRoutes.push(context, const ProductoFormScreen()),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = filtrados[i];
                      return Entrada3D(
                        delay: Duration(milliseconds: i < 8 ? i * 80 : 0),
                        child: ProductCard(
                          producto: p,
                          categoria: provider.categoriaDe(p.categoriaId),
                          onTap: () => AppRoutes.push(
                            context,
                            ProductoDetalleScreen(productoId: p.id),
                          ),
                          onAgregar: (origen) {
                            final error = context
                                .read<CarritoProvider>()
                                .agregar(p, 1);
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: const Color(0xFFD32F2F),
                                ),
                              );
                              return;
                            }
                            VueloAlCarrito.lanzar(
                              context,
                              tipo: p.tipoVisual,
                              colorHex: p.colorHex,
                              desde: origen,
                              tam: 92,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color? color;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.texto,
    required this.activo,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorBase = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: activo ? colorBase : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activo ? colorBase : Colors.grey.shade400,
            ),
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                color: activo ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
