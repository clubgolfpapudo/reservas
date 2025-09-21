// lib/presentation/widgets/booking/compact_stats.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/booking.dart';
import '../../../core/theme/app_theme.dart';

// Agregar después de los imports existentes

class CompactStats extends StatelessWidget {
  final List<Booking> bookings;

  final DateTime? selectedDate; // ðŸ”¥ NUEVO: fecha para calcular horarios correctos

  const CompactStats({
    Key? key,
    required this.bookings,
    this.selectedDate, // ðŸ”¥ NUEVO parámetro
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completeCount = bookings
        .where((booking) => booking.status == BookingStatus.complete)
        .length;
    
    final incompleteCount = bookings
        .where((booking) => booking.status == BookingStatus.incomplete)
        .length;
    
    // ðŸ”¥ USAR HORARIOS DINÃMICOS según la fecha
    final totalTimeSlots = AppConstants.getAllTimeSlots(selectedDate);
    final availableCount = totalTimeSlots.length - bookings.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Completas
          Expanded(
            child: _buildStatItem(
              count: completeCount,
              label: 'Completas',
              color: const Color(0xFF2E7AFF),
            ),
          ),
          
          // Incompletas
          Expanded(
            child: _buildStatItem(
              count: incompleteCount,
              label: 'Incompletas',
              color: AppColors.incomplete,
            ),
          ),
          
          // Disponibles
          Expanded(
            child: _buildStatItem(
              count: availableCount,
              label: 'Disponibles',
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


