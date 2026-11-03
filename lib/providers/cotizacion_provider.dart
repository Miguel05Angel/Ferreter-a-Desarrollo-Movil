import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/mock_data.dart';
import '../data/models/cotizacion.dart';
import '../data/models/venta.dart';

class CotizacionProvider extends ChangeNotifier {
  final List<Cotizacion> _cotizaciones = List.of(MockData.cotizaciones);

  List<Cotizacion> get cotizaciones =>
      List.unmodifiable(_cotizaciones..sort((a, b) => b.fecha.compareTo(a.fecha)));

  int get totalCotizaciones => _cotizaciones.length;

  Cotizacion? buscarPorId(String id) {
    for (final c in _cotizaciones) {
      if (c.id == id) return c;
    }
    return null;
  }

  Cotizacion registrar({
    required String clienteNombre,
    required List<ItemVenta> items,
    required int validezDias,
    String clienteId = '',
    String tipoDocumento = '',
    String documento = '',
  }) {
    final subtotal = items.fold(0.0, (suma, i) => suma + i.subtotal);
    final igv = subtotal * AppConstants.igv;

    final cotizacion = Cotizacion(
      id: 'ct-${DateTime.now().millisecondsSinceEpoch}',
      clienteNombre: clienteNombre,
      items: items,
      subtotal: subtotal,
      igv: igv,
      total: subtotal + igv,
      validezDias: validezDias,
      estado: 'Pendiente',
      fecha: DateTime.now(),
      clienteId: clienteId,
      tipoDocumento: tipoDocumento,
      documento: documento,
    );

    _cotizaciones.add(cotizacion);
    notifyListeners();
    return cotizacion;
  }

  /// Modifica una cotizacion guardada (cliente, productos y validez).
  /// Conserva su id y su fecha de emision original.
  Cotizacion? actualizar({
    required String id,
    required String clienteNombre,
    required List<ItemVenta> items,
    required int validezDias,
    String clienteId = '',
    String tipoDocumento = '',
    String documento = '',
  }) {
    final index = _cotizaciones.indexWhere((c) => c.id == id);
    if (index < 0) return null;
    final subtotal = items.fold(0.0, (suma, i) => suma + i.subtotal);
    final igv = subtotal * AppConstants.igv;
    final nueva = _cotizaciones[index].copyWith(
      clienteNombre: clienteNombre,
      items: items,
      subtotal: subtotal,
      igv: igv,
      total: subtotal + igv,
      validezDias: validezDias,
      clienteId: clienteId,
      tipoDocumento: tipoDocumento,
      documento: documento,
    );
    _cotizaciones[index] = nueva;
    notifyListeners();
    return nueva;
  }

  void cambiarEstado(String id, String estado) {
    final index = _cotizaciones.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _cotizaciones[index] = _cotizaciones[index].copyWith(estado: estado);
      notifyListeners();
    }
  }

  /// Elimina una cotizacion y sus datos asociados.
  void eliminar(String id) => eliminarVarias([id]);

  /// Elimina varias cotizaciones a la vez (seleccion multiple).
  void eliminarVarias(Iterable<String> ids) {
    final lista = ids.toSet();
    final antes = _cotizaciones.length;
    _cotizaciones.removeWhere((c) => lista.contains(c.id));
    if (_cotizaciones.length != antes) notifyListeners();
  }
}
