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

  // ---------------------------------------------------------------------
  // Pago de una cotizacion. Solo existe cuando el carrito se armo desde una
  // cotizacion aprobada; las compras normales nunca lo usan.
  // ---------------------------------------------------------------------
  String? _cotizacionId;
  final Set<String> _idsCotizados = {};
  final Set<String> _fueraDeCotizacion = {}; // el usuario decidio dejarlos fuera
  final List<String> _consultas = []; // productos nuevos esperando decision

  /// Id de la cotizacion que se esta pagando (null en compras normales).
  String? get cotizacionId => _cotizacionId;
  bool get enModoCotizacion => _cotizacionId != null;

  /// Productos nuevos (fuera de la cotizacion) que aun no se resolvieron.
  List<String> get consultasPendientes => List.unmodifiable(_consultas);

  /// Prepara el carrito para pagar la cotizacion [id]. Se vacia lo anterior.
  void iniciarCotizacion(String id, Iterable<String> productoIds) {
    _items.clear();
    _consultas.clear();
    _fueraDeCotizacion.clear();
    _idsCotizados
      ..clear()
      ..addAll(productoIds);
    _cotizacionId = id;
    notifyListeners();
  }

  /// El usuario eligio [Continuar Comprando]: esos productos se compran pero
  /// no figuraran en la cotizacion.
  void resolverContinuar() {
    _fueraDeCotizacion.addAll(_consultas);
    _consultas.clear();
    notifyListeners();
  }

  /// El usuario eligio actualizar la cotizacion: devuelve los productos
  /// nuevos y los marca como parte de la cotizacion.
  List<ItemCarrito> resolverEditar() {
    final nuevos = [
      for (final id in _consultas)
        if (_items[id] != null) _items[id]!,
    ];
    _idsCotizados.addAll(_consultas);
    _consultas.clear();
    notifyListeners();
    return nuevos;
  }

  // ---------------------------------------------------------------------

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

    // Producto que no estaba en la cotizacion que se esta pagando.
    if (_cotizacionId != null &&
        !_idsCotizados.contains(producto.id) &&
        !_fueraDeCotizacion.contains(producto.id) &&
        !_consultas.contains(producto.id)) {
      _consultas.add(producto.id);
    }
    notifyListeners();
    return null;
  }

  String? actualizarCantidad(String productoId, int cantidad) {
    final item = _items[productoId];
    if (item == null) return null;
    if (cantidad <= 0) {
      eliminar(productoId);
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
    _consultas.remove(productoId);
    _fueraDeCotizacion.remove(productoId);
    notifyListeners();
  }

  /// Vacia el carrito de una vez (y termina el pago de cotizacion, si habia).
  void limpiar() {
    _items.clear();
    _consultas.clear();
    _fueraDeCotizacion.clear();
    _idsCotizados.clear();
    _cotizacionId = null;
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
