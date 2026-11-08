import 'package:flutter/material.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../data/models/cliente.dart';
import '../../../data/models/venta.dart';

import '../../../providers/cliente_provider.dart';
import '../../../providers/venta_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/comprobante/comprobante_acciones.dart';

/// Muestra el comprobante electronico de una venta.
class VentaDetalleScreen extends StatelessWidget {
  final String ventaId;
  const VentaDetalleScreen({super.key, required this.ventaId});

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<VentaProvider>();
    final clientes = context.watch<ClienteProvider>();

    Venta? venta;
    for (final v in ventas.ventas) {
      if (v.id == ventaId) {
        venta = v;
        break;
      }
    }

    if (venta == null) {
      return const Scaffold(
        appBar:
            AppBarTaller(subtitulo: 'Documento', title: Text('Comprobante')),
        body: Center(child: Text('Venta no encontrada.')),
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
      appBar: AppBarTaller(title: Text('${venta.comprobante} ${venta.numero}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Estado de la venta: ${venta.estado}'),
          const SizedBox(height: 12),
          FadeSlide(
            inicio: const Offset(0, 0.25),
            child: ComprobanteConAcciones(
              venta: venta,
              cliente: cliente,
              vendedor: venta.vendedor.isEmpty ? 'Caja 01' : venta.vendedor,
            ),
          ),
        ],
      ),
    );
  }
}
