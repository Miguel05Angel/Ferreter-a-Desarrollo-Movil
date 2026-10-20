import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/firestore_mappers.dart';
import '../data/models/venta.dart';
import '../services/firestore_service.dart';

class VentaProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService.instance;

  List<Venta> _ventas = [];
  StreamSubscription<List<Venta>>? _sub;
  bool cargando = true;
  String? error;

  VentaProvider() {
    _sub = _fs
        .escuchar<Venta>(FirestoreService.colVentas, Mapeadores.ventaDesde)
        .listen((lista) {
      _ventas = List.of(lista);
      cargando = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      cargando = false;
      error = e.toString();
      debugPrint('❌ Firestore [ventas]: $e');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Venta> get ventas =>
      List.unmodifiable(_ventas..sort((a, b) => b.fecha.compareTo(a.fecha)));

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

  static double calcularIgv(double subtotal) => subtotal * AppConstants.igv;

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
  }) {
    final subtotal = items.fold(0.0, (suma, i) => suma + i.subtotal);
    final igv = calcularIgv(subtotal);

    final venta = Venta(
      id: 'v-${DateTime.now().millisecondsSinceEpoch}',
      numero: siguienteNumero(comprobante),
      clienteNombre: clienteNombre,
      items: items,
      subtotal: subtotal,
      igv: igv,
      total: subtotal + igv,
      metodoPago: metodoPago,
      comprobante: comprobante,
      fecha: DateTime.now(),
    );

    _ventas.add(venta);
    notifyListeners();
    unawaited(_fs.crear(
        FirestoreService.colVentas, venta.id, Mapeadores.ventaAMapa(venta)));
    return venta;
  }
}
