import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String dni;
  final String nombre;
  final String telefono;
  final String rol;
  final Uint8List? fotoPerfil;

  const Usuario({
    required this.id,
    required this.dni,
    required this.nombre,
    required this.telefono,
    required this.rol,
    this.fotoPerfil,
  });

  factory Usuario.desdeFirestore(String id, Map<String, dynamic> datos) {
    return Usuario(
      id: id,
      dni: datos['dni'] as String? ?? '',
      nombre: datos['nombre'] as String? ?? '',
      telefono: datos['telefono'] as String? ?? '',
      rol: datos['rol'] as String? ?? '',
      fotoPerfil: datos['fotoPerfil'] is Blob
          ? (datos['fotoPerfil'] as Blob).bytes
          : null,
    );
  }

  Usuario copyWith({
    String? nombre,
    Uint8List? fotoPerfil,
    bool quitarFoto = false,
  }) =>
      Usuario(
        id: id,
        dni: dni,
        nombre: nombre ?? this.nombre,
        telefono: telefono,
        rol: rol,
        fotoPerfil: quitarFoto ? null : fotoPerfil ?? this.fotoPerfil,
      );
}
