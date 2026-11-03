import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../buttons/animated_button.dart';
import '../visual/decor_industrial.dart';
import 'success_dialog.dart';

/// Un campo que cambio durante la edicion.
class CambioCampo {
  final String campo;
  final String antes;
  final String despues;

  const CambioCampo(this.campo, this.antes, this.despues);
}

/// Utilidades para comparar valores al editar y construir la lista de
/// cambios.
class ComparadorCambios {
  final List<CambioCampo> cambios = [];

  String _vacio(String v) => v.trim().isEmpty ? '(vacio)' : v.trim();

  void texto(String campo, String antes, String despues) {
    if (antes.trim() != despues.trim()) {
      cambios.add(CambioCampo(campo, _vacio(antes), _vacio(despues)));
    }
  }

  void numero(String campo, num antes, String despues, {int decimales = 2}) {
    final nuevo = double.tryParse(despues.trim().replaceAll(',', '.'));
    if (nuevo == null || (nuevo - antes).abs() > 0.0001) {
      final a = decimales == 0
          ? antes.toStringAsFixed(0)
          : antes.toStringAsFixed(decimales);
      cambios.add(CambioCampo(campo, a, _vacio(despues)));
    }
  }
}

class EdicionFlow {
  EdicionFlow._();

  /// Pregunta si los datos son correctos. Devuelve true si el usuario
  /// confirma ("Si, estoy seguro") y false si prefiere revisar.
  static Future<bool> confirmar(
    BuildContext context, {
    required String entidad,
    required List<CambioCampo> cambios,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoConfirmar(entidad: entidad, cambios: cambios),
    );
    return r ?? false;
  }

  /// Mensaje animado de exito (reemplaza a la notificacion verde).
  static Future<void> exito(
    BuildContext context, {
    required String titulo,
    required String mensaje,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialog(
        titulo: titulo,
        mensaje: mensaje,
        textoBoton: 'Listo',
      ),
    );
  }
}

class _DialogoConfirmar extends StatelessWidget {
  final String entidad;
  final List<CambioCampo> cambios;

  const _DialogoConfirmar({required this.entidad, required this.cambios});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final gris = Colors.grey.shade600;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaPeligro(alto: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const ShapeDecoration(
                        color: AppTheme.primary,
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(12)),
                        ),
                      ),
                      child: const Icon(Icons.fact_check_outlined,
                          color: AppTheme.grafito, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'LOS DATOS SON\nCORRECTOS?',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Vas a modificar $entidad. Revisa los cambios antes de guardar.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: gris),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < cambios.length; i++)
                          _FilaCambio(cambios[i], oscuro: oscuro, indice: i),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedButton(
                  texto: 'Si, estoy seguro',
                  icono: Icons.check,
                  ancho: double.infinity,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('NO, VOY A REVISAR'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCambio extends StatelessWidget {
  final CambioCampo cambio;
  final bool oscuro;
  final int indice;

  const _FilaCambio(this.cambio, {required this.oscuro, required this.indice});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + indice * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        decoration: BoxDecoration(
          color: oscuro ? const Color(0xFF12161A) : const Color(0xFFF4F1EA),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            left: const BorderSide(color: AppTheme.primary, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cambio.campo.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cambio.antes,
              style: TextStyle(
                fontSize: 13,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey.shade500,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.subdirectory_arrow_right,
                    size: 15, color: AppTheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cambio.despues,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Zona de botones de un formulario.
/// - Al crear: boton de registrar.
/// - Al editar sin cambios: solo "Cancelar".
/// - Al editar con cambios: "Guardar cambios" y "Cancelar".
class AccionesFormulario extends StatelessWidget {
  final bool esEdicion;
  final bool hayCambios;
  final bool cargando;
  final String textoRegistrar;
  final VoidCallback onGuardar;

  const AccionesFormulario({
    super.key,
    required this.esEdicion,
    required this.hayCambios,
    required this.cargando,
    required this.textoRegistrar,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    final cancelar = SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: cargando ? null : () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close, size: 18),
        label: const Text('CANCELAR'),
      ),
    );

    if (!esEdicion) {
      return AnimatedButton(
        texto: textoRegistrar,
        icono: Icons.save_outlined,
        cargando: cargando,
        onPressed: onGuardar,
        ancho: double.infinity,
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: hayCambios
            ? Column(
                key: const ValueKey('cambios'),
                children: [
                  AnimatedButton(
                    texto: 'Guardar cambios',
                    icono: Icons.save_outlined,
                    cargando: cargando,
                    onPressed: onGuardar,
                    ancho: double.infinity,
                  ),
                  const SizedBox(height: 4),
                  cancelar,
                ],
              )
            : Column(
                key: const ValueKey('sin'),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'SIN CAMBIOS POR GUARDAR',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  cancelar,
                ],
              ),
      ),
    );
  }
}
