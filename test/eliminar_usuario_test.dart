import 'package:ferreteria_app/providers/auth_provider.dart';
import 'package:ferreteria_app/ui/screens/perfil/eliminar_usuario_screen.dart';
import 'package:ferreteria_app/ui/screens/perfil/usuarios_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'usuarios_edicion_test.dart' as fixtures;

class SesionEliminar extends fixtures.SesionPrueba {
  SesionEliminar(super.usuarioActual);
  String? eliminado;
  String? fallo;
  @override
  Future<void> eliminarUsuario(
      {required String usuarioId, required String passwordActual}) async {
    if (fallo != null) throw AuthError(fallo!);
    eliminado = usuarioId;
  }
}

void main() {
  testWidgets('No pueden eliminar vendedores, visitantes ni la cuenta propia',
      (tester) async {
    for (final actual in [fixtures.vendedor, null, fixtures.administrador]) {
      await tester.pumpWidget(fixtures.app(
          SesionEliminar(actual),
          EliminarUsuarioScreen(
              usuario: actual == fixtures.administrador
                  ? fixtures.administrador
                  : fixtures.vendedor)));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Eliminar definitivamente'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('El menú abre eliminación y exige confirmar DNI y contraseña',
      (tester) async {
    final sesion = SesionEliminar(fixtures.administrador);
    await tester.pumpWidget(fixtures.app(sesion, const UsuariosScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opciones de usuario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar usuario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar definitivamente'));
    await tester.pumpAndSettle();
    expect(sesion.eliminado, isNull);
    expect(find.text('El DNI no coincide con la cuenta seleccionada.'),
        findsOneWidget);
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), fixtures.vendedor.dni);
    await tester.enterText(campos.at(1), 'PruebaAdmin123');
    sesion.fallo = 'La contraseña actual es incorrecta.';
    await tester.tap(find.text('Eliminar definitivamente'));
    await tester.pumpAndSettle();
    expect(sesion.eliminado, isNull);
    expect(find.text(sesion.fallo!), findsOneWidget);
    sesion.fallo = null;
    await tester.tap(find.text('Eliminar definitivamente'));
    await tester.pumpAndSettle();
    expect(sesion.eliminado, fixtures.vendedor.id);
    expect(find.text('Usuarios'), findsOneWidget);
  });
}
