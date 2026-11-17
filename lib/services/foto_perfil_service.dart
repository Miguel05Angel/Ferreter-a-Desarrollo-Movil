import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show compute, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Prepara una foto pequeña para guardarla en el perfil de Firestore.
class FotoPerfilService {
  FotoPerfilService._();
  static final instance = FotoPerfilService._();
  static const maxBytes = 180 * 1024;

  final _picker = ImagePicker();
  XFile? _recuperada;

  static bool get permiteCamara =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> recuperarPendiente() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final resultado = await _picker.retrieveLostData();
      if (resultado.files?.isNotEmpty ?? false) {
        _recuperada = resultado.files!.first;
      }
    } catch (_) {
      // Un error del selector no impide abrir la app.
    }
  }

  Future<Uint8List?> consumirRecuperada() async {
    final archivo = _recuperada;
    if (archivo == null) return null;
    final foto = await _preparar(archivo);
    _recuperada = null;
    return foto;
  }

  Future<Uint8List?> seleccionar(ImageSource origen) async {
    final archivo = await _picker.pickImage(
      source: origen,
      maxWidth: 960,
      maxHeight: 960,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    return archivo == null ? null : _preparar(archivo);
  }

  Future<Uint8List> _preparar(XFile archivo) async {
    if (await archivo.length() > 20 * 1024 * 1024) {
      throw const FormatException('Elige una imagen de menos de 20 MB.');
    }
    return compute(comprimirFotoPerfil, await archivo.readAsBytes());
  }
}

Uint8List comprimirFotoPerfil(Uint8List bytes) {
  final decodificada = img.decodeImage(bytes);
  if (decodificada == null) {
    throw const FormatException(
        'No se pudo leer la foto. Prueba con una imagen JPG o PNG.');
  }
  final orientada = img.bakeOrientation(decodificada);
  final imagen = orientada.width > 960 || orientada.height > 960
      ? img.copyResize(
          orientada,
          width: orientada.width >= orientada.height ? 960 : null,
          height: orientada.height > orientada.width ? 960 : null,
        )
      : orientada;
  for (final calidad in [80, 60, 40]) {
    final foto = img.encodeJpg(imagen, quality: calidad);
    if (foto.length <= FotoPerfilService.maxBytes) return foto;
  }
  throw const FormatException(
      'La foto pesa demasiado. Prueba con otra imagen.');
}
