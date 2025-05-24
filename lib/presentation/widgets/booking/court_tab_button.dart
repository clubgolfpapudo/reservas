// lib/presentation/widgets/booking/court_tab_button.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Botón para seleccionar una cancha específica
class CourtTabButton extends StatelessWidget {
  final String court;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? customColor;

  const CourtTabButton({
    Key? key,
    required this.court,
    required this.isSelected,
    required this.onTap,
    this.customColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingL,
          vertical: AppSizes.spacingS,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: _getBorderColor(),
            width: 2.0,
          ),
          boxShadow: isSelected ? AppShadows.light : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppAnimations.fast,
          style: AppTextStyles.tabLabel.copyWith(
            color: _getTextColor(),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          child: Text(court),
        ),
      ),
    );
  }

  /// Obtiene el color de fondo según el estado
  Color _getBackgroundColor() {
    if (isSelected) {
      return AppColors.lightGray;
    }
    return Colors.white;
  }

  /// Obtiene el color del borde según el estado
  Color _getBorderColor() {
    if (isSelected) {
      return customColor ?? AppColors.primaryBlue;
    }
    return AppColors.borderGray;
  }

  /// Obtiene el color del texto según el estado
  Color _getTextColor() {
    if (isSelected) {
      return AppColors.red; // Color rojo para texto seleccionado según el design
    }
    return AppColors.mediumGray;
  }
}