import 'dart:async';

import 'package:flutter/material.dart';

import '../data/firestore_mappers.dart';
import '../data/models/cliente.dart';
import '../services/firestore_service.dart';

class ClienteProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService.instance;

  List<Cliente> _clientes = [];
  StreamSubscription<List<Cliente>>? _sub;
  bool cargando = true;
  String? error;

  ClienteProvider() {
    _sub = _fs
        .escuchar<Cliente>(
            FirestoreService.colClientes, Mapeadores.clienteDesde)
        .listen((lista) {
      _clientes = lista;
      cargando = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      cargando = false;
      error = e.toString();
      debugPrint('❌ Firestore [clientes]: $e');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Cliente> get clientes => List.unmodifiable(_clientes);
  int get totalClientes => _clientes.length;

  bool existeDocumento(String documento, {String? ignorarId}) {
    return _clientes
        .any((c) => c.documento == documento.trim() && c.id != ignorarId);
  }

  void agregar(Cliente cliente) {
    _clientes.add(cliente);
    notifyListeners();
    unawaited(_fs.crear(FirestoreService.colClientes, cliente.id,
        Mapeadores.clienteAMapa(cliente)));
  }

  void actualizar(Cliente cliente) {
    final index = _clientes.indexWhere((c) => c.id == cliente.id);
    if (index >= 0) {
      _clientes[index] = cliente;
      notifyListeners();
      unawaited(_fs.guardar(FirestoreService.colClientes, cliente.id,
          Mapeadores.clienteAMapa(cliente)));
    }
  }

  void eliminar(String id) {
    _clientes.removeWhere((c) => c.id == id);
    notifyListeners();
    unawaited(_fs.eliminar(FirestoreService.colClientes, id));
  }
}
