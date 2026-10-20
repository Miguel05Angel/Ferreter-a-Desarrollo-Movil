import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/firestore_mappers.dart';
import '../data/models/cotizacion.dart';
import '../data/models/venta.dart';
import '../services/firestore_service.dart';

class CotizacionProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService.instance;

  List<Cotizacion> _cotizaciones = [];
  StreamSubscription<List<Cotizacion>>? _sub;
  bool cargando = true;
  String? error;

  CotizacionProvider() {
    _sub = _fs
        .escuchar<Cotizacion>(
            FirestoreService.colCotizaciones, Mapeadores.cotizacionDesde)
        .listen((lista) {
      _cotizaciones = List.of(lista);
      cargando = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      cargando = false;
      error = e.toString();
      debugPrint('❌ Firestore [cotizaciones]: $e');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Cotizacion> get cotizaciones => List.unmodifiable(
      _cotizaciones..sort((a, b) => b.fecha.compareTo(a.fecha)));

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
    unawaited(_fs.crear(FirestoreService.colCotizaciones, cotizacion.id,
        Mapeadores.cotizacionAMapa(cotizacion)));
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
      unawaited(_fs.guardar(
          FirestoreService.colCotizaciones, id, {'estado': estado}));
    }
  }
}
