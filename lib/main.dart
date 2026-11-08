import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'admin_app.dart';
import 'app.dart';
import 'services/firebase_ferreteria.dart';

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

  // El catalogo inicial NO se carga aqui: con las reglas nuevas, escribir
  // _meta/catalogo y productos exige rol de Administrador, asi que
  // prepararCatalogo() corre dentro de AuthProvider.iniciarSesion(), una vez
  // que hay sesion. Llamarlo al arrancar daria permission-denied.
}

/// Inicializa Firebase sin tumbar la app si algo falta.
///
/// Si devuelve `false`, la app del telefono sigue abriendo con los datos
/// locales de MockData y el panel web muestra una pantalla explicando que
/// falta configurar, en vez de quedarse en blanco.
Future<bool> _iniciarFirebase() async {
  try {
    await FirebaseFerreteria.inicializar();
    debugPrint('✅ Firebase INICIALIZADO.');
    return true;
  } catch (e) {
    debugPrint('❌ Firebase NO se pudo inicializar: $e');
    debugPrint('👉 La app sigue abriendo con los datos locales (MockData).');
    return false;
  }
}
