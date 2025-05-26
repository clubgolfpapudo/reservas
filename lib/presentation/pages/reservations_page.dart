// lib/presentation/pages/reservations_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/common/compact_header.dart';
import '../widgets/booking/compact_court_tabs.dart';
import '../widgets/booking/compact_stats.dart';
import '../widgets/booking/time_slot_block.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/booking.dart';

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          return Column(
            children: [
              // Header compacto
              CompactHeader(
                title: 'Reservas Pádel',
                subtitle: _formatDate(bookingProvider.selectedDate),
                onBackPressed: () => Navigator.of(context).pop(),
                onAddPressed: () => _handleAddReservation(context),
              ),

              // Tabs de canchas compactos
              CompactCourtTabs(
                selectedCourt: bookingProvider.selectedCourtName,
                onCourtSelected: (courtName) {
                  // Mapear nombre a ID
                  String courtId;
                  switch (courtName) {
                    case 'PITE':
                      courtId = 'court_1';
                      break;
                    case 'LILEN':
                      courtId = 'court_2';
                      break;
                    case 'PLAIYA':
                      courtId = 'court_3';
                      break;
                    default:
                      courtId = 'court_1';
                  }
                  bookingProvider.selectCourt(courtId);
                },
              ),

              // Estadísticas compactas
              CompactStats(
                bookings: bookingProvider.currentBookings,
              ),

              // Lista de horarios
              Expanded(
                child: _buildTimeSlotsList(context, bookingProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotsList(BuildContext context, BookingProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7AFF),
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Recargar datos
                provider.selectDate(provider.selectedDate);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: AppConstants.availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = AppConstants.availableTimeSlots[index];
        final booking = provider.getBookingForTimeSlot(timeSlot);

        // DEBUG TEMPORAL
        if (timeSlot == '16:30') {
          print('🎰 Slot 16:30 - booking encontrado: ${booking != null}');
          if (booking != null) {
            print('   - Status: ${booking.status}');
            print('   - Players: ${booking.players.length}');
          }
        }
        
        // Determinar estado del slot
        BookingStatus? status; // null = disponible
        List<BookingPlayer> players = [];
        
        if (booking != null) {
          status = booking.status;
          players = booking.players
              // .where((player) => player.status == PlayerStatus.confirmed)
              .toList();
        } else {
          status = null; // null = disponible
        }

        return TimeSlotBlock(
          time: timeSlot,
          status: status,
          players: players,
          onReservePressed: () => _handleReserveSlot(context, timeSlot),
          onTap: () => _handleSlotTap(context, booking),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month]}';
  }

  void _handleAddReservation(BuildContext context) {
    // TODO: Implementar navegación para agregar reserva
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de agregar reserva próximamente'),
        backgroundColor: Color(0xFF2E7AFF),
      ),
    );
  }

  void _handleReserveSlot(BuildContext context, String timeSlot) {
    // TODO: Implementar proceso de reserva
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reservar horario $timeSlot'),
        backgroundColor: Color(0xFF2E7AFF),
      ),
    );
  }

  void _handleSlotTap(BuildContext context, Booking? booking) {
    if (booking != null) {
      // TODO: Implementar navegación a detalles de reserva
      print('Ver detalles de reserva: ${booking.id}');
    }
  }
}