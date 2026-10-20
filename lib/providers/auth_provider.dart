import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models/usuario.dart';

class AuthProvider extends ChangeNotifier {
  final List<Usuario> _usuarios = [MockData.usuarioDemo];
  Usuario? _usuarioActual;

  Usuario? get usuarioActual => _usuarioActual;
  bool get autenticado => _usuarioActual != null;

  /// Retorna true si el inicio de sesion fue exitoso.
  bool iniciarSesion(String email, String password) {
    final normalizado = email.trim().toLowerCase();
    for (final u in _usuarios) {
      if (u.email.toLowerCase() == normalizado && u.password == password) {
        _usuarioActual = u;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Registra un nuevo usuario e inicia sesion automaticamente.
  bool registrar({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
  }) {
    final normalizado = email.trim().toLowerCase();
    final existe = _usuarios.any((u) => u.email.toLowerCase() == normalizado);
    if (existe) return false;

    final nuevo = Usuario(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre.trim(),
      email: normalizado,
      telefono: telefono.trim(),
      password: password,
      rol: 'Vendedor',
    );
    _usuarios.add(nuevo);
    _usuarioActual = nuevo;
    notifyListeners();
    return true;
  }

  void actualizarNombre(String nombre) {
    if (_usuarioActual == null) return;
    final index = _usuarios.indexWhere((u) => u.id == _usuarioActual!.id);
    if (index >= 0) {
      final actualizado = Usuario(
        id: _usuarios[index].id,
        nombre: nombre.trim(),
        email: _usuarios[index].email,
        telefono: _usuarios[index].telefono,
        password: _usuarios[index].password,
        rol: _usuarios[index].rol,
      );
      _usuarios[index] = actualizado;
      _usuarioActual = actualizado;
      notifyListeners();
    }
  }

  void cerrarSesion() {
    _usuarioActual = null;
    notifyListeners();
  }
}
