import 'package:flutter/material.dart';

import '../../../core/utils/formatos.dart';
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
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_cargando || !_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().iniciarSesion(
            _dniController.text,
            _passwordController.text,
          );
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    } on AuthError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.mensaje)),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
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
                        etiqueta: 'DNI',
                        icono: Icons.badge_outlined,
                        controlador: _dniController,
                        formateadores: Formatos.digitos(8),
                        tipoTeclado: TextInputType.number,
                        validador: Validators.dni,
                        ayuda: '8 dígitos',
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlide(
                      delay: const Duration(milliseconds: 200),
                      child: PasswordField(
                        etiqueta: 'Contraseña',
                        controlador: _passwordController,
                        validador: Validators.requerido,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlide(
                      delay: const Duration(milliseconds: 300),
                      child: AnimatedButton(
                        texto: 'Iniciar sesión',
                        icono: Icons.login,
                        cargando: _cargando,
                        onPressed: _iniciarSesion,
                        ancho: double.infinity,
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
