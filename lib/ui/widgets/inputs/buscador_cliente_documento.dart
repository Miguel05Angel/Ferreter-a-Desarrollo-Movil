import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/cliente.dart';
import '../../../providers/cliente_provider.dart';
import '../cotizacion/perfil_cliente_sheet.dart';

/// Campo "Buscar por DNI o RUC" para elegir el cliente de una cotizacion.
/// Valida la longitud (8 = DNI, 11 = RUC) y el formato mientras se escribe;
/// con un documento valido muestra al cliente con una animacion de entrada.
/// Tocar su nombre o RUC abre su perfil completo.
class BuscadorClienteDocumento extends StatefulWidget {
  /// Se llama con el id del cliente cuando el usuario lo elige.
  final ValueChanged<String> onUsar;

  /// Crear un cliente nuevo (cuando el documento no existe).
  final VoidCallback onCrear;

  const BuscadorClienteDocumento({
    super.key,
    required this.onUsar,
    required this.onCrear,
  });

  @override
  State<BuscadorClienteDocumento> createState() =>
      _BuscadorClienteDocumentoState();
}

class _BuscadorClienteDocumentoState extends State<BuscadorClienteDocumento> {
  final _c = TextEditingController();
  String? _error;
  String? _ayuda;
  Cliente? _hallado;
  bool _noExiste = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _cambio(String valor) {
    final t = valor.trim();
    String? error;
    String? ayuda;
    Cliente? hallado;
    var noExiste = false;

    if (t.isEmpty) {
      ayuda = null;
    } else if (t.length < 8) {
      ayuda = 'DNI: 8 dígitos  |  RUC: 11 dígitos  (${t.length})';
    } else if (t.length == 8) {
      error = Validators.dni(t);
    } else if (t.length < 11) {
      error = 'Tiene ${t.length} dígitos: usa 8 (DNI) u 11 (RUC)';
    } else {
      error = Validators.ruc(t);
    }

    if (error == null && (t.length == 8 || t.length == 11)) {
      for (final x in context.read<ClienteProvider>().clientes) {
        if (x.documento == t) {
          hallado = x;
          break;
        }
      }
      noExiste = hallado == null;
    }
    setState(() {
      _error = error;
      _ayuda = ayuda;
      _hallado = hallado;
      _noExiste = noExiste;
    });
  }

  void _limpiar() {
    _c.clear();
    _cambio('');
  }

  void _usar(Cliente c) {
    widget.onUsar(c.id);
    _limpiar();
    FocusScope.of(context).unfocus();
  }

  Widget _resultado() {
    final h = _hallado;
    if (h != null) {
      final color =
          h.tipoDocumento == 'RUC' ? const Color(0xFF0277BD) : AppTheme.primary;
      return Container(
        key: ValueKey('hallado-${h.id}'),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.7), width: 1.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => PerfilClienteSheet.mostrar(context,
                    cliente: h, onUsar: () => widget.onUsar(h.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dotted)),
                      const SizedBox(height: 3),
                      Text(
                        '${h.tipoDocumento} ${h.documento}'
                        '${h.telefono.isEmpty ? '' : '  |  Tel. ${h.telefono}'}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                      const SizedBox(height: 3),
                      Text('Toca para ver el perfil completo',
                          style: TextStyle(
                              fontSize: 10.8, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _usar(h),
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              child: const Text('USAR'),
            ),
          ],
        ),
      );
    }
    if (_noExiste) {
      final tipo = _c.text.trim().length == 11 ? 'RUC' : 'DNI';
      return Container(
        key: const ValueKey('no-existe'),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.amarilloSenal.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.amarilloSenal.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_off_outlined, color: Color(0xFF9A6B00)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('No hay un cliente con $tipo ${_c.text.trim()}.',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            TextButton(onPressed: widget.onCrear, child: const Text('CREAR')),
          ],
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('vacio'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _c,
          keyboardType: TextInputType.number,
          inputFormatters: Formatos.digitos(11),
          onChanged: _cambio,
          decoration: InputDecoration(
            hintText: 'Buscar por DNI o RUC',
            prefixIcon: const Icon(Icons.badge_outlined),
            errorText: _error,
            helperText: _ayuda,
            suffixIcon: _c.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.clear), onPressed: _limpiar),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            transitionBuilder: (w, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.18), end: Offset.zero)
                    .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: w,
              ),
            ),
            child: _resultado(),
          ),
        ),
      ],
    );
  }
}
