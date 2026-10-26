import '../../core/constants/app_constants.dart';
import '../../core/utils/dinero.dart';

/// Etapas del proceso de compra a un proveedor.
enum EstadoCompra { solicitada, cotizada, ordenada }

extension EstadoCompraTexto on EstadoCompra {
  String get texto {
    switch (this) {
      case EstadoCompra.solicitada:
        return 'Solicitada';
      case EstadoCompra.cotizada:
        return 'Cotizada';
      case EstadoCompra.ordenada:
        return 'Orden emitida';
    }
  }
}

/// Respuesta del proveedor a la solicitud de cotizacion.
class CotizacionProveedor {
  final double precioUnitario;
  final bool incluyeIgv;
  final double envio;
  final DateTime validaHasta;
  final int plazoEntregaDias;
  final String condicionesPago;
  final String observaciones;
  final DateTime fechaRegistro;

  const CotizacionProveedor({
    required this.precioUnitario,
    required this.incluyeIgv,
    required this.envio,
    required this.validaHasta,
    required this.plazoEntregaDias,
    required this.condicionesPago,
    required this.observaciones,
    required this.fechaRegistro,
  });

  bool get vigente {
    final hoy = DateTime.now();
    final fin =
        DateTime(validaHasta.year, validaHasta.month, validaHasta.day, 23, 59);
    return !fin.isBefore(hoy);
  }

  double _totalProductos(int cantidad) => incluyeIgv
      ? Dinero.r2(precioUnitario * cantidad)
      : Dinero.r2(precioUnitario * cantidad * (1 + AppConstants.igv));

  double subtotal(int cantidad) => incluyeIgv
      ? Dinero.r2(_totalProductos(cantidad) / (1 + AppConstants.igv))
      : Dinero.r2(precioUnitario * cantidad);

  double igv(int cantidad) =>
      Dinero.r2(_totalProductos(cantidad) - subtotal(cantidad));

  double total(int cantidad) => Dinero.r2(_totalProductos(cantidad) + envio);
}

/// Solicitud de cotizacion (RFQ): documento neutro con producto y cantidad.
/// No lleva precios; el proveedor responde con su cotizacion y recien despues
/// se genera la orden de compra.
class SolicitudCotizacion {
  final String id;
  final String numero;
  final String productoId;
  final String codigo;
  final String descripcion;
  final String unidad;
  final int cantidad;

  final String proveedorId;
  final String proveedorNombre;
  final String proveedorRuc;
  final String proveedorTelefono;
  final String proveedorDireccion;

  final DateTime fecha;
  final DateTime respuestaAntes;
  final String solicitante;

  /// Ultimo costo registrado: solo informativo y opcional en el documento.
  final double? precioReferencial;
  final bool incluirReferencia;

  EstadoCompra estado;
  CotizacionProveedor? cotizacion;
  String? ordenNumero;
  DateTime? fechaOrden;

  SolicitudCotizacion({
    required this.id,
    required this.numero,
    required this.productoId,
    required this.codigo,
    required this.descripcion,
    required this.unidad,
    required this.cantidad,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.proveedorRuc,
    required this.proveedorTelefono,
    required this.proveedorDireccion,
    required this.fecha,
    required this.respuestaAntes,
    required this.solicitante,
    this.precioReferencial,
    this.incluirReferencia = false,
    this.estado = EstadoCompra.solicitada,
    this.cotizacion,
    this.ordenNumero,
    this.fechaOrden,
  });
}
