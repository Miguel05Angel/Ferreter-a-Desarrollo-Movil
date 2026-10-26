import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models/producto.dart';
import '../data/models/proveedor.dart';

class ProveedorProvider extends ChangeNotifier {
  final List<Proveedor> _proveedores = List.of(MockData.proveedores);

  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);
  int get totalProveedores => _proveedores.length;

  /// Proveedor al que se le debe pedir la reposicion de un producto: primero
  /// por marca (por ejemplo Truper) y, si no hay, por la categoria.
  Proveedor? paraProducto(Producto producto, String categoriaNombre) {
    String limpio(String t) => t.toLowerCase();
    final marca = limpio(producto.marca);

    for (final v in _proveedores) {
      final palabras = limpio(v.nombre).split(RegExp(r'[\s.]+'));
      if (palabras.contains(marca)) return v;
    }

    final clave = limpio(categoriaNombre).split(' ').first;
    final raiz = clave.length > 5 ? clave.substring(0, 5) : clave;
    for (final v in _proveedores) {
      final texto = limpio('${v.nombre} ${v.productos.join(' ')}');
      if (texto.contains(raiz)) return v;
    }
    return _proveedores.isEmpty ? null : _proveedores.first;
  }

  bool existeRuc(String ruc, {String? ignorarId}) {
    return _proveedores.any(
        (p) => p.ruc == ruc.trim() && p.id != ignorarId);
  }

  void agregar(Proveedor proveedor) {
    _proveedores.add(proveedor);
    notifyListeners();
  }

  void actualizar(Proveedor proveedor) {
    final index = _proveedores.indexWhere((p) => p.id == proveedor.id);
    if (index >= 0) {
      _proveedores[index] = proveedor;
      notifyListeners();
    }
  }

  void eliminar(String id) {
    _proveedores.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
