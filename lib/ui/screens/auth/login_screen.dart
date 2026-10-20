import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/encabezado_taller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = auth.iniciarSesion(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _cargando = false);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales incorrectas. Verifica tu correo y contrasena.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado con plano tecnico y engranaje 3D
            const EncabezadoTaller(subtitulo: 'Ferreteria - Acceso'),
            const FranjaPeligro(alto: 10),

            // Formulario
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    FadeSlide(
                      delay: const Duration(milliseconds: 100),
                      child: CustomTextField(
                        etiqueta: 'Correo electronico',
                        icono: Icons.email_outlined,
                        controlador: _emailController,
                        tipoTeclado: TextInputType.emailAddress,
                        validador: Validators.email,
                        ayuda: 'ejemplo@correo.com',
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlide(
                      delay: const Duration(milliseconds: 200),
                      child: PasswordField(
                        etiqueta: 'Contrasena',
                        controlador: _passwordController,
                        validador: Validators.password,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlide(
                      delay: const Duration(milliseconds: 300),
                      child: AnimatedButton(
                        texto: 'Iniciar sesion',
                        icono: Icons.login,
                        cargando: _cargando,
                        onPressed: _iniciarSesion,
                        ancho: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlide(
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes una cuenta?',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.register),
                            child: const Text('Registrate'),
                          ),
                        ],
                      ),
                    ),
                    FadeSlide(
                      delay: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Demo: admin@ferreteria.com / admin123',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
