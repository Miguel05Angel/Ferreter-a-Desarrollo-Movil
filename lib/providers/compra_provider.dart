import 'package:flutter/foundation.dart';

import '../data/models/solicitud_cotizacion.dart';

/// Solicitudes de cotizacion y ordenes de compra a proveedores.
class CompraProvider extends ChangeNotifier {
  final List<SolicitudCotizacion> _solicitudes = [];
  int _contadorRfq = 0;
  int _contadorOc = 0;

  List<SolicitudCotizacion> get solicitudes {
    final l = List<SolicitudCotizacion>.of(_solicitudes);
    l.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(l);
  }

  int contar(EstadoCompra e) =>
      _solicitudes.where((s) => s.estado == e).length;

  /// Solicitudes que esperan accion (sin cotizar o con cotizacion lista).
  int get pendientes => _solicitudes
      .where((s) => s.estado != EstadoCompra.ordenada)
      .length;

  SolicitudCotizacion? buscar(String id) {
    for (final s in _solicitudes) {
      if (s.id == id) return s;
    }
    return null;
  }

  SolicitudCotizacion crear({
    required String productoId,
    required String codigo,
    required String descripcion,
    required String unidad,
    required int cantidad,
    required String proveedorId,
    required String proveedorNombre,
    required String proveedorRuc,
    required String proveedorTelefono,
    required String proveedorDireccion,
    required DateTime respuestaAntes,
    required String solicitante,
    double? precioReferencial,
    bool incluirReferencia = false,
  }) {
    _contadorRfq++;
    final ahora = DateTime.now();
    final s = SolicitudCotizacion(
      id: 'rfq-${ahora.millisecondsSinceEpoch}',
      numero: 'RFQ-${ahora.year}-${_contadorRfq.toString().padLeft(4, '0')}',
      productoId: productoId,
      codigo: codigo,
      descripcion: descripcion,
      unidad: unidad,
      cantidad: cantidad,
      proveedorId: proveedorId,
      proveedorNombre: proveedorNombre,
      proveedorRuc: proveedorRuc,
      proveedorTelefono: proveedorTelefono,
      proveedorDireccion: proveedorDireccion,
      fecha: ahora,
      respuestaAntes: respuestaAntes,
      solicitante: solicitante,
      precioReferencial: precioReferencial,
      incluirReferencia: incluirReferencia,
    );
    _solicitudes.add(s);
    notifyListeners();
    return s;
  }

  void registrarCotizacion(String id, CotizacionProveedor cotizacion) {
    final s = buscar(id);
    if (s == null || s.estado == EstadoCompra.ordenada) return;
    s.cotizacion = cotizacion;
    s.estado = EstadoCompra.cotizada;
    notifyListeners();
  }

  /// Emite la orden de compra con los precios de la cotizacion registrada.
  String? generarOrden(String id) {
    final s = buscar(id);
    if (s == null || s.cotizacion == null) return null;
    if (s.ordenNumero != null) return s.ordenNumero;
    _contadorOc++;
    final ahora = DateTime.now();
    s.ordenNumero = 'OC-${ahora.year}-${_contadorOc.toString().padLeft(4, '0')}';
    s.fechaOrden = ahora;
    s.estado = EstadoCompra.ordenada;
    notifyListeners();
    return s.ordenNumero;
  }
}
