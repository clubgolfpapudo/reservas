// lib/presentation/widgets/booking/animated_compact_stats.dart - ACTUALIZAR

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../../../core/theme/app_theme.dart';

class AnimatedCompactStats extends StatelessWidget {
  final List<dynamic> bookings; // Mantenemos por compatibilidad pero no lo usamos

  const AnimatedCompactStats({
    Key? key,
    required this.bookings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        // ✅ OBTENER horarios visibles filtrados
        final visibleTimeSlots = provider.getAvailableTimeSlotsForDate(provider.selectedDate);
        
        // ✅ CALCULAR estadísticas SOLO sobre horarios visibles
        final stats = provider.getStatsForVisibleTimeSlots(visibleTimeSlots);
        final completeCount = stats['complete'] ?? 0;
        final incompleteCount = stats['incomplete'] ?? 0;
        final availableCount = stats['available'] ?? 0;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              // Completas
              _buildStatItem(
                icon: Icons.check_circle,
                count: completeCount,
                label: 'Completas',
                color: const Color(0xFF2E7AFF),
              ),
              
              const SizedBox(width: 16),
              
              // Separador
              Container(
                width: 1,
                height: 20,
                color: Colors.grey[300],
              ),
              
              const SizedBox(width: 16),
              
              // Incompletas
              _buildStatItem(
                icon: Icons.group,
                count: incompleteCount,
                label: 'Incompletas',
                color: AppColors.incomplete,
              ),
              
              const SizedBox(width: 16),
              
              // Separador
              Container(
                width: 1,
                height: 20,
                color: Colors.grey[300],
              ),
              
              const SizedBox(width: 16),
              
              // Disponibles
              _buildStatItem(
                icon: Icons.schedule,
                count: availableCount,
                label: 'Disponibles',
                color: const Color(0xFF4CAF50),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          // Número animado
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '$count',
              key: ValueKey('${label}_$count'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
