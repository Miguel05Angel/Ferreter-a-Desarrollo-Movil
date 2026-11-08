import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseFerreteria {
  FirebaseFerreteria._();

  static late final FirebaseApp _app;
  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: _app);
  static FirebaseFunctions get funciones =>
      FirebaseFunctions.instanceFor(app: _app);
  static FirebaseFirestore get db => FirebaseFirestore.instanceFor(
        app: _app,
        databaseId: 'ferreteria-db',
      );

  static Future<void> inicializar() async {
    const host = String.fromEnvironment('FIREBASE_EMULADOR');
    if (kReleaseMode || host.isEmpty) {
      _app = await Firebase.initializeApp();
      return;
    }

    _app = await Firebase.initializeApp(
      name: 'ferreteria-local',
      options: const FirebaseOptions(
        // Firebase Installations valida el formato incluso en el emulador.
        apiKey: 'AIza00000000000000000000000000000000000',
        appId: '1:1:android:1',
        messagingSenderId: '1',
        projectId: 'demo-ferreteria',
      ),
    );
    await auth.useAuthEmulator(host, 9099, automaticHostMapping: false);
    db.useFirestoreEmulator(host, 8080, automaticHostMapping: false);
    funciones.useFunctionsEmulator(host, 5001, automaticHostMapping: false);
  }
}
