import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/inputs/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final ok = context.read<AuthProvider>().registrar(
          nombre: _nombreController.text,
          email: _emailController.text,
          telefono: _telefonoController.text,
          password: _passwordController.text,
        );

    setState(() => _cargando = false);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe una cuenta registrada con este correo.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FadeSlide(
                child: CustomTextField(
                  etiqueta: 'Nombre completo',
                  icono: Icons.person_outline,
                  controlador: _nombreController,
                  validador: Validators.nombre,
                  capitalizacion: TextCapitalization.words,
                  ayuda: 'Ej: Carlos Huaman',
                ),
              ),
              const SizedBox(height: 18),
              FadeSlide(
                delay: const Duration(milliseconds: 80),
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
                delay: const Duration(milliseconds: 160),
                child: CustomTextField(
                  etiqueta: 'Telefono',
                  icono: Icons.phone_outlined,
                  controlador: _telefonoController,
                  tipoTeclado: TextInputType.phone,
                  validador: Validators.telefono,
                  ayuda: '9 digitos, ej: 987654321',
                ),
              ),
              const SizedBox(height: 18),
              FadeSlide(
                delay: const Duration(milliseconds: 240),
                child: PasswordField(
                  etiqueta: 'Contrasena',
                  controlador: _passwordController,
                  validador: Validators.password,
                  ayuda: 'Minimo 6 caracteres y un numero',
                ),
              ),
              const SizedBox(height: 18),
              FadeSlide(
                delay: const Duration(milliseconds: 320),
                child: PasswordField(
                  etiqueta: 'Confirmar contrasena',
                  controlador: _confirmarController,
                  validador: (v) => Validators.confirmarPassword(
                      v, _passwordController.text),
                ),
              ),
              const SizedBox(height: 30),
              FadeSlide(
                delay: const Duration(milliseconds: 400),
                child: AnimatedButton(
                  texto: 'Registrarme',
                  icono: Icons.person_add_alt,
                  cargando: _cargando,
                  onPressed: _registrar,
                  ancho: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
