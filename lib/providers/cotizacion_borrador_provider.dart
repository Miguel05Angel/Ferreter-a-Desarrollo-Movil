import 'package:flutter/material.dart';

import '../data/models/producto.dart';

/// Un producto del listado de la cotizacion que se esta armando.
class LineaCotizacion {
  final Producto producto;
  int cantidad;

  /// Precio unitario cotizado (al editar se conserva el de la cotizacion).
  final double precio;

  LineaCotizacion({required this.producto, this.cantidad = 1, double? precio})
      : precio = precio ?? producto.precioVenta;

  double get subtotal => (cantidad * precio * 100).round() / 100;

  /// Unidades que la tienda no puede cubrir con el stock actual.
  int get faltante => cantidad > producto.stock ? cantidad - producto.stock : 0;

  bool get sinStock => faltante > 0;
}

/// Borrador de cotizacion. Es independiente del carrito de compras: los
/// productos elegidos desde el catalogo en modo cotizacion llegan aqui.
class CotizacionBorradorProvider extends ChangeNotifier {
  final List<LineaCotizacion> _lineas = [];

  /// Id de la cotizacion que se esta editando (null si es nueva).
  String? editandoId;

  List<LineaCotizacion> get lineas => List.unmodifiable(_lineas);
  bool get vacio => _lineas.isEmpty;
  int get unidades => _lineas.fold(0, (a, l) => a + l.cantidad);
  double get subtotal => _lineas.fold(0.0, (a, l) => a + l.subtotal);

  List<LineaCotizacion> get conFaltante =>
      _lineas.where((l) => l.sinStock).toList();

  int cantidadDe(String productoId) {
    for (final l in _lineas) {
      if (l.producto.id == productoId) return l.cantidad;
    }
    return 0;
  }

  /// A diferencia del carrito, una cotizacion PUEDE superar el stock: se
  /// permite y se resalta en rojo para avisar de lo que faltaria.
  void agregar(Producto producto, int cantidad) {
    if (cantidad <= 0) return;
    for (final l in _lineas) {
      if (l.producto.id == producto.id) {
        l.cantidad += cantidad;
        notifyListeners();
        return;
      }
    }
    _lineas.add(LineaCotizacion(producto: producto, cantidad: cantidad));
    notifyListeners();
  }

  void fijarCantidad(String productoId, int cantidad) {
    final i = _lineas.indexWhere((l) => l.producto.id == productoId);
    if (i < 0) return;
    if (cantidad <= 0) {
      _lineas.removeAt(i);
    } else {
      _lineas[i].cantidad = cantidad;
    }
    notifyListeners();
  }

  void quitar(String productoId) {
    _lineas.removeWhere((l) => l.producto.id == productoId);
    notifyListeners();
  }

  void cargar(List<LineaCotizacion> lineas, {String? editando}) {
    _lineas
      ..clear()
      ..addAll(lineas);
    editandoId = editando;
    notifyListeners();
  }

  void limpiar() {
    _lineas.clear();
    editandoId = null;
    notifyListeners();
  }
}
