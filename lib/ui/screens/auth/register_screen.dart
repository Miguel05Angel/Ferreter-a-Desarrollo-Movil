import 'package:flutter/material.dart';

import '../../../core/utils/formatos.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

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
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _cargando = false;
  late final _operacion = context.read<AuthProvider>().nuevaOperacion();

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_cargando || !_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().registrarVendedor(
            operacion: _operacion,
            nombre: _nombreController.text,
            dni: _dniController.text,
            telefono: _telefonoController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendedor registrado.')),
      );
      Navigator.of(context).pop();
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
    if (context.watch<AuthProvider>().usuarioActual?.rol != 'Administrador') {
      return const Scaffold(
        body: Center(child: Text('Acceso reservado al administrador.')),
      );
    }
    return Scaffold(
      appBar: const AppBarTaller(
          mostrarCarrito: false,
          subtitulo: 'Registro',
          title: Text('Registrar vendedor')),
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
                  formateadores: Formatos.nombre(50),
                  validador: Validators.nombre,
                  capitalizacion: TextCapitalization.words,
                  ayuda: 'Ej: Carlos Huaman',
                ),
              ),
              const SizedBox(height: 18),
              FadeSlide(
                delay: const Duration(milliseconds: 80),
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
                delay: const Duration(milliseconds: 160),
                child: CustomTextField(
                  etiqueta: 'Telefono',
                  icono: Icons.phone_outlined,
                  controlador: _telefonoController,
                  formateadores: Formatos.digitos(9),
                  tipoTeclado: TextInputType.phone,
                  validador: Validators.telefono,
                  ayuda: '9 digitos, ej: 987654321',
                ),
              ),
              const SizedBox(height: 18),
              FadeSlide(
                delay: const Duration(milliseconds: 240),
                child: PasswordField(
                  etiqueta: 'Contraseña',
                  controlador: _passwordController,
                  validador: Validators.password,
                  ayuda: 'Minimo 6 caracteres y un numero',
                ),
              ),
              const SizedBox(height: 18),
              FadeSlide(
                delay: const Duration(milliseconds: 320),
                child: PasswordField(
                  etiqueta: 'Confirmar contraseña',
                  controlador: _confirmarController,
                  validador: (v) =>
                      Validators.confirmarPassword(v, _passwordController.text),
                ),
              ),
              const SizedBox(height: 30),
              FadeSlide(
                delay: const Duration(milliseconds: 400),
                child: AnimatedButton(
                  texto: 'Registrar vendedor',
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
