import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/firestore_mappers.dart';
import '../data/mock_data.dart';
import '../data/models/categoria.dart';
import '../data/models/producto.dart';
import '../data/models/usuario.dart';
import '../services/firestore_service.dart';

class ProductoProvider extends ChangeNotifier {
  final _servicio = FirestoreService.instance;
  List<Producto> _productos = [];
  StreamSubscription<QuerySnapshot<Mapa>>? _suscripcion;
  String? _uid;
  bool cargando = false;
  bool error = false;

  List<Producto> get productos => List.unmodifiable(_productos);
  List<Categoria> get categorias => List.unmodifiable(MockData.categorias);
  int get totalProductos => _productos.length;

  int get productosStockBajo =>
      _productos.where((p) => p.stock <= AppConstants.stockBajo).length;

  double get valorInventario =>
      _productos.fold(0.0, (suma, p) => suma + p.precioVenta * p.stock);

  void actualizarSesion(Usuario? usuario) {
    if (_uid == usuario?.id) return;
    _uid = usuario?.id;
    _suscripcion?.cancel();
    _productos = [];
    error = false;
    cargando = usuario != null;
    if (usuario == null) return;

    _suscripcion = _servicio.productos
        .snapshots(includeMetadataChanges: true)
        .listen((resultado) {
      if (resultado.metadata.isFromCache && resultado.docs.isEmpty) return;
      final docs = resultado.docs.toList()
        ..sort((a, b) {
          final primero = a.data()['creadoEn'];
          final segundo = b.data()['creadoEn'];
          final porFecha = (primero is Timestamp
                  ? primero.millisecondsSinceEpoch
                  : 0)
              .compareTo(
                  segundo is Timestamp ? segundo.millisecondsSinceEpoch : 0);
          return porFecha == 0 ? a.id.compareTo(b.id) : porFecha;
        });
      _productos = docs
          .map((doc) => Mapeadores.productoDesde(doc.id, doc.data()))
          .toList();
      cargando = false;
      error = false;
      notifyListeners();
    }, onError: (Object _) {
      cargando = false;
      error = true;
      notifyListeners();
    });
  }

  Categoria categoriaDe(String categoriaId) {
    return MockData.categorias.firstWhere(
      (c) => c.id == categoriaId,
      orElse: () => MockData.categorias.first,
    );
  }

  Producto? buscarPorId(String id) {
    for (final p in _productos) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool existeCodigo(String codigo, {String? ignorarId}) {
    return _productos.any((p) =>
        p.codigo.toLowerCase() == codigo.trim().toLowerCase() &&
        p.id != ignorarId);
  }

  Future<void> agregar(Producto producto) =>
      _servicio.productos.doc(producto.id).set({
        ...Mapeadores.productoAMapa(producto),
        'creadoEn': FieldValue.serverTimestamp(),
      });

  Future<void> actualizar(Producto producto,
      {required int stockOriginal}) async {
    final ref = _servicio.productos.doc(producto.id);
    final datos = Mapeadores.productoAMapa(producto);
    if (producto.stock == stockOriginal) {
      datos.remove('stock');
      await ref.update(datos);
      return;
    }
    await _servicio.db.runTransaction((transaccion) async {
      final actual = await transaccion.get(ref);
      if (actual.data()?['stock'] != stockOriginal) {
        throw StateError('El stock cambió mientras se editaba el producto.');
      }
      transaccion.update(ref, datos);
    });
  }

  Future<void> reponer(String id, int unidades) => _servicio.productos
      .doc(id)
      .update({'stock': FieldValue.increment(unidades)});

  Future<void> eliminar(String id) => _servicio.productos.doc(id).delete();

  final ValueNotifier<List<AlertaStock>> alertas = ValueNotifier(const []);
  List<Producto> get criticos => _productos.where((p) => p.critico).toList();
  List<Producto> get agotados => _productos.where((p) => p.agotado).toList();

  void avisarStock(List<Map<String, dynamic>> cambios) {
    final nuevas = <AlertaStock>[];
    for (final cambio in cambios) {
      final producto = buscarPorId(cambio['id'] as String);
      if (producto == null) continue;
      final antes = producto.copyWith(stock: cambio['antes'] as int);
      final despues = producto.copyWith(stock: cambio['despues'] as int);
      if ((!antes.stockBajo && despues.stockBajo) ||
          (!antes.agotado && despues.agotado)) {
        nuevas.add(AlertaStock(despues));
      }
    }
    if (nuevas.isNotEmpty) alertas.value = nuevas;
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    alertas.dispose();
    super.dispose();
  }
}

class AlertaStock {
  final Producto producto;
  const AlertaStock(this.producto);
  bool get agotado => producto.agotado;
}
