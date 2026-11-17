import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseFerreteria {
  FirebaseFerreteria._();

  static late final FirebaseApp _app;
  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: _app);
  static FirebaseFunctions get funciones =>
      FirebaseFunctions.instanceFor(app: _app);
      
  // 🔥 ESTA ES LA LÍNEA MÁGICA: NO TIENE 'ferreteria-db'
  static FirebaseFirestore get db => FirebaseFirestore.instanceFor(
        app: _app,
      );

  static Future<void> inicializar() async {
    try {
      _app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("🚀 Firebase inicializado con éxito.");
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        print("✅ Firebase ya estaba encendido por Android. Reutilizando...");
        _app = Firebase.app();
      } else {
        rethrow;
      }
    }
  }
}