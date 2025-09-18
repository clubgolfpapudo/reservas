// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COLORES DE LA APLICACIÓN - TENIS (TIERRA BATIDA)
// ═══════════════════════════════════════════════════════════════════════════════
abstract class AppColors {
  // Colores principales - TENIS (Tierra Batida) 🎾
  static const Color primaryBlue = Color(0xFFD2691E);        // 🏆 TIERRA BATIDA AUTÉNTICA (era café)
  static const Color primaryBlueLight = Color(0xFFFFF8DC);   // 🏺 Cornsilk claro (era café claro)
  static const Color primaryBlueDark = Color(0xFFB8860B);    // 🥉 Dark Goldenrod (era café oscuro)
  static const Color primaryBlueBorder = Color(0xFFDEB887);  // 🍂 Burlywood borde (era café borde)
  
  // Colores de estado para reservas
  static const Color available = Color(0xFFF3E5AB);          // Beige disponible (mantener)
  static const Color availableBorder = Color(0xFFD4AF37);    // Dorado claro borde (mantener)
  static const Color availableText = Color(0xFF3A3A3C);
  static const Color reserved = Color(0xFFD2691E);           // 🎾 TIERRA BATIDA reservado
  static const Color reservedBorder = Color(0xFFB8860B);     // 🎾 Dark Goldenrod borde
  static const Color reservedText = Colors.white;
  static const Color incomplete = Color(0xFFFFFACD);         // Mantener amarillo
  static const Color incompleteBorder = Color(0xFFDAA520);   // Mantener borde dorado
  static const Color incompleteText = Color(0xFF8B4513);     // Mantener texto marrón
  
  // Colores semánticos
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3A30);
  static const Color info = primaryBlue;                     // 🎾 Ahora tierra batida
  
  // Grises (sin cambios)
  static const Color darkGray = Color(0xFF3A3A3C);
  static const Color mediumGray = Color(0xFF8E8E93);
  static const Color lightGray = Color(0xFFF2F2F7);
  static const Color borderGray = Color(0xFFD1D1D6);
  static const Color backgroundGray = Color(0xFFFAFAFA);
  
  // Colores de categorías de usuario (sin cambios)
  static const Color adminColor = Color(0xFF9C27B0);     // Púrpura
  static const Color socioColor = Color(0xFF4CAF50);     // Verde
  static const Color hijoSocioColor = Color(0xFF2196F3); // Azul
  static const Color visitaColor = Color(0xFFFF9800);    // Naranja
  static const Color filialColor = Color(0xFF795548);    // Marrón
  
  // Colores de canchas (sin cambios - estos son para canchas individuales)
  static const Color piteColor = Color(0xFFFF5722);   // Naranja
  static const Color lilenColor = Color(0xFF2196F3);  // Azul
  static const Color plaiyaColor = Color(0xFF4CAF50); // Verde
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAMAÑOS Y ESPACIADO
// ═══════════════════════════════════════════════════════════════════════════════
abstract class AppSizes {
  // Sistema base de 8px
  static const double base = 8.0;
  
  // Espaciado
  static const double spacingXS = base * 0.5;  // 4px
  static const double spacingS = base;         // 8px
  static const double spacingM = base * 2;     // 16px
  static const double spacingL = base * 3;     // 24px
  static const double spacingXL = base * 4;    // 32px
  static const double spacingXXL = base * 6;   // 48px
  
  // Radios de borde
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 50.0;
  
  // Tamaños de iconos
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 28.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 48.0;
  
  // Alturas de componentes
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 56.0;
  static const double buttonHeight = 44.0;
  static const double inputHeight = 44.0;
  static const double timeSlotBlockHeight = 60.0;
  static const double timeSlotBlockExpandedHeight = 100.0;
  
  // Tamaños táctiles mínimos
  static const double minTouchTarget = 44.0;
  
  // Anchos máximos
  static const double maxContentWidth = 480.0;
  static const double maxCardWidth = 400.0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ESTILOS DE TEXTO
// ═══════════════════════════════════════════════════════════════════════════════
abstract class AppTextStyles {
  // Familia de fuente base
  static const String fontFamily = 'SF Pro Display';
  
  // Títulos
  static const TextStyle headline1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGray,
    height: 1.2,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    height: 1.3,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    height: 1.4,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline4 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    height: 1.4,
    fontFamily: fontFamily,
  );
  
  // Cuerpo de texto
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18.0,
    color: AppColors.darkGray,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16.0,
    color: AppColors.darkGray,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14.0,
    color: AppColors.darkGray,
    height: 1.4,
    fontFamily: fontFamily,
  );
  
  // Texto de componentes específicos
  static const TextStyle timeSlotTime = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
    fontFamily: fontFamily,
  );
  
  static const TextStyle timeSlotStatus = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.normal,
    height: 1.2,
    fontFamily: fontFamily,
  );
  
  static const TextStyle timeSlotPlayers = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    height: 1.3,
    fontFamily: fontFamily,
  );
  
  static const TextStyle tabLabel = TextStyle(
    fontSize: 20.0,
    height: 1.2,
    fontFamily: fontFamily,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    color: AppColors.mediumGray,
    height: 1.3,
    fontFamily: fontFamily,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    color: AppColors.mediumGray,
    height: 1.5,
    letterSpacing: 1.5,
    fontFamily: fontFamily,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMACIONES
// ═══════════════════════════════════════════════════════════════════════════════
abstract class AppAnimations {
  // Duraciones
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration verySlow = Duration(milliseconds: 600);
  
  // Curvas
  static const Curve standard = Curves.easeOut;
  static const Curve acceleration = Curves.easeIn;
  static const Curve deceleration = Curves.easeOut;
  static const Curve bounce = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve smooth = Curves.easeInOut;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SOMBRAS
// ═══════════════════════════════════════════════════════════════════════════════
abstract class AppShadows {
  static List<BoxShadow> get none => [];
  
  static List<BoxShadow> get light => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get heavy => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMA PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Configuración base
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Esquema de colores
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.incomplete,
        surface: Colors.white,
        background: AppColors.backgroundGray,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkGray,
        onBackground: AppColors.darkGray,
        onError: Colors.white,
      ),
      
      // Tipografía
      fontFamily: AppTextStyles.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headline1,
        displayMedium: AppTextStyles.headline2,
        displaySmall: AppTextStyles.headline3,
        headlineMedium: AppTextStyles.headline4,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.buttonText,
        labelMedium: AppTextStyles.tabLabel,
        labelSmall: AppTextStyles.caption,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkGray,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          fontFamily: AppTextStyles.fontFamily,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkGray,
          size: AppSizes.iconM,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingM,
            vertical: AppSizes.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          textStyle: AppTextStyles.buttonText,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingM,
            vertical: AppSizes.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingM,
            vertical: AppSizes.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          side: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      
      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(
            color: AppColors.borderGray,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(
            color: AppColors.borderGray,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.spacingM),
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          color: AppColors.mediumGray,
          fontFamily: AppTextStyles.fontFamily,
        ),
        labelStyle: const TextStyle(
          color: AppColors.mediumGray,
          fontFamily: AppTextStyles.fontFamily,
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontFamily: AppTextStyles.fontFamily,
        ),
      ),
      
      // // Tarjetas
      // cardTheme: CardThemeData(
      //   elevation: 2.0,
      //   shadowColor: Colors.black.withOpacity(0.1),
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(AppSizes.radiusM),
      //   ),
      //   margin: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
      //   color: Colors.white,
      // ),
      
      // // Diálogos
      // dialogTheme: DialogThemeData(
      //   elevation: 8.0,
      //   backgroundColor: Colors.white,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(AppSizes.radiusL),
      //   ),
      //   titleTextStyle: AppTextStyles.headline3,
      //   contentTextStyle: AppTextStyles.bodyMedium,
      // ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusL),
          ),
        ),
        elevation: 8.0,
      ),
      
      // Navegación inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.mediumGray,
        selectedLabelStyle: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          fontFamily: AppTextStyles.fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          fontFamily: AppTextStyles.fontFamily,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
      ),
      
      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppColors.borderGray,
        thickness: 1.0,
        space: 1.0,
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightGray,
        labelStyle: AppTextStyles.bodySmall,
        selectedColor: AppColors.primaryBlue,
        disabledColor: AppColors.lightGray.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingS,
          vertical: AppSizes.spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.mediumGray;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue.withOpacity(0.3);
          }
          return AppColors.lightGray;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(
          color: AppColors.borderGray,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXS),
        ),
      ),
      
      // Radio Button
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.mediumGray;
        }),
      ),
      
      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryBlue,
        inactiveTrackColor: AppColors.lightGray,
        thumbColor: AppColors.primaryBlue,
        overlayColor: Color(0x1F2E7AFF),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
        linearTrackColor: AppColors.lightGray,
        circularTrackColor: AppColors.lightGray,
      ),
      
      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkGray,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6.0,
      ),
      
      // // TabBar
      // tabBarTheme: TabBarThemeData(
      //   labelColor: AppColors.primaryBlue,
      //   unselectedLabelColor: AppColors.mediumGray,
      //   indicatorColor: AppColors.primaryBlue,
      //   labelStyle: TextStyle(
      //     fontSize: 16.0,
      //     fontWeight: FontWeight.w500,
      //     fontFamily: AppTextStyles.fontFamily,
      //   ),
      //   unselectedLabelStyle: TextStyle(
      //     fontSize: 16.0,
      //     fontWeight: FontWeight.normal,
      //     fontFamily: AppTextStyles.fontFamily,
      //   ),
      // ),
      
      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 6.0,
        focusElevation: 8.0,
        hoverElevation: 8.0,
        highlightElevation: 12.0,
        shape: CircleBorder(),
      ),
    );
  }

  // Tema oscuro (opcional para futuro)
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.incomplete,
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: lightTheme.cardTheme.copyWith(
        color: const Color(0xFF1E1E1E),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MÉTODOS UTILITARIOS PARA COLORES
// ═══════════════════════════════════════════════════════════════════════════════
extension AppColorsExtension on AppColors {
  /// Obtiene el color según el rol del usuario
  static Color getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.adminColor;
      case 'socio_titular':
        return AppColors.socioColor;
      case 'hijo_socio':
        return AppColors.hijoSocioColor;
      case 'visita':
        return AppColors.visitaColor;
      case 'filial':
        return AppColors.filialColor;
      default:
        return AppColors.primaryBlue;
    }
  }

  /// Obtiene el color según el nombre de la cancha
  static Color getCourtColor(String courtName) {
    switch (courtName.toLowerCase()) {
      case 'pite':
        return AppColors.piteColor;
      case 'lilen':
        return AppColors.lilenColor;
      case 'plaiya':
        return AppColors.plaiyaColor;
      default:
        return AppColors.primaryBlue;
    }
  }

  /// Obtiene el color según el estado de la reserva
  static Color getBookingStatusColor(String status) {
    switch (status) {
      case 'complete':
        return AppColors.reserved;
      case 'incomplete':
        return AppColors.incomplete;
      case 'cancelled':
        return AppColors.mediumGray;
      default:
        return AppColors.available;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESPONSIVE UTILITIES
// ═══════════════════════════════════════════════════════════════════════════════
extension ResponsiveUtils on BuildContext {
  /// Verifica si es móvil
  bool get isMobile => MediaQuery.of(this).size.width < 768;
  
  /// Verifica si es tablet
  bool get isTablet => MediaQuery.of(this).size.width >= 768;
  
  /// Verifica si es móvil pequeño
  bool get isSmallMobile => MediaQuery.of(this).size.width <= 375;
  
  /// Obtiene el ancho de pantalla
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Obtiene el alto de pantalla
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Obtiene padding responsivo
  EdgeInsets get responsivePadding {
    if (isSmallMobile) {
      return const EdgeInsets.all(AppSizes.spacingS);
    } else if (isMobile) {
      return const EdgeInsets.all(AppSizes.spacingM);
    } else {
      return const EdgeInsets.all(AppSizes.spacingL);
    }
  }
  
  /// Obtiene el número de columnas para grid responsivo
  int get gridColumns {
    if (isSmallMobile) return 1;
    if (isMobile) return 2;
    return 3;
  }
}