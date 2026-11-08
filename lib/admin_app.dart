import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/admin/admin_dashboard_screen.dart';

/// Raiz de la version web: el panel administrativo.
///
/// La app del telefono (FerreteriaApp) no se toca. Las dos comparten modelos,
/// tema y la misma base de datos en Firestore.
class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key, required this.firebaseListo});

  /// `false` cuando falta registrar la app Web en Firebase Console.
  final bool firebaseListo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Constructor - Panel administrativo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: firebaseListo
          ? const AdminDashboardScreen()
          : const _FirebaseSinConfigurar(),
    );
  }
}

/// Pantalla de ayuda cuando Firebase Web no esta configurado todavia.
///
/// Es mejor que una pantalla en blanco: dice exactamente que falta hacer.
class _FirebaseSinConfigurar extends StatelessWidget {
  const _FirebaseSinConfigurar();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Falta configurar Firebase para Web',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'El panel lee los productos desde Firestore, asi que '
                  'necesita una app Web registrada en el proyecto '
                  'ferreteria-app-16bde.',
                ),
                const SizedBox(height: 16),
                const _Paso(
                  numero: '1',
                  texto: 'Entra a console.firebase.google.com y abre el '
                      'proyecto ferreteria-app-16bde.',
                ),
                const _Paso(
                  numero: '2',
                  texto: 'Configuracion del proyecto > Agregar aplicacion > '
                      'Web, y ponle un apodo (por ejemplo admin-panel-web).',
                ),
                const _Paso(
                  numero: '3',
                  texto: 'En la terminal del proyecto ejecuta '
                      'flutterfire configure y vuelve a compilar.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.texto});

  final String numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text(numero)),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
