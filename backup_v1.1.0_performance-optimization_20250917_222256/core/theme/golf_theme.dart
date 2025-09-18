// lib/core/theme/golf_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════════════════════════
// COLORES DE LA APLICACIÓN - GOLF (VERDE PROFESIONAL)
// ═══════════════════════════════════════════════════════════════════════════════════════════════════
abstract class GolfColors {
  // Colores principales - GOLF (Verde Profesional) ⛳
  static const Color primaryGreen = Color(0xFF7CB342);       // 🌿 VERDE GOLF AUTÉNTICO
  static const Color primaryGreenLight = Color(0xFFF1F8E9);  // 🌱 Verde muy claro fondo
  static const Color primaryGreenDark = Color(0xFF689F38);   // 🌲 Verde golf oscuro
  static const Color primaryGreenBorder = Color(0xFF8BC34A); // 🍃 Verde claro borde

  // Colores de estado para reservas
  static const Color available = Color(0xFFE8F5E8);          // Verde muy claro disponible
  static const Color availableBorder = Color(0xFF81C784);    // Verde medio borde
  static const Color availableText = Color(0xFF2E7D32);
  static const Color reserved = Color(0xFF7CB342);           // ⛳ VERDE GOLF reservado
  static const Color reservedBorder = Color(0xFF689F38);     // ⛳ Verde golf oscuro borde
  static const Color reservedText = Colors.white;
  static const Color incomplete = Color(0xFFFFF9C4);         // Amarillo claro incompleto
  static const Color incompleteBorder = Color(0xFFFFCC02);   // Amarillo borde
  static const Color incompleteText = Color(0xFF33691E);     // Verde oscuro texto

  // Colores semánticos
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFf44336);
  static const Color info = primaryGreen;                    // ⛳ Verde golf

  // Colores adicionales
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF424242);
  
  // Gradientes golf
  static const List<Color> golfGradient = [
    Color(0xFF7CB342),
    Color(0xFF689F38),
  ];
  
  // Colores específicos para tees
  static const Map<String, Color> teeColors = {
    'golf_tee_1': Color(0xFF4CAF50),   // Verde estándar Tee 1
    'golf_tee_10': Color(0xFF66BB6A),  // Verde claro Tee 10
  };
}

// Tema completo para Golf
abstract class GolfTheme {
  static ThemeData get theme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: GolfColors.primaryGreen,
      scaffoldBackgroundColor: GolfColors.white,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: GolfColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GolfColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: GolfColors.primaryGreen,
        primary: GolfColors.primaryGreen,
        secondary: GolfColors.primaryGreenDark,
        surface: Colors.white,
        background: GolfColors.primaryGreenLight,
      ),
    );
  }
}