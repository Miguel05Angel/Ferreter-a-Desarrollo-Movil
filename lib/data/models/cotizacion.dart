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

  /// Datos del cliente al momento de cotizar (vacios en cotizaciones
  /// antiguas: en ese caso se busca el cliente por su nombre).
  final String clienteId;
  final String tipoDocumento; // DNI o RUC
  final String documento;

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
    this.clienteId = '',
    this.tipoDocumento = '',
    this.documento = '',
  });

  /// Fecha en que vence la cotizacion.
  DateTime get fechaVencimiento => fecha.add(Duration(days: validezDias));

  bool get vencida =>
      estado == 'Pendiente' && DateTime.now().isAfter(fechaVencimiento);

  Cotizacion copyWith({
    String? clienteNombre,
    List<ItemVenta>? items,
    double? subtotal,
    double? igv,
    double? total,
    int? validezDias,
    String? estado,
    DateTime? fecha,
    String? clienteId,
    String? tipoDocumento,
    String? documento,
  }) {
    return Cotizacion(
      id: id,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      igv: igv ?? this.igv,
      total: total ?? this.total,
      validezDias: validezDias ?? this.validezDias,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      clienteId: clienteId ?? this.clienteId,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
    );
  }
}
