import 'package:flutter/material.dart';

import '../data/models/producto.dart';
import '../data/models/venta.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;

  ItemCarrito({required this.producto, this.cantidad = 1});

  double get subtotal => cantidad * producto.precioVenta;
}

class CarritoProvider extends ChangeNotifier {
  final Map<String, ItemCarrito> _items = {};

  List<ItemCarrito> get items => _items.values.toList();
  int get cantidadItems => _items.length;
  bool get vacio => _items.isEmpty;

  double get subtotal =>
      _items.values.fold(0.0, (suma, i) => suma + i.subtotal);

  /// Agrega un producto al carrito respetando el stock disponible.
  /// Retorna null si fue exitoso, o un mensaje de error.
  String? agregar(Producto producto, int cantidad) {
    if (cantidad <= 0) return 'La cantidad debe ser mayor a 0';

    final actual = _items[producto.id];
    final cantidadFinal = (actual?.cantidad ?? 0) + cantidad;

    if (cantidadFinal > producto.stock) {
      return 'Stock insuficiente. Solo hay ${producto.stock} unidades disponibles.';
    }

    if (actual == null) {
      _items[producto.id] = ItemCarrito(producto: producto, cantidad: cantidad);
    } else {
      actual.cantidad = cantidadFinal;
    }
    notifyListeners();
    return null;
  }

  String? actualizarCantidad(String productoId, int cantidad) {
    final item = _items[productoId];
    if (item == null) return null;
    if (cantidad <= 0) {
      _items.remove(productoId);
      notifyListeners();
      return null;
    }
    if (cantidad > item.producto.stock) {
      return 'Stock insuficiente. Maximo ${item.producto.stock} unidades.';
    }
    item.cantidad = cantidad;
    notifyListeners();
    return null;
  }

  void eliminar(String productoId) {
    _items.remove(productoId);
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }

  List<ItemVenta> aItemsVenta() {
    return _items.values
        .map((i) => ItemVenta(
              productoId: i.producto.id,
              nombre: i.producto.nombre,
              cantidad: i.cantidad,
              precioUnitario: i.producto.precioVenta,
            ))
        .toList();
  }
}
