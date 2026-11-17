import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF0B1F3A);
  static const blue = Color(0xFF1E6FEB);
  static const green = Color(0xFF2E9E5B);
  static const red = Color(0xFFD64545);
  static const orange = Color(0xFFE8912D);
  static const grey = Color(0xFF9AA5B1);
  static const bg = Color(0xFFF5F7FA);

  static Color forSlot(String status) => switch (status) {
        'AVAILABLE' => green,
        'OCCUPIED' => red,
        'RESERVED' => orange,
        _ => grey,
      };

  static Color forStatus(String s) => switch (s) {
        'AVAILABLE' || 'CONFIRMED' => green,
        'ACTIVE' || 'CHARGING' => blue,
        'RESERVED' => orange,
        'OCCUPIED' || 'CANCELLED' || 'OFFLINE' => red,
        _ => grey,
      };
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue, primary: AppColors.blue),
      scaffoldBackgroundColor: AppColors.bg,
      cardTheme: const CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: AppColors.navy),
    );
