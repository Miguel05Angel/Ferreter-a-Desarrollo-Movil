import 'package:flutter/material.dart';

import 'app.dart';
import 'services/firebase_ferreteria.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseFerreteria.inicializar();
  runApp(const FerreteriaApp());
}
