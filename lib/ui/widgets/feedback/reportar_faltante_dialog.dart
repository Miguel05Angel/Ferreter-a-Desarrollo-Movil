import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faltante_provider.dart';

/// Boton discreto para el borde del buscador: abre el reporte rapido.
class BotonReportarFaltante extends StatelessWidget {
  const BotonReportarFaltante({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => ReportarFaltanteDialog.mostrar(context),
        icon: const Icon(Icons.report_gmailerrorred_outlined, size: 17),
        label: const Text('¿No lo encuentras? Reportar'),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          foregroundColor: Colors.grey.shade600,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Reporte rapido de un articulo que no esta en el catalogo: 3 datos y un
/// boton. Aparece con escala + fade y, al guardar, muestra un check verde y
/// se cierra solo en menos de un segundo.
class ReportarFaltanteDialog extends StatefulWidget {
  const ReportarFaltanteDialog({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const ReportarFaltanteDialog(),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    );
  }

  @override
  State<ReportarFaltanteDialog> createState() => _ReportarFaltanteDialogState();
}

class _ReportarFaltanteDialogState extends State<ReportarFaltanteDialog> {
  final _k = GlobalKey<FormState>();
  final _producto = TextEditingController();
  final _marca = TextEditingController();
  String? _categoria;
  bool _errorCategoria = false;
  bool _guardado = false;

  @override
  void dispose() {
    _producto.dispose();
    _marca.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final valido = _k.currentState!.validate();
    if (_categoria == null) setState(() => _errorCategoria = true);
    if (!valido || _categoria == null) return;

    final usuario = context.read<AuthProvider>().usuarioActual?.nombre ?? 'Sin usuario';
    context.read<FaltanteProvider>().registrar(
          producto: _producto.text,
          marca: _marca.text,
          categoria: _categoria!,
          reportadoPor: usuario,
        );
    FocusScope.of(context).unfocus();
    setState(() => _guardado = true);
    await Future.delayed(const Duration(milliseconds: 850));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: _guardado
            ? const _Exito()
            : Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: SingleChildScrollView(
                  child: Form(
                    key: _k,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.report_gmailerrorred_outlined,
                                color: AppTheme.primary),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Reportar artículo faltante',
                                  style: TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w900)),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Ayúdanos a ampliar nuestro catálogo.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _producto,
                          autofocus: true,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                              labelText: 'Nombre del producto',
                              prefixIcon: Icon(Icons.inventory_2_outlined)),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.length < 3) return 'Escribe al menos 3 letras';
                            if (t.length > 60) return 'Máximo 60 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _marca,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Marca solicitada',
                              prefixIcon: Icon(Icons.sell_outlined)),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isNotEmpty && t.length < 2) return 'Muy corta';
                            if (t.length > 40) return 'Máximo 40 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('CATEGORÍA',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final c in FaltanteProvider.categorias)
                              ChoiceChip(
                                label: Text(c),
                                selected: _categoria == c,
                                onSelected: (_) => setState(() {
                                  _categoria = c;
                                  _errorCategoria = false;
                                }),
                              ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _errorCategoria
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('Elige una categoría',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade700)),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _guardar,
                            icon: const Icon(Icons.send_outlined),
                            label: const Text('Guardar y enviar reporte'),
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Exito extends StatelessWidget {
  const _Exito();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: const CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.success,
                child: Icon(Icons.check, color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Reporte enviado',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
