import 'package:flutter/material.dart';

import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/register_screen.dart';
import '../../ui/screens/main/main_shell_screen.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/screens/welcome/welcome_screen.dart';

/// Rutas con transicion animada (desvanecido + deslizamiento suave).
class FadeRoute<T> extends MaterialPageRoute<T> {
  FadeRoute({required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return FadeRoute(builder: (_) => const SplashScreen());
      case welcome:
        return FadeRoute(builder: (_) => const WelcomeScreen());
      case login:
        return FadeRoute(builder: (_) => const LoginScreen());
      case register:
        return FadeRoute(builder: (_) => const RegisterScreen());
      case main:
        return FadeRoute(builder: (_) => const MainShellScreen());
      default:
        return FadeRoute(builder: (_) => const SplashScreen());
    }
  }

  /// Atajo para navegar con animacion desde cualquier parte de la app.
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push(FadeRoute<T>(builder: (_) => page));
  }
}
