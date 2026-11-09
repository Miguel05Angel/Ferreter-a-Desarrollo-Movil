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
      throw UnsupportedError(
        'Falta registrar la app Web en Firebase Console.\n'
        'Console > Configuracion del proyecto > Agregar aplicacion > Web (</>)\n'
        'y despues ejecuta: flutterfire configure',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Falta registrar la app iOS en Firebase Console.\n'
          'El Bundle ID debe ser el mismo que el applicationId de Android: '
          'com.elconstructor.ferreteria_app\n'
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
    apiKey: 'AIzaSyBmLDW2IkdP6KNyxAc_pvmkhuNn7Ru9SQ4',
    appId: '1:100244183370:android:d3ae26e6c98a2e587d89b3',
    messagingSenderId: '100244183370',
    projectId: 'ferreteria-app-16bde',
    storageBucket: 'ferreteria-app-16bde.firebasestorage.app',
  );
}
