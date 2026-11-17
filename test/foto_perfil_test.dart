import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferreteria_app/data/models/usuario.dart';
import 'package:ferreteria_app/services/foto_perfil_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('La foto conserva proporciones y cabe en el perfil de Firestore', () {
    final original = img.Image(width: 1200, height: 600);
    final foto = comprimirFotoPerfil(img.encodePng(original));
    final resultado = img.decodeJpg(foto)!;
    expect(resultado.width, 960);
    expect(resultado.height, 480);
    expect(foto.length, lessThanOrEqualTo(FotoPerfilService.maxBytes));
  });

  test('Rechaza archivos que no son imágenes', () {
    expect(
      () => comprimirFotoPerfil(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });

  test('El perfil conserva la foto al editar el nombre y permite quitarla', () {
    final antiguo = Usuario.desdeFirestore('u-1', {'nombre': 'Mirko'});
    expect(antiguo.fotoPerfil, isNull);
    final bytes = img.encodeJpg(img.Image(width: 4, height: 4));
    final cargado = Usuario.desdeFirestore('u-1', {
      'nombre': 'Mirko',
      'fotoPerfil': Blob(bytes),
    });
    expect(cargado.fotoPerfil, orderedEquals(bytes));
    expect(cargado.copyWith(nombre: 'Mirko Raymundo').fotoPerfil,
        orderedEquals(bytes));
    final sinFoto = cargado.copyWith(quitarFoto: true);
    expect(sinFoto.fotoPerfil, isNull);
  });
}
