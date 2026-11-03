import 'package:flutter/material.dart';

import '../core/utils/dinero.dart';

import '../core/constants/app_constants.dart';
import '../data/mock_data.dart';
import '../data/models/venta.dart';

class VentaProvider extends ChangeNotifier {
  final List<Venta> _ventas = List.of(MockData.ventas);

  List<Venta> get ventas =>
      List.unmodifiable(_ventas..sort((a, b) => b.fecha.compareTo(a.fecha)));

  /// Ventas que puede ver el usuario: el administrador ve todas, el
  /// vendedor solo las que registro el.
  List<Venta> visiblesPara({required bool esAdmin, required String usuarioId}) {
    final todas = ventas;
    return esAdmin
        ? todas
        : todas.where((v) => v.vendedorId == usuarioId).toList();
  }

  static double totalHoyEn(List<Venta> lista) {
    final hoy = DateTime.now();
    return lista
        .where((v) =>
            v.fecha.year == hoy.year &&
            v.fecha.month == hoy.month &&
            v.fecha.day == hoy.day)
        .fold(0.0, (suma, v) => suma + v.total);
  }

  int get totalVentas => _ventas.length;

  double get totalHoy {
    final hoy = DateTime.now();
    return _ventas
        .where((v) =>
            v.fecha.year == hoy.year &&
            v.fecha.month == hoy.month &&
            v.fecha.day == hoy.day)
        .fold(0.0, (suma, v) => suma + v.total);
  }

  static double calcularIgv(double subtotal) =>
      Dinero.r2(subtotal * AppConstants.igv);

  String siguienteNumero(String comprobante) {
    final prefijo = comprobante == 'Factura' ? 'F' : 'B';
    final correlativo =
        _ventas.where((v) => v.comprobante == comprobante).length + 1;
    return '${prefijo}001-${correlativo.toString().padLeft(4, '0')}';
  }

  Venta registrar({
    required String clienteNombre,
    required List<ItemVenta> items,
    required String metodoPago,
    required String comprobante,
    String vendedorId = '',
    String vendedor = '',
    double redondeo = 0,
  }) {
    final subtotal =
        Dinero.r2(items.fold(0.0, (suma, i) => suma + i.subtotal));
    final igv = calcularIgv(subtotal);

    final venta = Venta(
      id: 'v-${DateTime.now().millisecondsSinceEpoch}',
      numero: siguienteNumero(comprobante),
      clienteNombre: clienteNombre,
      items: items,
      subtotal: subtotal,
      igv: igv,
      total: Dinero.r2(subtotal + igv),
      metodoPago: metodoPago,
      comprobante: comprobante,
      fecha: DateTime.now(),
      vendedorId: vendedorId,
      vendedor: vendedor,
      redondeo: redondeo,
    );

    _ventas.add(venta);
    notifyListeners();
    return venta;
  }
}
