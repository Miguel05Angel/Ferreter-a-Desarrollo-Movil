/// Validaciones reutilizables de toda la aplicacion.
class Validators {
  Validators._();

  static String? requerido(String? valor, [String? mensaje]) {
    if (valor == null || valor.trim().isEmpty) {
      return mensaje ?? 'Este campo es obligatorio';
    }
    return null;
  }

  static String? nombre(String? valor) {
    final base = requerido(valor, 'Ingresa el nombre');
    if (base != null) return base;
    if (valor!.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? email(String? valor) {
    final base = requerido(valor, 'Ingresa tu correo electronico');
    if (base != null) return base;
    final regex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(valor!.trim())) {
      return 'Ingresa un correo valido (ejemplo@correo.com)';
    }
    return null;
  }

  static String? password(String? valor) {
    final base = requerido(valor, 'Ingresa tu contrasena');
    if (base != null) return base;
    if (valor!.length < 6) {
      return 'La contrasena debe tener al menos 6 caracteres';
    }
    if (!valor.contains(RegExp(r'[0-9]'))) {
      return 'La contrasena debe incluir al menos un numero';
    }
    return null;
  }

  static String? confirmarPassword(String? valor, String passwordOriginal) {
    final base = requerido(valor, 'Confirma tu contrasena');
    if (base != null) return base;
    if (valor != passwordOriginal) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  static String? dni(String? valor) {
    final base = requerido(valor, 'Ingresa el DNI');
    if (base != null) return base;
    if (!RegExp(r'^\d{8}$').hasMatch(valor!.trim())) {
      return 'El DNI debe tener 8 digitos numericos';
    }
    return null;
  }

  static String? ruc(String? valor) {
    final base = requerido(valor, 'Ingresa el RUC');
    if (base != null) return base;
    if (!RegExp(r'^\d{11}$').hasMatch(valor!.trim())) {
      return 'El RUC debe tener 11 digitos numericos';
    }
    return null;
  }

  static String? telefono(String? valor) {
    final base = requerido(valor, 'Ingresa el numero de telefono');
    if (base != null) return base;
    if (!RegExp(r'^\d{9}$').hasMatch(valor!.trim())) {
      return 'El telefono debe tener 9 digitos (ej: 987654321)';
    }
    return null;
  }

  static String? telefonoOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    return telefono(valor);
  }

  static String? codigoProducto(String? valor) {
    final base = requerido(valor, 'Ingresa el codigo del producto');
    if (base != null) return base;
    if (valor!.trim().length < 3) {
      return 'El codigo debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? precio(String? valor) {
    final base = requerido(valor, 'Ingresa el precio');
    if (base != null) return base;
    final numero = double.tryParse(valor!.trim());
    if (numero == null) {
      return 'Ingresa un valor numerico valido';
    }
    if (numero <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    return null;
  }

  static String? precioOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    return precio(valor);
  }

  static String? stock(String? valor) {
    final base = requerido(valor, 'Ingresa el stock');
    if (base != null) return base;
    final numero = int.tryParse(valor!.trim());
    if (numero == null) {
      return 'Ingresa un numero entero valido';
    }
    if (numero < 0) {
      return 'El stock no puede ser negativo';
    }
    return null;
  }

  static String? cantidad(String? valor) {
    final base = requerido(valor, 'Ingresa la cantidad');
    if (base != null) return base;
    final numero = int.tryParse(valor!.trim());
    if (numero == null || numero <= 0) {
      return 'Ingresa una cantidad mayor a 0';
    }
    return null;
  }

  static String? direccion(String? valor) {
    final base = requerido(valor, 'Ingresa la direccion');
    if (base != null) return base;
    if (valor!.trim().length < 5) {
      return 'Ingresa una direccion mas completa';
    }
    return null;
  }
}
