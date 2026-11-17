import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../../../services/foto_perfil_service.dart';
import '../../../providers/auth_provider.dart' show AuthError;

class EditorFotoPerfil extends StatefulWidget {
  final Uint8List? foto;
  final bool habilitado;
  final Future<void> Function(Uint8List?) onGuardar;

  const EditorFotoPerfil({
    super.key,
    required this.foto,
    required this.onGuardar,
    this.habilitado = true,
  });

  @override
  State<EditorFotoPerfil> createState() => _EditorFotoPerfilState();
}

class _EditorFotoPerfilState extends State<EditorFotoPerfil> {
  final _servicio = FotoPerfilService.instance;
  bool _procesando = false;
  bool _guardando = false;
  Uint8List? _foto;

  @override
  void initState() {
    super.initState();
    _foto = widget.foto;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recuperar());
  }

  Future<void> _recuperar() async {
    if (!mounted) return;
    setState(() => _procesando = true);

    try {
      final foto = await _servicio.consumirRecuperada();
      if (!mounted || foto == null) return;
      setState(() => _foto = foto);
      _avisar(
          'Se recuperó una foto pendiente. Revísala antes de guardar tu perfil.');
    } catch (_) {
      if (mounted) _avisar('No se pudo recuperar la foto pendiente.');
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _guardar() async {
    if (_procesando || _guardando) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(_foto);
      if (mounted) Navigator.of(context).pop(true);
    } on AuthError catch (error) {
      if (mounted) _avisar(error.mensaje);
    } catch (_) {
      if (mounted) {
        _avisar(
            'No se pudo guardar tu foto. Revisa la conexión y los permisos del perfil.');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _elegir(ImageSource origen) async {
    if (_procesando || _guardando || !widget.habilitado) return;
    setState(() => _procesando = true);

    try {
      final foto = await _servicio.seleccionar(origen);
      if (mounted && foto != null) setState(() => _foto = foto);
    } on PlatformException catch (error) {
      if (!mounted) return;
      _avisar(switch (error.code) {
        'camera_access_denied' ||
        'camera_access_denied_without_prompt' ||
        'camera_access_restricted' =>
          'Permite el acceso a la cámara en los ajustes de la aplicación.',
        'photo_access_denied' ||
        'photo_access_denied_without_prompt' ||
        'photo_access_restricted' =>
          'Permite el acceso a las fotos en los ajustes de la aplicación.',
        _ => 'No se pudo abrir la cámara o la galería. Inténtalo nuevamente.',
      });
    } on FormatException catch (error) {
      if (mounted) _avisar(error.message);
    } catch (_) {
      if (mounted) {
        _avisar('No se pudo preparar la foto. Prueba con otra imagen.');
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponible = widget.habilitado && !_procesando && !_guardando;
    return PopScope(
      canPop: !_guardando && !_procesando,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Foto de perfil',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: Center(
                    child: ClipOval(
                        child: SizedBox(
                  width: 160,
                  height: 160,
                  child: _foto == null
                      ? const Center(
                          child: Icon(Icons.add_photo_alternate_outlined,
                              size: 54))
                      : Image.memory(
                          _foto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child:
                                  Icon(Icons.broken_image_outlined, size: 48)),
                        ),
                ))),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (FotoPerfilService.permiteCamara)
                    OutlinedButton.icon(
                      onPressed:
                          disponible ? () => _elegir(ImageSource.camera) : null,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Tomar foto'),
                    ),
                  OutlinedButton.icon(
                    onPressed:
                        disponible ? () => _elegir(ImageSource.gallery) : null,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Elegir de galería'),
                  ),
                  if (_foto != null)
                    TextButton.icon(
                      onPressed: disponible
                          ? () => setState(() => _foto = null)
                          : null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Quitar foto'),
                    ),
                ],
              ),
              if (_procesando) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 8),
              const Text('El cambio se guardará en tu cuenta al confirmar.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: disponible ? _guardar : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(_guardando ? 'Guardando…' : 'Guardar foto'),
              ),
              TextButton(
                onPressed:
                    disponible ? () => Navigator.of(context).pop(false) : null,
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
