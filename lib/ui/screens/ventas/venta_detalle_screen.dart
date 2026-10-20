import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/cliente.dart';
import '../../../data/models/venta.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/venta_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/comprobante/comprobante_view.dart';

/// Muestra el comprobante electronico de una venta.
class VentaDetalleScreen extends StatelessWidget {
  final String ventaId;
  const VentaDetalleScreen({super.key, required this.ventaId});

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<VentaProvider>();
    final clientes = context.watch<ClienteProvider>();
    final usuario = context.watch<AuthProvider>().usuarioActual;

    Venta? venta;
    for (final v in ventas.ventas) {
      if (v.id == ventaId) {
        venta = v;
        break;
      }
    }

    if (venta == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprobante')),
        body: const Center(child: Text('Venta no encontrada.')),
      );
    }

    Cliente? cliente;
    for (final c in clientes.clientes) {
      if (c.nombre == venta.clienteNombre) {
        cliente = c;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('${venta.comprobante} ${venta.numero}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          FadeSlide(
            inicio: const Offset(0, 0.25),
            child: ComprobanteView(
              venta: venta,
              cliente: cliente,
              vendedor: usuario?.nombre.split(' ').first ?? 'Caja 01',
            ),
          ),
        ],
      ),
    );
  }
}
