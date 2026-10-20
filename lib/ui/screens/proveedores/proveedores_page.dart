import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../providers/proveedor_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/feedback/empty_state.dart';
import 'proveedor_form_screen.dart';

class ProveedoresPage extends StatelessWidget {
  const ProveedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProveedorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            AppRoutes.push(context, const ProveedorFormScreen()),
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Nuevo'),
      ),
      body: provider.proveedores.isEmpty
          ? const EmptyState(
              icono: Icons.local_shipping_outlined,
              titulo: 'Sin proveedores',
              mensaje: 'Registra los proveedores de los productos '
                  'que compra la ferreteria.',
              textoBoton: 'Agregar proveedor',
              onAccion: null,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: provider.proveedores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = provider.proveedores[i];
                return FadeSlide(
                  delay: Duration(milliseconds: i < 8 ? i * 60 : 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF0277BD)
                                    .withOpacity(0.12),
                                child: const Icon(Icons.local_shipping,
                                    color: Color(0xFF0277BD)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.nombre,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text('RUC: ${p.ruc}',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Color(0xFFD32F2F)),
                                onPressed: () {
                                  ConfirmDialog.mostrar(
                                    context,
                                    titulo: 'Eliminar proveedor',
                                    mensaje: '¿Eliminar a ${p.nombre}?',
                                    textoConfirmar: 'Eliminar',
                                    onConfirmar: () {
                                      provider.eliminar(p.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Proveedor eliminado'),
                                          backgroundColor:
                                              Color(0xFF2E7D32),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 15, color: Colors.grey.shade600),
                              const SizedBox(width: 5),
                              Text(p.telefono,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade700)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 15,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(p.direccion,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              color:
                                                  Colors.grey.shade700)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (p.productos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: p.productos
                                  .map(
                                    (prod) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0277BD)
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(prod,
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF0277BD))),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => AppRoutes.push(
                                context,
                                ProveedorFormScreen(proveedor: p),
                              ),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16),
                              label: const Text('Editar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
