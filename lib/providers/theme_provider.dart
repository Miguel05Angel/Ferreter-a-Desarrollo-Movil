import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get esModoOscuro => _themeMode == ThemeMode.dark;

  void alternarTema(bool oscuro) {
    _themeMode = oscuro ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
