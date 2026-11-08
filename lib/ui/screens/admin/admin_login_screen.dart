import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

/// Acceso al panel web con el mismo DNI y contrasena que la app del telefono.
///
/// Reusa AuthProvider.iniciarSesion(), que ya traduce el DNI al correo
/// interno y comprueba el perfil en la coleccion usuarios.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _dni = TextEditingController();
  final _password = TextEditingController();

  bool _cargando = false;
  bool _verPassword = false;
  String? _error;

  @override
  void dispose() {
    _dni.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().iniciarSesion(
            _dni.text.trim(),
            _password.text,
          );
      // Si sale bien no hace falta navegar: _PuertaAdmin escucha el provider
      // y cambia sola a la pantalla del panel.
    } on AuthError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo entrar. Intentalo de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.handyman, size: 44),
                      const SizedBox(height: 16),
                      Text(
                        'El Constructor',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Panel administrativo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _dni,
                        decoration: const InputDecoration(
                          labelText: 'DNI',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        autofillHints: const [AutofillHints.username],
                        validator: (v) {
                          final dni = (v ?? '').trim();
                          if (dni.isEmpty) return 'Escribe tu DNI';
                          if (dni.length != 8) return 'El DNI tiene 8 digitos';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_verPassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _verPassword = !_verPassword),
                          ),
                        ),
                        obscureText: !_verPassword,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _cargando ? null : _entrar(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Escribe tu contrasena'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _cargando ? null : _entrar,
                        child: _cargando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Solo cuentas con rol Administrador pueden gestionar '
                        'el catalogo desde aqui.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
