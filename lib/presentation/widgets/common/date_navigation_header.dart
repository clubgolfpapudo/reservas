// lib/presentation/widgets/common/date_navigation_header.dart - LAYOUT COMPACTO UNA LÍNEA
import 'package:flutter/material.dart';

class DateNavigationHeader extends StatelessWidget {
  final String title;
  final DateTime currentDate;
  final int currentIndex;
  final int totalDays;
  final VoidCallback onBackPressed;
  final VoidCallback onAddPressed;
  final VoidCallback? onPreviousDate;
  final VoidCallback? onNextDate;
  final VoidCallback? onDateTap;

  const DateNavigationHeader({
    required this.title,
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
          colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              // ? HEADER PRINCIPAL - TODO EN UNA LÍNEA CENTRADO
              Row(
                children: [
                  // Botón atrás
                  _buildActionButton(
                    icon: Icons.arrow_back,
                    onPressed: onBackPressed,
                  ),
                  
                  // ? CENTRO: TÍTULO + FECHA + FLECHAS JUNTOS
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: onDateTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Título principal
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            
                            // Separador
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            
                            // Fecha
                            Text(
                              _formatDateCompact(currentDate),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // ? FLECHAS INMEDIATAMENTE DESPUÉS DE LA FECHA
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botón agregar (equilibra el layout)
                  _buildActionButton(
                    icon: Icons.add,
                    onPressed: onAddPressed,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Indicadores de días (más compactos)
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
      width: 28, // ? Ligeramente más grande para mejor usabilidad móvil
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(onPressed != null ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: Colors.white.withOpacity(onPressed != null ? 0.9 : 0.3),
          size: 16, // ? Ícono más grande para mejor tap target
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
          width: isActive ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isActive ? 1.0 : 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ? FORMATO DE FECHA COMPLETO PERO COMPACTO
  String _formatDateCompact(DateTime date) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Jul', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    // Formato: "28 Mayo" - completo pero sin "de"
    return '${date.day} ${months[date.month]}';
  }
}
