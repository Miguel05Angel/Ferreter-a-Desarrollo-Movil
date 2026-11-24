import 'package:ferreteria_app/providers/auth_provider.dart';
import 'package:ferreteria_app/ui/screens/perfil/password_usuario_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'usuarios_edicion_test.dart' as fixtures;

class SesionPassword extends fixtures.SesionPrueba {
  SesionPassword(super.usuarioActual);
  int cambios = 0;
  String? destino;
  String? fallo;
  @override
  Future<void> cambiarMiPassword(
      {required String passwordActual, required String nuevaPassword}) async {
    if (fallo != null) throw AuthError(fallo!);
    cambios++;
    destino = usuarioActual!.id;
  }

  @override
  Future<void> restablecerPasswordUsuario(
      {required String usuarioId,
      required String passwordActual,
      required String nuevaPassword}) async {
    if (fallo != null) throw AuthError(fallo!);
    cambios++;
    destino = usuarioId;
  }
}

void main() {
  testWidgets('Solo administradores acceden a las contraseñas', (tester) async {
    for (final usuario in [fixtures.vendedor, null]) {
      await tester.pumpWidget(fixtures.app(SesionPassword(usuario),
          const PasswordUsuarioScreen(usuario: fixtures.vendedor)));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Acceso reservado al administrador.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('El formulario propio confirma y cambia la contraseña',
      (tester) async {
    final sesion = SesionPassword(fixtures.administrador);
    await tester.pumpWidget(fixtures.app(
        sesion, const PasswordUsuarioScreen(usuario: fixtures.administrador)));
    await tester.pumpAndSettle();
    final campos = find.byType(TextFormField);
    expect(campos, findsNWidgets(3));
    for (final field in tester.widgetList<EditableText>(find.byType(EditableText))) {
      expect(field.obscureText, isTrue);
    }
    await tester.enterText(campos.at(0), 'Anterior123');
    await tester.enterText(campos.at(1), 'Nueva456');
    await tester.enterText(campos.at(2), 'Diferente789');
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(sesion.cambios, 0);
    expect(find.text('Las contrasenas no coinciden'), findsOneWidget);
    await tester.enterText(campos.at(2), 'Nueva456');
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(sesion.destino, fixtures.administrador.id);
  });

  testWidgets('Restablecimiento usa la cuenta seleccionada y muestra errores',
      (tester) async {
    final sesion = SesionPassword(fixtures.administrador)
      ..fallo = 'Contraseña del administrador incorrecta.';
    await tester.pumpWidget(fixtures.app(
        sesion, const PasswordUsuarioScreen(usuario: fixtures.vendedor)));
    await tester.pumpAndSettle();
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Incorrecta123');
    await tester.enterText(campos.at(1), 'Nueva456');
    await tester.enterText(campos.at(2), 'Nueva456');
    await tester.tap(find.descendant(
      of: find.byWidgetPredicate((w) => w is FilledButton),
      matching: find.text('Restablecer contraseña'),
    ));
    await tester.pumpAndSettle();
    expect(sesion.cambios, 0);
    expect(find.text(sesion.fallo!), findsOneWidget);
    sesion.fallo = null;
    await tester.enterText(campos.at(0), 'Admin123');
    await tester.tap(find.descendant(
      of: find.byWidgetPredicate((w) => w is FilledButton),
      matching: find.text('Restablecer contraseña'),
    ));
    await tester.pumpAndSettle();
    expect(sesion.cambios, 1);
    expect(sesion.destino, fixtures.vendedor.id);
  });
}
