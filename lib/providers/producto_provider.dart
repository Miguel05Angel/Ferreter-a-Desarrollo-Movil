import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/mock_data.dart';
import '../data/models/categoria.dart';
import '../data/models/producto.dart';

class ProductoProvider extends ChangeNotifier {
  final List<Producto> _productos = List.of(MockData.productos);
  final List<Categoria> _categorias = List.of(MockData.categorias);

  List<Producto> get productos => List.unmodifiable(_productos);
  List<Categoria> get categorias => List.unmodifiable(_categorias);

  int get totalProductos => _productos.length;

  int get productosStockBajo =>
      _productos.where((p) => p.stock <= AppConstants.stockBajo).length;

  double get valorInventario => _productos.fold(
      0.0, (suma, p) => suma + p.precioVenta * p.stock);

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
    return _productos.any(
        (p) => p.codigo.toLowerCase() == codigo.trim().toLowerCase() && p.id != ignorarId);
  }

  void agregar(Producto producto) {
    _productos.add(producto);
    notifyListeners();
  }

  void actualizar(Producto producto) {
    final index = _productos.indexWhere((p) => p.id == producto.id);
    if (index >= 0) {
      _productos[index] = producto;
      notifyListeners();
    }
  }

  void eliminar(String id) {
    _productos.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Alertas urgentes de reposicion: se emiten cuando una venta deja un
  /// producto en STOCK CRITICO (antes de agotarse) o AGOTADO.
  final ValueNotifier<List<AlertaStock>> alertas = ValueNotifier(const []);

  List<Producto> get criticos => _productos.where((p) => p.critico).toList();
  List<Producto> get agotados => _productos.where((p) => p.agotado).toList();

  @override
  void dispose() {
    alertas.dispose();
    super.dispose();
  }

  /// Descuenta el stock despues de registrar una venta.
  void descontarStock(List<({String productoId, int cantidad})> items) {
    final nuevas = <AlertaStock>[];
    for (final item in items) {
      final index = _productos.indexWhere((p) => p.id == item.productoId);
      if (index >= 0) {
        final actual = _productos[index];
        final nuevoStock = actual.stock - item.cantidad;
        final despues =
            actual.copyWith(stock: nuevoStock < 0 ? 0 : nuevoStock);
        _productos[index] = despues;
        // Alerta solo cuando cruza el limite (no en cada venta).
        final cruzoMinimo = !actual.stockBajo && despues.stockBajo;
        final seAgoto = !actual.agotado && despues.agotado;
        if (cruzoMinimo || seAgoto) {
          nuevas.add(AlertaStock(despues));
        }
      }
    }
    notifyListeners();
    if (nuevas.isNotEmpty) alertas.value = nuevas;
  }
}


/// Aviso de reposicion: [producto.agotado] indica si ya no quedan unidades.
class AlertaStock {
  final Producto producto;
  const AlertaStock(this.producto);
  bool get agotado => producto.agotado;
}
