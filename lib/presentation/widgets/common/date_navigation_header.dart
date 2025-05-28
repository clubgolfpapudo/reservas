// lib/presentation/widgets/common/date_navigation_header.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';

class DateNavigationHeader extends StatelessWidget {
  final DateTime currentDate;
  final int currentIndex;
  final int totalDays;
  final VoidCallback onBackPressed;
  final VoidCallback onAddPressed;
  final VoidCallback? onPreviousDate;
  final VoidCallback? onNextDate;
  final VoidCallback? onDateTap;

  const DateNavigationHeader({
    Key? key,
    required this.currentDate,
    required this.currentIndex,
    required this.totalDays,
    required this.onBackPressed,
    required this.onAddPressed,
    this.onPreviousDate,
    this.onNextDate,
    this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7AFF), Color(0xFF1a5ce6)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), // ✅ Reduced padding
          child: Column(
            children: [
              // Header principal - REORGANIZADO
              Row(
                children: [
                  // Botón atrás
                  _buildActionButton(
                    icon: Icons.arrow_back,
                    onPressed: onBackPressed,
                  ),
                  
                  // Título compacto con fecha
                  Expanded(
                    child: GestureDetector(
                      onTap: onDateTap,
                      child: Column(
                        children: [
                          // Solo el título principal
                          Text(
                            'Reservas Pádel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16, // ✅ Smaller font
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis, // ✅ Handle overflow
                          ),
                          const SizedBox(height: 2),
                          // Fecha en línea separada
                          Text(
                            _formatDate(currentDate),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis, // ✅ Handle overflow
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Flechas de navegación - SEPARADAS
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavButton(
                        icon: Icons.chevron_left,
                        onPressed: currentIndex > 0 ? onPreviousDate : null,
                      ),
                      const SizedBox(width: 4),
                      _buildNavButton(
                        icon: Icons.chevron_right,
                        onPressed: currentIndex < totalDays - 1 ? onNextDate : null,
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // Botón agregar
                  _buildActionButton(
                    icon: Icons.add,
                    onPressed: onAddPressed,
                  ),
                ],
              ),

              const SizedBox(height: 8), // ✅ Reduced spacing

              // Indicadores de días
              _buildDateIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(onPressed != null ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: Colors.white.withOpacity(onPressed != null ? 0.9 : 0.3),
          size: 12,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDateIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDays, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6, // ✅ Slightly smaller active indicator
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isActive ? 1.0 : 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month]}';
  }
}