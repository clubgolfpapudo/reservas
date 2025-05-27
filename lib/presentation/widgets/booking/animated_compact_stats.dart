// lib/presentation/widgets/booking/animated_compact_stats.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/booking.dart';

class AnimatedCompactStats extends StatefulWidget {
  final List<Booking> bookings;

  const AnimatedCompactStats({
    Key? key,
    required this.bookings,
  }) : super(key: key);

  @override
  State<AnimatedCompactStats> createState() => _AnimatedCompactStatsState();
}

class _AnimatedCompactStatsState extends State<AnimatedCompactStats>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCompactStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookings.length != widget.bookings.length) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcular estadísticas
    final completeCount = widget.bookings
        .where((b) => b.status == BookingStatus.complete)
        .length;
    
    final incompleteCount = widget.bookings
        .where((b) => b.status == BookingStatus.incomplete)
        .length;
    
    const totalTimeSlots = 8; // Total de horarios disponibles
    final availableCount = totalTimeSlots - widget.bookings.length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      count: completeCount,
                      label: 'Completas',
                      color: const Color(0xFF2E7AFF),
                      icon: Icons.check_circle,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      count: incompleteCount,
                      label: 'Incompletas',
                      color: const Color(0xFFFF7530),
                      icon: Icons.group,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      count: availableCount,
                      label: 'Disponibles',
                      color: const Color(0xFF10B981),
                      icon: Icons.add_circle_outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '$count',
              key: ValueKey(count),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}