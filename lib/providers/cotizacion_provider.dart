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

  Cotizacion registrar({
    required String clienteNombre,
    required List<ItemVenta> items,
    required int validezDias,
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
    );

    _cotizaciones.add(cotizacion);
    notifyListeners();
    return cotizacion;
  }

  void cambiarEstado(String id, String estado) {
    final index = _cotizaciones.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final c = _cotizaciones[index];
      _cotizaciones[index] = Cotizacion(
        id: c.id,
        clienteNombre: c.clienteNombre,
        items: c.items,
        subtotal: c.subtotal,
        igv: c.igv,
        total: c.total,
        validezDias: c.validezDias,
        estado: estado,
        fecha: c.fecha,
      );
      notifyListeners();
    }
  }
}
