// lib/presentation/widgets/booking/date_selector.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Selector horizontal de fechas
class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> availableDates;
  final Function(DateTime) onDateSelected;

  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.availableDates,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
        itemCount: availableDates.length,
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isToday(date);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              curve: AppAnimations.standard,
              width: 70.0,
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXS),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isSelected, isToday),
                shape: BoxShape.circle,
                border: _getBorder(isSelected, isToday),
                boxShadow: isSelected ? AppShadows.light : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nombre del día
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(isSelected, isToday, false),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  // Número del día
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(isSelected, isToday, true),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Verifica si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Verifica si una fecha es hoy
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  /// Obtiene el color de fondo según el estado
  Color _getBackgroundColor(bool isSelected, bool isToday) {
    if (isSelected) {
      return AppColors.primaryBlue;
    }
    return Colors.transparent;
  }

  /// Obtiene el borde según el estado
  Border? _getBorder(bool isSelected, bool isToday) {
    if (isToday && !isSelected) {
      return Border.all(
        color: AppColors.primaryBlue,
        width: 2.0,
      );
    }
    return null;
  }

  /// Obtiene el color del texto según el estado
  Color _getTextColor(bool isSelected, bool isToday, bool isMainText) {
    if (isSelected) {
      return Colors.white;
    }
    
    if (isToday) {
      return AppColors.primaryBlue;
    }
    
    return isMainText ? AppColors.darkGray : AppColors.mediumGray;
  }

  /// Obtiene el nombre corto del día
  String _getDayName(DateTime date) {
    return AppConstants.getWeekdayName(date.weekday, short: true);
  }
}