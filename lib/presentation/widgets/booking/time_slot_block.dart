// lib/presentation/widgets/booking/time_slot_block.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/booking.dart';
import '../../../core/constants/app_constants.dart';

class TimeSlotBlock extends StatefulWidget {
  final String time;
  final BookingStatus? status; // null = disponible
  final List<BookingPlayer> players;
  final VoidCallback? onReservePressed;
  final VoidCallback? onTap;

  const TimeSlotBlock({
    Key? key,
    required this.time,
    required this.status,
    required this.players,
    this.onReservePressed,
    this.onTap,
  }) : super(key: key);

  @override
  State<TimeSlotBlock> createState() => _TimeSlotBlockState();
}

class _TimeSlotBlockState extends State<TimeSlotBlock>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    if (_canExpand()) {
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
      widget.onTap?.call();
    }
  }

  bool _canExpand() {
    return widget.status != null && // null = disponible
           widget.players.isNotEmpty;
  }

  Color _getBackgroundColor() {
    if (widget.status == null) {
      return const Color(0xFFE8F4F9); // Azul claro - disponible
    }
    
    switch (widget.status!) {
      case BookingStatus.complete:
        return const Color(0xFF2E7AFF); // Azul
      case BookingStatus.incomplete:
        return const Color(0xFFFF7530); // Naranja
      // case BookingStatus.cancelled:
        return Colors.grey; // Gris
    }
    // Return por defecto:
    return Colors.grey;
  }

  String _getStatusText() {
    if (widget.status == null) {
      return "Disponible";
    }
    
    switch (widget.status!) {
      case BookingStatus.complete:
        return "Reservada";
      case BookingStatus.incomplete:
        return "Incompleta";
      case BookingStatus.cancelled:
        return "Cancelada";
      default:
        return "Desconocido";
    }
  }

  bool _isTextWhite() {
    return widget.status != null; // null = disponible = texto negro
  }

  Widget _buildPlayerPreview() {
    if (widget.players.isEmpty || _isExpanded) return const SizedBox.shrink();
    
    final activePlayers = widget.players
        // .where((player) => player.status == PlayerStatus.confirmed)
        .toList();
    
    if (activePlayers.isEmpty) return const SizedBox.shrink();

    final displayPlayers = activePlayers.take(2).toList();
    final remainingCount = activePlayers.length - displayPlayers.length;
    
    String previewText = displayPlayers
        .map((player) => player.name.split(' ').take(2).join(' '))
        .join(' • ');
    
    if (remainingCount > 0) {
      previewText += ' • +$remainingCount';
    }

    return Flexible(
      child: Text(
        previewText,
        style: TextStyle(
          fontSize: 14,
          color: _isTextWhite() ? Colors.white.withOpacity(0.9) : Colors.black54,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 1,
      ),
    );
  }

  Widget _buildExpandedPlayerList() {
    if (!_isExpanded || widget.players.isEmpty) {
      return const SizedBox.shrink();
    }

    final activePlayers = widget.players
        // .where((player) => player.status == PlayerStatus.confirmed)
        .toList();

    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: activePlayers.map((player) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    if (widget.status == null) { // null = disponible
      return ElevatedButton(
        onPressed: widget.onReservePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: const Text(
          'Reservar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getStatusText(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (_canExpand()) ...[
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: AppConstants.defaultAnimationDuration,
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: AnimatedContainer(
        duration: AppConstants.fastAnimationDuration,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(8),
          border: widget.status == null // null = disponible
              ? Border.all(color: const Color(0xFF2E7AFF).withOpacity(0.3), width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila principal: Hora + Preview + Acción
            Row(
              children: [
                // Hora
                Text(
                  widget.time,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isTextWhite() ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Preview de jugadores
                _buildPlayerPreview(),
                
                const Spacer(),
                
                // Botón o estado
                _buildActionSection(),
              ],
            ),
            
            // Lista expandida de jugadores
            _buildExpandedPlayerList(),
          ],
        ),
      ),
    );
  }
}