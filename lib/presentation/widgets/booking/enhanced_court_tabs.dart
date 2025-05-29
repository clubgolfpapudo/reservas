// lib/presentation/widgets/booking/enhanced_court_tabs.dart - ANDROID COLOR FIX
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class EnhancedCourtTabs extends StatefulWidget {
  final String selectedCourt;
  final Function(String) onCourtSelected;

  const EnhancedCourtTabs({
    Key? key,
    required this.selectedCourt,
    required this.onCourtSelected,
  }) : super(key: key);

  @override
  State<EnhancedCourtTabs> createState() => _EnhancedCourtTabsState();
}

class _EnhancedCourtTabsState extends State<EnhancedCourtTabs>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200), // ✅ Más lento para Android
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: AppConstants.courtNames.map((courtName) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: courtName != AppConstants.courtNames.last ? 8.0 : 0,
              ),
              child: _buildTab(courtName),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTab(String courtName) {
    final isSelected = widget.selectedCourt == courtName;
    
    // ✅ OBTENER colores como Color objects directamente
    final primaryColor = _getCourtPrimaryColor(courtName);
    final darkColor = _getCourtDarkColor(courtName);

    return GestureDetector(
      onTap: () {
        print('🎾 Seleccionando cancha: $courtName');
        widget.onCourtSelected(courtName);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), // ✅ Más lento para Android
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // ✅ USAR COLOR SÓLIDO en lugar de gradiente para Android
          color: isSelected ? primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: darkColor, width: 2) // ✅ Borde sólido
              : Border.all(color: Colors.grey[300]!, width: 1),
          // ✅ SOMBRA SIMPLIFICADA para Android
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            courtName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODOS HELPER PARA COLORES CONSISTENTES
  Color _getCourtPrimaryColor(String courtName) {
    switch (courtName) {
      case 'PITE':
        return const Color(0xFFFF6B35); // 🟠 Naranja Intenso
      case 'LILEN':
        return const Color(0xFF00C851); // 🟢 Verde Esmeralda
      case 'PLAIYA':
        return const Color(0xFF8E44AD); // 🟣 Púrpura Vibrante
      default:
        return const Color(0xFF2196F3); // Azul por defecto
    }
  }

  Color _getCourtDarkColor(String courtName) {
    switch (courtName) {
      case 'PITE':
        return const Color(0xFFE55527); // Naranja más oscuro
      case 'LILEN':
        return const Color(0xFF007E33); // Verde más oscuro
      case 'PLAIYA':
        return const Color(0xFF6C3483); // Púrpura más oscuro
      default:
        return const Color(0xFF1976D2); // Azul oscuro por defecto
    }
  }
}