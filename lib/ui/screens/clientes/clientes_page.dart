import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../providers/cliente_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/feedback/empty_state.dart';
import 'cliente_form_screen.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();
    final texto = _busquedaController.text.trim().toLowerCase();
    final filtrados = provider.clientes.where((c) {
      return texto.isEmpty ||
          c.nombre.toLowerCase().contains(texto) ||
          c.documento.contains(texto);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            AppRoutes.push(context, const ClienteFormScreen()),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nuevo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busquedaController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o documento...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filtrados.isEmpty
                ? EmptyState(
                    icono: Icons.people_alt_outlined,
                    titulo: texto.isEmpty ? 'Sin clientes' : 'Sin resultados',
                    mensaje: texto.isEmpty
                        ? 'Registra a los clientes habituales de la ferreteria.'
                        : 'No se encontraron clientes con ese criterio.',
                    textoBoton: texto.isEmpty ? 'Agregar cliente' : null,
                    onAccion: texto.isEmpty
                        ? () => AppRoutes.push(
                            context, const ClienteFormScreen())
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = filtrados[i];
                      return FadeSlide(
                        delay: Duration(milliseconds: i < 8 ? i * 60 : 0),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF546E7A)
                                  .withOpacity(0.12),
                              child: Text(
                                c.nombre.isNotEmpty
                                    ? c.nombre[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Color(0xFF546E7A),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(c.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${c.tipoDocumento}: ${c.documento}\n${c.telefono}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.credito)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32)
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text('Credito',
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFF2E7D32),
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20,
                                      color: Color(0xFFD32F2F)),
                                  onPressed: () {
                                    ConfirmDialog.mostrar(
                                      context,
                                      titulo: 'Eliminar cliente',
                                      mensaje:
                                          '¿Eliminar a ${c.nombre}?',
                                      textoConfirmar: 'Eliminar',
                                      onConfirmar: () {
                                        provider.eliminar(c.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Cliente eliminado'),
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
                            onTap: () => AppRoutes.push(
                              context,
                              ClienteFormScreen(cliente: c),
                            ),
                          ),
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
