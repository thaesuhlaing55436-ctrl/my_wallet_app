import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class ThemeController extends Cubit<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  bool get isDarkMode => state == ThemeMode.dark;

  ThemeMode get themeMode => state;

  void toggleTheme(bool value) {
    final newTheme = value ? ThemeMode.dark : ThemeMode.light;

    if (state == newTheme) return;

    emit(newTheme);
  }
}