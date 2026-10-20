import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/firestore_mappers.dart';
import '../data/mock_data.dart';
import '../data/models/categoria.dart';
import '../data/models/producto.dart';
import '../services/firestore_service.dart';

class ProductoProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService.instance;

  List<Producto> _productos = [];
  // Las categorias tienen icono y color, por eso se mantienen en la app.
  final List<Categoria> _categorias = List.of(MockData.categorias);

  StreamSubscription<List<Producto>>? _sub;
  bool cargando = true;
  String? error;

  ProductoProvider() {
    _sub = _fs
        .escuchar<Producto>(
            FirestoreService.colProductos, Mapeadores.productoDesde)
        .listen((lista) {
      _productos = lista;
      cargando = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      cargando = false;
      error = e.toString();
      debugPrint('❌ Firestore [productos]: $e');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Producto> get productos => List.unmodifiable(_productos);
  List<Categoria> get categorias => List.unmodifiable(_categorias);

  int get totalProductos => _productos.length;

  int get productosStockBajo =>
      _productos.where((p) => p.stock <= AppConstants.stockBajo).length;

  double get valorInventario =>
      _productos.fold(0.0, (suma, p) => suma + p.precioVenta * p.stock);

  Categoria categoriaDe(String categoriaId) {
    return _categorias.firstWhere(
      (c) => c.id == categoriaId,
      orElse: () => _categorias.first,
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

  void agregar(Producto producto) {
    _productos.add(producto);
    notifyListeners();
    unawaited(_fs.crear(FirestoreService.colProductos, producto.id,
        Mapeadores.productoAMapa(producto)));
  }

  void actualizar(Producto producto) {
    final index = _productos.indexWhere((p) => p.id == producto.id);
    if (index >= 0) {
      _productos[index] = producto;
      notifyListeners();
      unawaited(_fs.guardar(FirestoreService.colProductos, producto.id,
          Mapeadores.productoAMapa(producto)));
    }
  }

  void eliminar(String id) {
    _productos.removeWhere((p) => p.id == id);
    notifyListeners();
    unawaited(_fs.eliminar(FirestoreService.colProductos, id));
  }

  /// Descuenta el stock despues de registrar una venta.
  void descontarStock(List<({String productoId, int cantidad})> items) {
    for (final item in items) {
      final index = _productos.indexWhere((p) => p.id == item.productoId);
      if (index >= 0) {
        final actual = _productos[index];
        final nuevoStock = actual.stock - item.cantidad;
        final stockFinal = nuevoStock < 0 ? 0 : nuevoStock;
        _productos[index] = actual.copyWith(stock: stockFinal);
        unawaited(_fs.guardar(FirestoreService.colProductos, actual.id,
            {'stock': stockFinal}));
      }
    }
    notifyListeners();
  }
}
