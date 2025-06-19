// lib/presentation/widgets/common/app_loading_indicator.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme.dart';

/// Indicador de carga personalizado para la aplicación
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool showMessage;
  final Color? color;
  final double size;

  const AppLoadingIndicator({
    Key? key,
    this.message,
    this.showMessage = true,
    this.color,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador circular
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primaryBlue,
              ),
              strokeWidth: 3.0,
            ),
          ),
          
          // Mensaje opcional
          if (showMessage && message != null) ...[
            const SizedBox(height: AppSizes.spacingM),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Indicador de carga pequeño para usar en línea
class AppLoadingIndicatorSmall extends StatelessWidget {
  final Color? color;

  const AppLoadingIndicatorSmall({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20.0,
      height: 20.0,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primaryBlue,
        ),
        strokeWidth: 2.0,
      ),
    );
  }
}

/// Overlay de carga que cubre toda la pantalla
class AppLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;
  final Widget child;

  const AppLoadingOverlay({
    Key? key,
    required this.child,
    this.message,
    this.isVisible = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isVisible)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: AppLoadingIndicator(
              message: message ?? 'Cargando...',
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}
