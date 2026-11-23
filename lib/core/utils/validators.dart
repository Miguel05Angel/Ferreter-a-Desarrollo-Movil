/// Validaciones reutilizables de toda la aplicación.
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
    final base = requerido(valor, 'Ingresa tu correo electrónico');
    if (base != null) return base;
    final regex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(valor!.trim())) {
      return 'Ingresa un correo válido (ejemplo@correo.com)';
    }
    return null;
  }

  static String? password(String? valor) {
    final base = requerido(valor, 'Ingresa tu contraseña');
    if (base != null) return base;
    if (valor!.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (!valor.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe incluir al menos un número';
    }
    return null;
  }

  static String? confirmarPassword(String? valor, String passwordOriginal) {
    final base = requerido(valor, 'Confirma tu contraseña');
    if (base != null) return base;
    if (valor != passwordOriginal) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? dni(String? valor) {
    final base = requerido(valor, 'Ingresa el DNI');
    if (base != null) return base;
    if (!RegExp(r'^\d{8}$').hasMatch(valor!.trim())) {
      return 'El DNI debe tener 8 dígitos numéricos';
    }
    if (valor.trim() == '00000000') {
      return 'Ingresa un DNI válido';
    }
    return null;
  }

  static String? ruc(String? valor) {
    final base = requerido(valor, 'Ingresa el RUC');
    if (base != null) return base;
    if (!RegExp(r'^\d{11}$').hasMatch(valor!.trim())) {
      return 'El RUC debe tener 11 dígitos numéricos';
    }
    if (!RegExp(r'^(10|15|16|17|20)').hasMatch(valor.trim())) {
      return 'El RUC debe empezar con 10 o 20';
    }
    return null;
  }

  static String? telefono(String? valor) {
    final base = requerido(valor, 'Ingresa el número de teléfono');
    if (base != null) return base;
    if (!RegExp(r'^9\d{8}$').hasMatch(valor!.trim())) {
      return 'El celular debe tener 9 dígitos y empezar con 9 (ej: 987654321)';
    }
    return null;
  }

  static String? telefonoOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    return telefono(valor);
  }

  static String? codigoProducto(String? valor) {
    final base = requerido(valor, 'Ingresa el código del producto');
    if (base != null) return base;
    if (valor!.trim().length < 3) {
      return 'El código debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? precio(String? valor) {
    final base = requerido(valor, 'Ingresa el precio');
    if (base != null) return base;
    final numero = double.tryParse(valor!.trim());
    if (numero == null) {
      return 'Ingresa un valor numérico válido';
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
      return 'Ingresa un número entero válido';
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
    final base = requerido(valor, 'Ingresa la dirección');
    if (base != null) return base;
    if (valor!.trim().length < 5) {
      return 'Ingresa una dirección más completa';
    }
    return null;
  }
}
