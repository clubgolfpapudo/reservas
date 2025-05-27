// lib/presentation/widgets/booking/enhanced_court_tabs.dart
import 'package:flutter/material.dart';

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
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shineAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shineController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animación de brillo cada 3 segundos
    _shineController.repeat(period: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const courtNames = ['PITE', 'LILEN', 'PLAIYA'];
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: courtNames.map((courtName) {
          final isSelected = widget.selectedCourt == courtName;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildCourtTab(
                courtName: courtName,
                isSelected: isSelected,
                onTap: () => widget.onCourtSelected(courtName),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourtTab({
    required String courtName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // ← Reducido de 300ms a 200ms
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(0.0, isSelected ? -2.0 : 0.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7AFF), Color(0xFF1a5ce6)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E7AFF) : const Color(0xFFE9ECEF),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2E7AFF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Efecto de brillo más sutil y rápido
              if (isSelected)
                AnimatedBuilder(
                  animation: _shineAnimation,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_shineAnimation.value - 0.2, 0), // ← Área más pequeña
                              end: Alignment(_shineAnimation.value + 0.2, 0),   // ← Área más pequeña
                              colors: const [
                                Colors.transparent,
                                Colors.white10, // ← Más sutil (era white24)
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              
              // Texto del tab
              Center(
                child: Text(
                  courtName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6C757D),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}