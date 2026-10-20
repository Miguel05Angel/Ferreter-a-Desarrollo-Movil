import 'venta.dart';

class Cotizacion {
  final String id;
  final String clienteNombre;
  final List<ItemVenta> items;
  final double subtotal;
  final double igv;
  final double total;
  final int validezDias;
  final String estado;
  final DateTime fecha;

  const Cotizacion({
    required this.id,
    required this.clienteNombre,
    required this.items,
    required this.subtotal,
    required this.igv,
    required this.total,
    required this.validezDias,
    required this.estado,
    required this.fecha,
  });
}
