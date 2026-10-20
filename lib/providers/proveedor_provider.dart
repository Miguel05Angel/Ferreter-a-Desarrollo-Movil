import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models/proveedor.dart';

class ProveedorProvider extends ChangeNotifier {
  final List<Proveedor> _proveedores = List.of(MockData.proveedores);

  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);
  int get totalProveedores => _proveedores.length;

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
