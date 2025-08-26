// lib/presentation/widgets/time_slot_block.dart
import 'package:flutter/material.dart';
import '../../domain/entities/booking.dart';
import '../../core/theme/app_theme.dart';

class TimeSlotBlock extends StatefulWidget {
  final String time;
  final BookingStatus? status; // null significa disponible
  final List<BookingPlayer> players;
  final VoidCallback onReservePressed;
  final VoidCallback? onTap;

  const TimeSlotBlock({
    Key? key,
    required this.time,
    this.status,
    this.players = const [],
    required this.onReservePressed,
    this.onTap,
  }) : super(key: key);

  @override
  State<TimeSlotBlock> createState() => _TimeSlotBlockState();
}

class _TimeSlotBlockState extends State<TimeSlotBlock> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Determinar color y texto según estado (según documento de diseño)
    Color blockColor;
    String statusText;
    bool showReserveButton = false;
    Color textColor = Colors.white;

    if (widget.status == null) {
      // Disponible
      blockColor = const Color(0xFFE8F4F9); // Azul claro
      statusText = "Disponible";
      showReserveButton = true;
      textColor = Colors.black;
    } else {
      switch (widget.status!) {
        case BookingStatus.complete:
          blockColor = const Color(0xFF2E7AFF); // Azul
          statusText = "Reservada";
          break;
        case BookingStatus.incomplete:
          blockColor = AppColors.incomplete; // Naranja
          statusText = "Reservada";
          break;
        case BookingStatus.cancelled:
          blockColor = Colors.red;
          statusText = "Cancelada";
          break;
      }
    }

    return GestureDetector(
      onTap: () {
        if (widget.status != null && widget.status != BookingStatus.cancelled) {
          // Solo expandir si hay una reserva activa
          setState(() {
            _isExpanded = !_isExpanded;
          });
        }
        
        // Llamar callback si existe
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.symmetric(
          horizontal: 16.0, 
          vertical: _isExpanded ? 20.0 : 12.0
        ),
        decoration: BoxDecoration(
          color: blockColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primera fila: Hora y estado/botón
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.time,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (showReserveButton)
                  ElevatedButton(
                    onPressed: widget.onReservePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      "Reservar", 
                      style: TextStyle(fontSize: 18.0)
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            // Segunda fila: Jugadores (solo si está expandido y hay jugadores)
            if (_isExpanded && widget.players.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white),
              const SizedBox(height: 8),
              
              // Mostrar jugadores según formato del documento: "JUGADOR1 * JUGADOR2 * ..."
              Text(
                widget.players
                    .where((player) => player.status == PlayerStatus.confirmed)
                    .map((player) => player.name)
                    .join(" * "),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              // Mostrar información adicional si está expandido
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.players.where((p) => p.status == PlayerStatus.confirmed).length}/4 jugadores',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  if (widget.players.any((p) => p.isMainBooker))
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.players.firstWhere((p) => p.isMainBooker).name,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],

            // Indicador visual de que se puede expandir
            if (widget.players.isNotEmpty && widget.status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
