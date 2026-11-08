import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/models/usuario.dart';
import '../services/firebase_ferreteria.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseFerreteria.auth;
  final _perfiles = FirestoreService.instance.db.collection('usuarios');
  Usuario? _usuarioActual;

  Usuario? get usuarioActual => _usuarioActual;
  bool get autenticado => _usuarioActual != null;

  Future<void> iniciarSesion(String dni, String password) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: '${dni.trim()}@acceso.ferreteria.invalid',
        password: password,
      );
      final perfil = await _perfiles
          .doc(credencial.user!.uid)
          .get(const GetOptions(source: Source.server));
      final datos = perfil.data();
      if (datos == null ||
          datos['dni'] != dni.trim() ||
          !['Administrador', 'Vendedor'].contains(datos['rol'])) {
        throw const AuthError('La cuenta no tiene un perfil autorizado.');
      }
      if (datos['rol'] == 'Administrador') {
        await FirestoreService.instance.prepararCatalogo();
      }
      _usuarioActual = Usuario.desdeFirestore(perfil.id, datos);
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      throw AuthError(switch (error.code) {
        'network-request-failed' => 'Revisa tu conexión e inténtalo de nuevo.',
        'too-many-requests' =>
          'Demasiados intentos. Vuelve a probar en unos minutos.',
        'operation-not-allowed' =>
          'El acceso por contraseña aún no está habilitado.',
        _ => 'Verifica tu DNI y contraseña.',
      });
    } on FirebaseException catch (error) {
      await _auth.signOut();
      throw AuthError(error.code == 'permission-denied'
          ? 'La cuenta no tiene un perfil autorizado.'
          : 'No se pudo preparar el acceso a Firestore.');
    } on AuthError {
      await _auth.signOut();
      rethrow;
    }
  }

  Stream<List<Usuario>> escucharUsuarios() {
    return _perfiles.snapshots().map((resultado) {
      final usuarios = resultado.docs
          .map((doc) => Usuario.desdeFirestore(doc.id, doc.data()))
          .toList();
      return usuarios..sort((a, b) => a.nombre.compareTo(b.nombre));
    });
  }

  String nuevaOperacion() => _perfiles.doc().id;

  Future<void> registrarVendedor({
    required String operacion,
    required String dni,
    required String nombre,
    required String telefono,
    required String password,
  }) async {
    if (_usuarioActual?.rol != 'Administrador') {
      throw const AuthError(
          'Solo un administrador puede registrar vendedores.');
    }
    try {
      await FirebaseFerreteria.funciones
          .httpsCallable('registrarVendedor')
          .call({
        'operacion': operacion,
        'dni': dni.trim(),
        'nombre': nombre.trim(),
        'telefono': telefono.trim(),
        'password': password,
      });
    } on FirebaseFunctionsException catch (error) {
      throw AuthError(switch (error.code) {
        'already-exists' => 'Este DNI ya está registrado.',
        'invalid-argument' =>
          'Revisa el DNI, el nombre, el teléfono y la contraseña.',
        'permission-denied' ||
        'unauthenticated' =>
          'Se requiere una sesión de administrador.',
        _ =>
          'No se pudo completar el alta. Revisa la conexión y la función de Firebase.',
      });
    }
  }

  Future<bool> verificarPassword(String clave) async {
    final usuario = _auth.currentUser;
    if (!autenticado || usuario == null || usuario.email == null) return false;
    try {
      await usuario.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: usuario.email!, password: clave),
      );
      return true;
    } on FirebaseAuthException catch (error) {
      if (['invalid-credential', 'invalid-login-credentials', 'wrong-password']
          .contains(error.code)) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> actualizarNombre(String nombre) async {
    final actual = _usuarioActual;
    if (actual == null) return;
    await _perfiles.doc(actual.id).update({'nombre': nombre.trim()});
    if (_usuarioActual?.id != actual.id) return;
    _usuarioActual = Usuario(
      id: actual.id,
      dni: actual.dni,
      nombre: nombre.trim(),
      telefono: actual.telefono,
      rol: actual.rol,
    );
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
    _usuarioActual = null;
    notifyListeners();
  }
}

class AuthError implements Exception {
  final String mensaje;
  const AuthError(this.mensaje);
}
