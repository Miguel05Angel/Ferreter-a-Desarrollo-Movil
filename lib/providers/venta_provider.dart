import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import '../core/utils/dinero.dart';
import '../core/constants/app_constants.dart';
import '../data/firestore_mappers.dart';
import '../data/models/usuario.dart';
import '../data/models/venta.dart';
import '../services/firebase_ferreteria.dart';
import '../services/firestore_service.dart';

class VentaProvider extends ChangeNotifier {
  final _servicio = FirestoreService.instance;
  List<Venta> _ventas = [];
  StreamSubscription<QuerySnapshot<Mapa>>? _suscripcion;
  String? _uid;
  bool error = false;

  List<Venta> get ventas => List.unmodifiable(_ventas);

  void actualizarSesion(Usuario? usuario) {
    if (_uid == usuario?.id) return;
    _uid = usuario?.id;
    _suscripcion?.cancel();
    _ventas = [];
    error = false;
    if (usuario == null) return;

    final Query<Mapa> consulta = usuario.rol == 'Administrador'
        ? _servicio.ventas
        : _servicio.ventas.where('vendedorId', isEqualTo: usuario.id);
    _suscripcion =
        consulta.snapshots(includeMetadataChanges: true).listen((resultado) {
      if (resultado.metadata.isFromCache) return;
      _ventas = resultado.docs
          .map((doc) => Mapeadores.ventaDesde(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      error = false;
      notifyListeners();
    }, onError: (Object _) {
      error = true;
      notifyListeners();
    });
  }

  List<Venta> visiblesPara(
          {required bool esAdmin, required String usuarioId}) =>
      esAdmin
          ? ventas
          : ventas.where((v) => v.vendedorId == usuarioId).toList();

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
  double get totalHoy => totalHoyEn(_ventas);

  static double calcularIgv(double subtotal) =>
      Dinero.r2(subtotal * AppConstants.igv);

  String nuevoIdVenta() => _servicio.ventas.doc().id;

  Future<({Venta venta, List<Mapa> cambios})> registrar({
    required String id,
    required String clienteNombre,
    required List<ItemVenta> items,
    required String metodoPago,
    required String comprobante,
  }) async {
    final resultado = await FirebaseFerreteria.funciones
        .httpsCallable('registrarVenta')
        .call({
      'id': id,
      'clienteNombre': clienteNombre,
      'items': [
        for (final item in items)
          {
            'productoId': item.productoId,
            'cantidad': item.cantidad,
            'precioUnitario': item.precioUnitario,
          },
      ],
      'metodoPago': metodoPago,
      'comprobante': comprobante,
    });
    final datos = Mapa.from(resultado.data as Map);
    final venta = Mapa.from(datos['venta'] as Map);
    venta['fecha'] =
        Timestamp.fromMillisecondsSinceEpoch(venta['fecha'] as int);
    final cambios = (datos['cambios'] as List)
        .map((cambio) => Mapa.from(cambio as Map))
        .toList();
    return (venta: Mapeadores.ventaDesde(id, venta), cambios: cambios);
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
