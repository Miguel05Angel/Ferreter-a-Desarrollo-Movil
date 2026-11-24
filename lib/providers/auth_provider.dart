import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../data/models/usuario.dart';
import '../core/utils/validators.dart';
import '../services/firebase_ferreteria.dart';
import '../services/firestore_service.dart';
import '../services/foto_perfil_service.dart';

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

      final uid = credencial.user!.uid;

      // Forzamos la lectura desde el servidor
      final perfil =
          await _perfiles.doc(uid).get(const GetOptions(source: Source.server));

      final datos = perfil.data();

      if (datos == null || !perfil.exists) {
        throw const AuthError(
            'No se encontró el perfil. Revisa el UID en Firestore.');
      }

      final dniApp = dni.trim();
      final dniEnFirestore = datos['dni']?.toString().trim() ?? '';
      final rolEnFirestore =
          datos['rol']?.toString().trim().toLowerCase() ?? '';

      if (dniEnFirestore != dniApp ||
          !['administrador', 'vendedor'].contains(rolEnFirestore)) {
        throw const AuthError(
            'El perfil no coincide. Revisa los datos en Firestore.');
      }

      if (rolEnFirestore == 'administrador') {
        try {
          await FirestoreService.instance.prepararCatalogo();
        } catch (e) {
          debugPrint('Advertencia: No se pudo preparar el catálogo: $e');
        }
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
          ? 'Permiso denegado en Firestore. Revisa las Reglas.'
          : 'Error de Firestore: ${error.message}');
    } on AuthError {
      await _auth.signOut();
      rethrow;
    } catch (e) {
      await _auth.signOut();
      throw AuthError('Error inesperado: $e');
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

  User _administradorParaPassword() {
    final user = _auth.currentUser;
    if (_usuarioActual?.rol != 'Administrador' ||
        user == null ||
        _usuarioActual?.id != user.uid) {
      throw const AuthError('Solo un administrador puede cambiar contraseñas.');
    }
    return user;
  }

  Future<User> _confirmarAdministrador(String passwordActual) async {
    final user = _administradorParaPassword();
    if (user.email == null || passwordActual.isEmpty) {
      throw const AuthError('Ingresa tu contraseña actual.');
    }
    await user.reauthenticateWithCredential(EmailAuthProvider.credential(
      email: user.email!,
      password: passwordActual,
    ));
    if (_administradorParaPassword().uid != user.uid) {
      throw const AuthError('La sesión cambió. Vuelve a iniciar sesión.');
    }
    return user;
  }

  AuthError _errorPassword(FirebaseAuthException error) => AuthError(
        switch (error.code) {
          'invalid-credential' ||
          'invalid-login-credentials' ||
          'wrong-password' =>
            'La contraseña actual del administrador es incorrecta.',
          'weak-password' ||
          'password-does-not-meet-requirements' =>
            'La nueva contraseña no cumple los requisitos de seguridad.',
          'network-request-failed' =>
            'Revisa tu conexión e inténtalo de nuevo.',
          'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
          'requires-recent-login' => 'Vuelve a confirmar tu contraseña actual.',
          _ => 'No se pudo cambiar la contraseña. Vuelve a iniciar sesión.',
        },
      );

  Future<void> cambiarMiPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    _administradorParaPassword();
    final error = Validators.nuevaPassword(nuevaPassword);
    if (error != null) throw AuthError(error);
    if (passwordActual == nuevaPassword) {
      throw const AuthError('Elige una contraseña diferente a la actual.');
    }
    try {
      final user = await _confirmarAdministrador(passwordActual);
      await user.updatePassword(nuevaPassword);
    } on FirebaseAuthException catch (error) {
      throw _errorPassword(error);
    }
  }

  Future<void> restablecerPasswordUsuario({
    required String usuarioId,
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    final actual = _administradorParaPassword();
    if (actual.uid == usuarioId) {
      throw const AuthError('Usa Cambiar mi contraseña para tu propia cuenta.');
    }
    final error = Validators.nuevaPassword(nuevaPassword);
    if (error != null) throw AuthError(error);
    try {
      final user = await _confirmarAdministrador(passwordActual);
      await user.getIdToken(true);
      if (_administradorParaPassword().uid != user.uid) {
        throw const AuthError('La sesión cambió. Vuelve a iniciar sesión.');
      }
      await FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'southamerica-east1',
      ).httpsCallable('restablecerPasswordUsuario').call({
        'usuarioId': usuarioId,
        'nuevaPassword': nuevaPassword,
      });
    } on FirebaseAuthException catch (error) {
      throw _errorPassword(error);
    } on FirebaseFunctionsException catch (error) {
      throw AuthError(switch (error.code) {
        'not-found' =>
          'La cuenta no existe o la función aún no está publicada en Firebase.',
        'permission-denied' =>
          'Solo un administrador puede restablecer contraseñas.',
        'failed-precondition' => 'Confirma de nuevo tu contraseña actual.',
        'unauthenticated' => 'Vuelve a iniciar sesión.',
        'unavailable' ||
        'deadline-exceeded' =>
          'No se pudo confirmar el cambio. Revisa la conexión antes de reintentar.',
        'invalid-argument' =>
          'Revisa la nueva contraseña y los datos de la cuenta.',
        _ => 'No se pudo restablecer la contraseña. Inténtalo de nuevo.',
      });
    }
  }

  Future<void> eliminarUsuario({
    required String usuarioId,
    required String passwordActual,
  }) async {
    final actual = _administradorParaPassword();
    if (actual.uid == usuarioId) {
      throw const AuthError('No puedes eliminar tu propia cuenta.');
    }
    try {
      final user = await _confirmarAdministrador(passwordActual);
      await user.getIdToken(true);
      if (_administradorParaPassword().uid != user.uid) {
        throw const AuthError('La sesión cambió. Vuelve a iniciar sesión.');
      }
      await FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'southamerica-east1',
      ).httpsCallable('eliminarUsuario').call({'usuarioId': usuarioId});
    } on FirebaseAuthException catch (error) {
      throw _errorPassword(error);
    } on FirebaseFunctionsException catch (error) {
      throw AuthError(switch (error.code) {
        'not-found' =>
          'La función de eliminación aún no está publicada en Firebase.',
        'permission-denied' => 'Solo un administrador puede eliminar usuarios.',
        'failed-precondition' =>
          'No se puede eliminar esta cuenta. Confirma tu contraseña y revisa el perfil.',
        'unauthenticated' => 'Vuelve a iniciar sesión.',
        _ =>
          'No se pudo confirmar la eliminación. Actualiza la lista antes de reintentar.',
      });
    }
  }

  Future<void> editarUsuario({
    required String usuarioId,
    required String nombre,
    required String telefono,
  }) async {
    if (_usuarioActual?.rol != 'Administrador' || _auth.currentUser == null) {
      throw const AuthError('Solo un administrador puede editar usuarios.');
    }
    final nombreLimpio = nombre.trim();
    final telefonoLimpio = telefono.trim();
    final error = Validators.nombre(nombreLimpio) ??
        (nombreLimpio.length > 50
            ? 'El nombre admite hasta 50 caracteres.'
            : null) ??
        Validators.telefonoOpcional(telefonoLimpio);
    if (error != null) throw AuthError(error);
    try {
      await _perfiles.doc(usuarioId).update({
        'nombre': nombreLimpio,
        'telefono': telefonoLimpio,
      });
      if (_usuarioActual?.id == usuarioId) {
        _usuarioActual = _usuarioActual!.copyWith(
          nombre: nombreLimpio,
          telefono: telefonoLimpio,
        );
        notifyListeners();
      }
    } on FirebaseException catch (error) {
      throw AuthError(error.code == 'permission-denied'
          ? 'No tienes permiso para editar usuarios. Revisa las reglas de Firebase.'
          : 'No se pudo guardar el usuario. Inténtalo de nuevo.');
    }
  }

  Future<void> registrarVendedor({
    required String operacion, // Se mantiene por compatibilidad con la UI
    required String dni,
    required String nombre,
    required String telefono,
    required String password,
  }) async {
    if (_usuarioActual?.rol.toLowerCase() != 'administrador') {
      throw const AuthError(
          'Solo un administrador puede registrar vendedores.');
    }

    try {
      // 1. Inicializar una app secundaria para no cerrar la sesión del administrador
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name:
            'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}', // Nombre único
        options: Firebase.app().options,
      );

      // 2. Crear el usuario en Authentication
      UserCredential credenciales =
          await FirebaseAuth.instanceFor(app: secondaryApp)
              .createUserWithEmailAndPassword(
        email: '${dni.trim()}@acceso.ferreteria.invalid',
        password: password,
      );

      String nuevoUid = credenciales.user!.uid;

      // 3. Guardar sus datos en Firestore (Base de datos ferreteria-db)
      await FirestoreService.instance.db
          .collection('usuarios')
          .doc(nuevoUid)
          .set({
        'dni': dni.trim(),
        'nombre': nombre.trim(),
        'telefono': telefono.trim(),
        'rol': 'Vendedor',
      });

      // 4. Limpiar la sesión secundaria para no dejar procesos abiertos
      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthError('Este DNI ya está registrado.');
      }
      throw AuthError('Error de Firebase Auth: ${e.message}');
    } on FirebaseException catch (e) {
      throw AuthError('Error de Firestore: ${e.message}');
    } catch (e) {
      throw AuthError('Error inesperado al registrar: $e');
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
    _usuarioActual = _usuarioActual!.copyWith(nombre: nombre.trim());
    notifyListeners();
  }

  Future<void> actualizarFotoPerfil(
    Uint8List? foto, {
    required String usuarioId,
  }) async {
    if (_usuarioActual?.id != usuarioId ||
        _auth.currentUser?.uid != usuarioId) {
      throw const AuthError(
          'Inicia sesión con tu cuenta para cambiar la foto.');
    }
    if (foto != null && foto.length > FotoPerfilService.maxBytes) {
      throw const AuthError('La foto pesa demasiado. Elige otra imagen.');
    }
    await _perfiles.doc(usuarioId).update({
      'fotoPerfil': foto == null ? null : Blob(foto),
    });
    if (_usuarioActual?.id != usuarioId) return;
    _usuarioActual = _usuarioActual!.copyWith(
      fotoPerfil: foto,
      quitarFoto: foto == null,
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
