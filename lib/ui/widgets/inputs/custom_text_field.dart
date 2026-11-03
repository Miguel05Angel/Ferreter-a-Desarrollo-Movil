import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto con estilo consistente y validacion integrada.
class CustomTextField extends StatelessWidget {
  final String etiqueta;
  final IconData? icono;
  final TextEditingController controlador;
  final String? Function(String?)? validador;
  final TextInputType tipoTeclado;
  final bool esPassword;
  final int lineas;
  final String? ayuda;
  final TextCapitalization capitalizacion;

  /// Limita lo que se puede escribir (solo digitos, maximo de caracteres...).
  final List<TextInputFormatter>? formateadores;

  const CustomTextField({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.icono,
    this.validador,
    this.tipoTeclado = TextInputType.text,
    this.esPassword = false,
    this.lineas = 1,
    this.ayuda,
    this.capitalizacion = TextCapitalization.none,
    this.formateadores,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          validator: validador,
          keyboardType: tipoTeclado,
          obscureText: esPassword,
          maxLines: esPassword ? 1 : lineas,
          textCapitalization: capitalizacion,
          inputFormatters: formateadores,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: ayuda,
            prefixIcon: icono != null ? Icon(icono, size: 22) : null,
          ),
        ),
      ],
    );
  }
}

/// Campo de contrasena con boton para mostrar/ocultar.
class PasswordField extends StatefulWidget {
  final String etiqueta;
  final TextEditingController controlador;
  final String? Function(String?)? validador;
  final String? ayuda;

  const PasswordField({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.validador,
    this.ayuda,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.etiqueta.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controlador,
          validator: widget.validador,
          obscureText: _oculto,
          inputFormatters: [LengthLimitingTextInputFormatter(20)],
          decoration: InputDecoration(
            hintText: widget.ayuda,
            prefixIcon: const Icon(Icons.lock_outline, size: 22),
            suffixIcon: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _oculto ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  key: ValueKey(_oculto),
                  size: 22,
                ),
              ),
              onPressed: () => setState(() => _oculto = !_oculto),
            ),
          ),
        ),
      ],
    );
  }
}
