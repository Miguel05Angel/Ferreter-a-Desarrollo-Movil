import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/carrito_provider.dart';
import 'providers/cliente_provider.dart';
import 'providers/cotizacion_borrador_provider.dart';
import 'providers/cotizacion_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/proveedor_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/compra_provider.dart';
import 'providers/faltante_provider.dart';
import 'providers/media_provider.dart';
import 'providers/venta_provider.dart';
import 'ui/widgets/carrito/carrito_flotante.dart';
import 'ui/widgets/cotizacion/guardia_cotizacion.dart';

class FerreteriaApp extends StatelessWidget {
  const FerreteriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProductoProvider>(
          create: (_) => ProductoProvider(),
          update: (_, auth, productos) => productos!..actualizarSesion(auth.usuarioActual),
        ),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ProveedorProvider()),
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProxyProvider<AuthProvider, VentaProvider>(
          create: (_) => VentaProvider(),
          update: (_, auth, ventas) => ventas!..actualizarSesion(auth.usuarioActual),
        ),
        ChangeNotifierProvider(create: (_) => CotizacionProvider()),
        ChangeNotifierProvider(create: (_) => CotizacionBorradorProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()..cargar()),
        ChangeNotifierProvider(create: (_) => CompraProvider()),
        ChangeNotifierProvider(create: (_) => FaltanteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navegadorGlobal,
            title: 'Ferreteria El Constructor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: (context, child) =>
                GuardiaCotizacion(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
