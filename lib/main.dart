import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'admin_app.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseListo = await _iniciarFirebase();

  // Mismo codigo, dos caras: en el navegador arranca el panel administrativo
  // y en el telefono la app de la ferreteria.
  runApp(
    kIsWeb
        ? AdminWebApp(firebaseListo: firebaseListo)
        : const FerreteriaApp(),
  );

  // Comprueba la conexion con la base y carga los datos de ejemplo la primera
  // vez. Mira la consola: debe salir "Firestore CONECTADO".
  if (firebaseListo) {
    unawaited(FirestoreService.instance.inicializarBaseDeDatos());
  }
}

/// Inicializa Firebase sin tumbar la app si algo falta.
///
/// Si devuelve `false`, la app del telefono sigue funcionando con los datos
/// locales de MockData y el panel web muestra una pantalla explicando que
/// falta configurar.
Future<bool> _iniciarFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase INICIALIZADO. Proyecto: '
        '${Firebase.app().options.projectId}');
    return true;
  } catch (e) {
    debugPrint('❌ Firebase NO se pudo inicializar: $e');
    debugPrint('👉 La app sigue abriendo con los datos locales (MockData).');
    return false;
  }
}
