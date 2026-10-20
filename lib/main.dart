import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  debugPrint('✅ Firebase INICIALIZADO. Proyecto: '
      '${Firebase.app().options.projectId}');

  runApp(const FerreteriaApp());

  // Comprueba la conexion con la base y carga los datos de ejemplo
  // la primera vez. Mira la consola: debe salir "Firestore CONECTADO".
  unawaited(FirestoreService.instance.inicializarBaseDeDatos());
}
