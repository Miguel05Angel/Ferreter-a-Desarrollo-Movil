import 'dart:async';

import 'package:flutter/material.dart';

import '../data/firestore_mappers.dart';
import '../data/models/proveedor.dart';
import '../services/firestore_service.dart';

class ProveedorProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService.instance;

  List<Proveedor> _proveedores = [];
  StreamSubscription<List<Proveedor>>? _sub;
  bool cargando = true;
  String? error;

  ProveedorProvider() {
    _sub = _fs
        .escuchar<Proveedor>(
            FirestoreService.colProveedores, Mapeadores.proveedorDesde)
        .listen((lista) {
      _proveedores = lista;
      cargando = false;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      cargando = false;
      error = e.toString();
      debugPrint('❌ Firestore [proveedores]: $e');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);
  int get totalProveedores => _proveedores.length;

  bool existeRuc(String ruc, {String? ignorarId}) {
    return _proveedores.any((p) => p.ruc == ruc.trim() && p.id != ignorarId);
  }

  void agregar(Proveedor proveedor) {
    _proveedores.add(proveedor);
    notifyListeners();
    unawaited(_fs.crear(FirestoreService.colProveedores, proveedor.id,
        Mapeadores.proveedorAMapa(proveedor)));
  }

  void actualizar(Proveedor proveedor) {
    final index = _proveedores.indexWhere((p) => p.id == proveedor.id);
    if (index >= 0) {
      _proveedores[index] = proveedor;
      notifyListeners();
      unawaited(_fs.guardar(FirestoreService.colProveedores, proveedor.id,
          Mapeadores.proveedorAMapa(proveedor)));
    }
  }

  void eliminar(String id) {
    _proveedores.removeWhere((p) => p.id == id);
    notifyListeners();
    unawaited(_fs.eliminar(FirestoreService.colProveedores, id));
  }
}
