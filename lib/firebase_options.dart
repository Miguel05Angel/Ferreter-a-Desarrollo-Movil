// Opciones de Firebase por plataforma.
//
// Los valores de Android salen de android/app/google-services.json, que ya
// esta en el repositorio, por lo que el telefono funciona sin pasos extra.
//
// Web e iOS todavia NO tienen una app registrada en Firebase Console. Cuando
// la registren, la forma recomendada de rellenar este archivo es dejar que lo
// genere la herramienta oficial:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure
//
// Eso sobrescribe este archivo con los valores correctos de las tres
// plataformas. Mientras no se haga, arrancar en web o iOS lanza el error de
// abajo con la instruccion, en lugar de fallar con un mensaje confuso.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Falta registrar la app iOS en Firebase Console.\n'
          'El Bundle ID debe ser el mismo que el applicationId de Android: '
          'com.example.ferreteria_app\n'
          'Despues ejecuta: flutterfire configure',
        );
      default:
        throw UnsupportedError(
          'Esta app solo esta configurada para Android y Web. '
          'Plataforma actual: $defaultTargetPlatform',
        );
    }
  }

  /// Tomado de android/app/google-services.json (proyecto ferreteria-app-16bde).

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4oalehEv-epYe-8tlNjToDY22Vv7PRKY',
    appId: '1:216446212508:android:71d539cc5108e292cbd059',
    messagingSenderId: '216446212508',
    projectId: 'ferreteria-el-constructor',
    storageBucket: 'ferreteria-el-constructor.firebasestorage.app',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_oGZUNd23s9WjcW7x77PNw9qhLGb1moE',
    appId: '1:216446212508:web:de19719c6791698dcbd059',
    messagingSenderId: '216446212508',
    projectId: 'ferreteria-el-constructor',
    authDomain: 'ferreteria-el-constructor.firebaseapp.com',
    storageBucket: 'ferreteria-el-constructor.firebasestorage.app',
    measurementId: 'G-Y7MCR5E67L',
  );
}
