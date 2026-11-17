import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/dinero.dart';
import '../core/constants/app_constants.dart';
import '../data/firestore_mappers.dart';
import '../data/models/usuario.dart';
import '../data/models/venta.dart';
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

  /// Registra una venta directamente en Firestore usando una transacción.
  Future<({Venta venta, List<Mapa> cambios})> registrar({
    required String id,
    required String clienteNombre,
    required List<ItemVenta> items,
    required String metodoPago,
    required String comprobante,
    required String vendedorId,
    required String vendedorNombre,
  }) async {
    final db = _servicio.db;
    final ventaRef = _servicio.ventas.doc(id);
    final prefijo = comprobante == 'Factura' ? 'F001-' : 'B001-';
    final contadorRef = db.collection('_meta').doc('ventas-${prefijo.substring(0, 4)}');
    final fecha = DateTime.now();

    return await db.runTransaction((transaction) async {
      final registrada = await transaction.get(ventaRef);
      if (registrada.exists) {
        final ventaData = registrada.data()!;
        return (
          venta: Mapeadores.ventaDesde(id, ventaData),
          cambios: <Mapa>[],
        );
      }

      final correlativoDoc = await transaction.get(contadorRef);
      int ultimo = 0;
      if (correlativoDoc.exists) {
        ultimo = correlativoDoc.get('ultimo') ?? 0;
      }
      final siguienteNumero = ultimo + 1;

      final referencias = items
          .map((item) => _servicio.productos.doc(item.productoId))
          .toList();
      final productosSnapshots = await Future.wait(
        referencias.map((ref) => transaction.get(ref)),
      );

      final cambios = <Mapa>[];
      int subtotalCentavos = 0;
      final detalle = <Mapa>[];

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final productoDoc = productosSnapshots[i];

        if (!productoDoc.exists) {
          throw Exception('El producto ${item.productoId} no existe.');
        }

        final stock = productoDoc.get('stock') as int? ?? 0;
        final precio = productoDoc.get('precioVenta') as num? ??
            productoDoc.get('precio') as num?;

        if (stock < item.cantidad) {
          throw Exception(
              'Stock insuficiente para ${productoDoc.get('nombre')}. Disponible: $stock');
        }
        if (precio == null || precio.toDouble() != item.precioUnitario) {
          throw Exception(
              'El precio de ${productoDoc.get('nombre')} ha cambiado. Actualiza el carrito.');
        }

        final nuevoStock = stock - item.cantidad;
        cambios.add({
          'id': productoDoc.id,
          'antes': stock,
          'despues': nuevoStock,
        });
        subtotalCentavos += (item.cantidad * item.precioUnitario * 100).round();

        detalle.add({
          'productoId': productoDoc.id,
          'nombre': productoDoc.get('nombre') ?? '',
          'cantidad': item.cantidad,
          'precioUnitario': item.precioUnitario,
        });
      }

      final igvCentavos = (subtotalCentavos * 0.18).round();
      final totalCentavos = subtotalCentavos + igvCentavos;

      final ventaData = {
        'numero': '$prefijo${siguienteNumero.toString().padLeft(4, '0')}',
        'clienteNombre': clienteNombre.trim(),
        'items': detalle,
        'subtotal': subtotalCentavos / 100,
        'igv': igvCentavos / 100,
        'total': totalCentavos / 100,
        'redondeo': metodoPago == 'Efectivo' ? (totalCentavos % 10) / 100 : 0,
        'metodoPago': metodoPago,
        'comprobante': comprobante,
        'estado': 'Completada',
        'fecha': Timestamp.fromDate(fecha),
        'vendedorId': vendedorId,
        'vendedor': vendedorNombre,
      };

      for (var i = 0; i < cambios.length; i++) {
        transaction.update(referencias[i], {'stock': cambios[i]['despues']});
      }
      transaction.set(contadorRef, {'ultimo': siguienteNumero});
      transaction.set(ventaRef, ventaData);

      return (
        venta: Mapeadores.ventaDesde(id, ventaData),
        cambios: cambios,
      );
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}