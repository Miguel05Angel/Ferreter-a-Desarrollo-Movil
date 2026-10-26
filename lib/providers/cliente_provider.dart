import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models/cliente.dart';

class ClienteProvider extends ChangeNotifier {
  final List<Cliente> _clientes = List.of(MockData.clientes);

  List<Cliente> get clientes => List.unmodifiable(_clientes);
  int get totalClientes => _clientes.length;

  bool existeDocumento(String documento, {String? ignorarId}) {
    return _clientes.any(
        (c) => c.documento == documento.trim() && c.id != ignorarId);
  }

  void agregar(Cliente cliente) {
    _clientes.add(cliente);
    notifyListeners();
  }

  void actualizar(Cliente cliente) {
    final index = _clientes.indexWhere((c) => c.id == cliente.id);
    if (index >= 0) {
      _clientes[index] = cliente;
      notifyListeners();
    }
  }

  void eliminar(String id) {
    _clientes.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
