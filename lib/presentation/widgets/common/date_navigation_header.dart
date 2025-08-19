// lib/presentation/widgets/common/date_navigation_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/corporate_theme.dart';

// SOLO REEMPLAZAR EL CONSTRUCTOR en date_navigation_header.dart

class DateNavigationHeader extends StatelessWidget {
  // MANTENER ESTOS PARÁMETROS PARA SER COMPATIBLE
  final DateTime selectedDate;          // Era currentDate en las páginas
  final int? currentIndex;             // AGREGAR - usado en las páginas
  final int? totalDays;                // AGREGAR - usado en las páginas  
  final String title;
  final VoidCallback? onBackPressed;   // AGREGAR - usado en las páginas
  final VoidCallback? onAddPressed;    // AGREGAR - usado en las páginas
  final VoidCallback? onPreviousDate;  // AGREGAR - usado en las páginas
  final VoidCallback? onNextDate;      // AGREGAR - usado en las páginas
  final VoidCallback? onDateTap;       // AGREGAR - usado en las páginas
  
  // MANTENER LOS ORIGINALES TAMBIÉN POR COMPATIBILIDAD
  final Function(DateTime)? onDateChanged;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;

  const DateNavigationHeader({
    super.key,
    required this.selectedDate,        // COMPATIBLE con selectedDate
    required this.title,
    this.currentIndex,                 // AGREGAR
    this.totalDays,                    // AGREGAR
    this.onBackPressed,                // AGREGAR
    this.onAddPressed,                 // AGREGAR
    this.onPreviousDate,               // AGREGAR
    this.onNextDate,                   // AGREGAR
    this.onDateTap,                    // AGREGAR
    this.onDateChanged,                // MANTENER
    this.onMenuPressed,                // MANTENER
    this.actions,                      // MANTENER
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getGradientForTitle(title),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Header superior con título y acciones
              _buildTopHeader(context),
              
              const SizedBox(height: 16),
              
              // Navegación de fechas
              _buildDateNavigation(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      children: [
        // Botón menú / back
        if (onMenuPressed != null)
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu),
            color: Colors.white,
            iconSize: 24,
          )
        else
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            iconSize: 24,
          ),
        
        const SizedBox(width: 8),
        
        // Logo del club (pequeño)
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/club_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: CorporateTheme.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.golf_course,
                    size: 18,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Título y subtítulo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppConstants.clubName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Acciones adicionales
        if (actions != null) ...actions!,
      ],
    );
  }

  Widget _buildDateNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón día anterior
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onPressed: () => _navigateDate(-1),
            enabled: _canNavigateBackward(),
          ),
          
          // Fecha actual con formato elegante
          Expanded(
            child: GestureDetector(
              onTap: () => _showDatePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE', 'es_ES').format(selectedDate),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMMM yyyy', 'es_ES').format(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Botón día siguiente
          _buildNavigationButton(
            icon: Icons.chevron_right,
            onPressed: () => _navigateDate(1),
            enabled: _canNavigateForward(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled 
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        color: enabled 
            ? Colors.white
            : Colors.white.withOpacity(0.5),
        iconSize: 24,
      ),
    );
  }

  // Determina el gradiente según el deporte/sección
  LinearGradient _getGradientForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'pádel':
      case 'padel':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConstants.padelPrimary),
            Color(AppConstants.padelSecondary),
          ],
        );
      
      case 'tenis':
      case 'tennis':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConstants.tennisPrimary),
            Color(AppConstants.tennisSecondary),
          ],
        );
      
      case 'golf':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConstants.golfPrimary),
            Color(AppConstants.golfSecondary),
          ],
        );
      
      default:
        // Gradiente corporativo para página principal o indeterminado
        return CorporateTheme.primaryGradient;
    }
  }

  void _navigateDate(int days) {
    final newDate = selectedDate.add(Duration(days: days));
    onDateChanged?.call(newDate);
  }

  bool _canNavigateBackward() {
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day);
    return selectedDate.isAfter(minDate);
  }

  bool _canNavigateForward() {
    final today = DateTime.now();
    final maxDate = today.add(Duration(days: AppConstants.maxDaysInAdvance));
    return selectedDate.isBefore(maxDate);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final today = DateTime.now();
    final maxDate = today.add(Duration(days: AppConstants.maxDaysInAdvance));
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: today,
      lastDate: maxDate,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _getPrimaryColorForTitle(title),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      onDateChanged?.call(pickedDate);
    }
  }

  Color _getPrimaryColorForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'pádel':
      case 'padel':
        return Color(AppConstants.padelPrimary);
      case 'tenis':
      case 'tennis':
        return Color(AppConstants.tennisPrimary);
      case 'golf':
        return Color(AppConstants.golfPrimary);
      default:
        return CorporateTheme.primaryNavyBlue;
    }
  }
}

// Widget simplificado para casos donde solo se necesita el header básico
class SimpleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const SimpleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: CorporateTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              if (onBackPressed != null)
                IconButton(
                  onPressed: onBackPressed,
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                ),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
