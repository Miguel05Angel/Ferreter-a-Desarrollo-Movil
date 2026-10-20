class ItemVenta {
  final String productoId;
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  const ItemVenta({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class Venta {
  final String id;
  final String numero;
  final String clienteNombre;
  final List<ItemVenta> items;
  final double subtotal;
  final double igv;
  final double total;
  final String metodoPago;
  final String comprobante;
  final DateTime fecha;

  const Venta({
    required this.id,
    required this.numero,
    required this.clienteNombre,
    required this.items,
    required this.subtotal,
    required this.igv,
    required this.total,
    required this.metodoPago,
    required this.comprobante,
    required this.fecha,
  });
}
