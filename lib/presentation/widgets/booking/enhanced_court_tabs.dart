// lib/presentation/widgets/booking/enhanced_court_tabs.dart - ANDROID COLOR FIX
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class EnhancedCourtTabs extends StatefulWidget {
  final String selectedCourt;
  final Function(String) onCourtSelected;
  final List<String> courtNames;

  const EnhancedCourtTabs({
    Key? key,
    required this.selectedCourt,
    required this.onCourtSelected,
    required this.courtNames,
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
        children: widget.courtNames.map((courtName) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: courtName != widget.courtNames.last ? 8.0 : 0,
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
          color: isSelected ? primaryColor : _getCourtLightColor(courtName),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: darkColor, width: 2) // ✅ Borde sólido
              : Border.all(color: _getCourtLightColor(courtName), width: 1),
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
        return const Color(0xFF00BCD4); // 🔵 Cyan (Pádel)
      case 'LILEN':
        return const Color(0xFF00C851); // 🟢 Verde Esmeralda (Pádel)
      case 'PLAIYA':
        return const Color(0xFF8E44AD); // 🟣 Púrpura Vibrante (Pádel)
      
      // 🎾 TENIS - NUEVOS COLORES
      case 'C.1':
        return const Color(0xFF2196F3); // 🔵 Azul
      case 'C.2':
        return const Color(0xFF4CAF50); // 🟢 Verde
      case 'C.3':
        return const Color(0xFF00BCD4); // 🔵 Turquesa
      case 'C.4':
        return const Color(0xFF9C27B0); // 🟣 Púrpura
      
      default:
        return const Color(0xFF2196F3); // Azul por defecto
    }
  }

  Color _getCourtDarkColor(String courtName) {
    switch (courtName) {
      case 'PITE':
        return const Color(0xFF0097A7); // 🔵 Cyan oscuro (Pádel)
      case 'LILEN':
        return const Color(0xFF007E33); // Verde más oscuro (Pádel)
      case 'PLAIYA':
        return const Color(0xFF6C3483); // Púrpura más oscuro (Pádel)
      
      // 🎾 TENIS - VERSIONES OSCURAS
      case 'C.1':
        return const Color(0xFF1976D2); // Azul oscuro
      case 'C.2':
        return const Color(0xFF388E3C); // Verde oscuro
      case 'C.3':
        return const Color(0xFF0097A7); // Turquesa oscuro
      case 'C.4':
        return const Color(0xFF7B1FA2); // Púrpura oscuro
      
      default:
        return const Color(0xFF1976D2); // Azul oscuro por defecto
    }
  }

  Color _getCourtLightColor(String courtName) {
    switch (courtName) {
      case 'PITE':
        return const Color(0xFFB2EBF2);  // 🔵 Cyan muy claro (Pádel)
      case 'LILEN':
        return const Color(0xFFE8F5E8);  // Verde claro (Pádel)
      case 'PLAIYA':
        return const Color(0xFFF3E5F5);  // Púrpura claro (Pádel)
      
      // 🎾 TENIS - VERSIONES CLARAS
      case 'C.1':
        return const Color(0xFFE3F2FD); // Azul claro
      case 'C.2':
        return const Color(0xFFE8F5E8); // Verde claro
      case 'C.3':
        return const Color(0xFFE0F7FA); // Turquesa claro
      case 'C.4':
        return const Color(0xFFFCE4EC); // Púrpura claro
      
      default:
        return const Color(0xFFE3F2FD);
    }
  }
}
