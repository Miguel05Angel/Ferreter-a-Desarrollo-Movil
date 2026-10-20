import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/empty_state.dart';
import 'cotizacion_form_screen.dart';

class CotizacionesPage extends StatelessWidget {
  const CotizacionesPage({super.key});

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Aceptada':
        return const Color(0xFF2E7D32);
      case 'Rechazada':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFFF9A825);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CotizacionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cotizaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            AppRoutes.push(context, const CotizacionFormScreen()),
        icon: const Icon(Icons.request_quote_outlined),
        label: const Text('Nueva'),
      ),
      body: provider.cotizaciones.isEmpty
          ? const EmptyState(
              icono: Icons.request_quote_outlined,
              titulo: 'Sin cotizaciones',
              mensaje: 'Crea cotizaciones para tus clientes con precios '
                  'especiales y validez limitada.',
              textoBoton: 'Crear cotizacion',
              onAccion: null,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: provider.cotizaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = provider.cotizaciones[i];
                final colorEstado = _colorEstado(c.estado);
                return FadeSlide(
                  delay: Duration(milliseconds: i < 8 ? i * 60 : 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colorEstado
                                    .withOpacity(0.12),
                                child: Icon(Icons.request_quote,
                                    color: colorEstado),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.clienteNombre,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 14.5)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${Formatters.fechaCorta(c.fecha)}  |  Validez: ${c.validezDias} dias  |  ${c.items.length} productos',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      colorEstado.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  c.estado,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: colorEstado),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 22),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Formatters.soles(c.total),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (c.estado == 'Pendiente')
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => provider
                                          .cambiarEstado(
                                              c.id, 'Aceptada'),
                                      child: const Text('Aceptar'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(
                                                  0xFFD32F2F)),
                                      onPressed: () => provider
                                          .cambiarEstado(
                                              c.id, 'Rechazada'),
                                      child:
                                          const Text('Rechazar'),
                                    ),
                                  ],
                                ),
                            ],
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
