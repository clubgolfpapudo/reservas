// lib/presentation/pages/reservations_page.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking/animated_compact_stats.dart';
import '../widgets/booking/enhanced_court_tabs.dart';
import '../widgets/booking/reservation_form_modal.dart';
import '../widgets/booking/reservation_webview.dart';
import '../widgets/booking/time_slot_block.dart';
import '../widgets/common/date_navigation_header.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/booking.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: context.read<BookingProvider>().currentDateIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          return Column(
            children: [
              // Header con navegación de fechas
              DateNavigationHeader(
                title: 'Pádel',
                currentDate: bookingProvider.selectedDate,
                currentIndex: bookingProvider.currentDateIndex,
                totalDays: bookingProvider.totalAvailableDays,
                onBackPressed: () => Navigator.of(context).pop(),
                onAddPressed: () => _handleAddReservation(context),
                onPreviousDate: bookingProvider.canGoToPreviousDate
                    ? () => _goToPreviousDate(bookingProvider)
                    : null,
                onNextDate: bookingProvider.canGoToNextDate
                    ? () => _goToNextDate(bookingProvider)
                    : null,
                onDateTap: () => _showDateSelector(context, bookingProvider),
              ),

              // Contenido principal con PageView para swipe
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: bookingProvider.totalAvailableDays,
                  onPageChanged: (index) {
                    bookingProvider.selectDateByIndex(index);
                  },
                  itemBuilder: (context, index) {
                    return _buildDateContent(context, bookingProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateContent(BuildContext context, BookingProvider provider) {
    return Column(
      children: [
        // Tabs de canchas mejorados
        EnhancedCourtTabs(
          courtNames: AppConstants.courtNames,
          selectedCourt: provider.selectedCourtName,
          onCourtSelected: (courtName) {
            // Mapear nombre a ID
            String courtId;
            switch (courtName) {
              case 'PITE':
                courtId = 'padel_court_1';
                break;
              case 'LILEN':
                courtId = 'padel_court_2';
                break;
              case 'PLAIYA':
                courtId = 'padel_court_3';
                break;
              default:
                courtId = 'padel_court_1';
            }
            provider.selectCourt(courtId);
          },
        ),

        // Estadísticas compactas
        AnimatedCompactStats(
          bookings: provider.currentBookings,
        ),

        // Lista de horarios
        Expanded(
          child: _buildTimeSlotsList(context, provider),
        ),
      ],
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
                provider.refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7AFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final availableTimeSlots = provider.getAvailableTimeSlotsForDate(provider.selectedDate);

    // Si no hay horarios disponibles, mostrar mensaje
    if (availableTimeSlots.isEmpty) {
      return _buildNoSlotsAvailable(context, provider);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = availableTimeSlots[index];
        final booking = provider.getBookingForTimeSlot(timeSlot);

        // Determinar estado del slot
        BookingStatus? status; // null = disponible
        List<BookingPlayer> players = [];
        
        if (booking != null) {
          status = booking.status;
          players = booking.players.toList();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getSlotBackgroundColor(status),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSlotBorderColor(status),
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTap: booking != null ? () => _handleSlotTap(context, booking) : null,
              child: Row(
                children: [
                  // Hora en columna fija
                  SizedBox(
                    width: 60,
                    child: Text(
                      timeSlot,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(status),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Contenido expandible
                  Expanded(
                    child: players.isNotEmpty 
                        ? Text(
                            _formatPlayersText(players),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getSubtextColor(status),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            'Disponible',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getSubtextColor(status), 
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Status/Botón en ancho fijo
                  SizedBox(
                    width: 110,
                    child: _buildActionWidget(status, timeSlot),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // NAVEGACIÓN DE FECHAS
  // ============================================================================

  void _goToPreviousDate(BookingProvider provider) {
    if (provider.canGoToPreviousDate) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextDate(BookingProvider provider) {
    if (provider.canGoToNextDate) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showDateSelector(BuildContext context, BookingProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccionar Fecha',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ...provider.availableDates.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                final isSelected = index == provider.currentDateIndex;
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2E7AFF) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  title: Text(_formatDate(date)),
                  subtitle: Text(_getDayName(date)),
                  trailing: isSelected 
                      ? const Icon(Icons.check, color: Color(0xFF2E7AFF))
                      : null,
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // MÉTODOS DE UTILIDAD Y COLORES - 🔧 CORREGIDOS (solo colores que existen)
  // ============================================================================

  Color _getSlotBackgroundColor(BookingStatus? status) {
    switch (status) {
      case BookingStatus.complete:
        return const Color(0xFF2E7AFF); // 🔧 HARDCODE (AppColors.confirmed NO EXISTE)
      case BookingStatus.incomplete:
        return AppColors.incomplete; // ✅ ESTE SÍ EXISTE
      default:
        return const Color(0xFFE8F4F9); // 🔧 HARDCODE (AppColors.available NO EXISTE)
    }
  }

  Color _getSlotBorderColor(BookingStatus? status) {
    switch (status) {
      case BookingStatus.complete:
        return const Color(0xFF1a5ce6); // 🔧 HARDCODE (AppColors.confirmedBorder NO EXISTE)
      case BookingStatus.incomplete:
        return AppColors.incompleteBorder; // ✅ ESTE SÍ EXISTE
      default:
        return const Color(0xFF2E7AFF).withOpacity(0.2); // 🔧 HARDCODE
    }
  }

  Color _getTextColor(BookingStatus? status) {
    switch (status) {
      case BookingStatus.complete:
        return Colors.white; // 🔧 HARDCODE (AppColors.confirmedText NO EXISTE)
      case BookingStatus.incomplete:
        return AppColors.incompleteText; // ✅ ESTE SÍ EXISTE
      default:
        return Colors.black87; // 🔧 HARDCODE
    }
  }

  Color _getSubtextColor(BookingStatus? status) {
    switch (status) {
      case BookingStatus.complete:
        return Colors.white.withOpacity(0.9); // 🔧 HARDCODE
      case BookingStatus.incomplete:
        return AppColors.incompleteText.withOpacity(0.7); // ✅ ESTE SÍ EXISTE
      default:
        return Colors.grey[600]!; // Para disponible
    }
  }

  String _getStatusText(BookingStatus? status) {
    switch (status) {
      case BookingStatus.complete:
        return 'Completa';
      case BookingStatus.incomplete:
        return 'Incompleta';
      default:
        return 'Disponible';
    }
  }

  Widget _buildNoSlotsAvailable(BuildContext context, BookingProvider provider) {
    final isToday = provider.selectedDate.day == DateTime.now().day;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              isToday 
                  ? 'No hay horarios disponibles para hoy'
                  : 'No hay horarios disponibles para esta fecha',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isToday && provider.canGoToNextDate) ...[
              GestureDetector(
                onTap: () => provider.nextDate(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7AFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver reservas de mañana',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPlayersText(List<BookingPlayer> players) {
    if (players.isEmpty) return '';
    
    // Tomar el primer jugador (quien hace la reserva)
    final mainPlayer = players.first.name;
    final additionalCount = players.length - 1;
    
    if (additionalCount > 0) {
      return '$mainPlayer +$additionalCount';
    } else {
      return mainPlayer;
    }
  }

  Widget _buildActionWidget(BookingStatus? status, String timeSlot) {
    switch (status) {
      case BookingStatus.complete:
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7AFF), // 🔧 HARDCODE (AppColors.confirmed NO EXISTE)
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, color: Colors.white, size: 14), // 🔧 HARDCODE
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Reservada',
                  style: TextStyle(
                    color: Colors.white, // 🔧 HARDCODE (AppColors.confirmedText NO EXISTE)
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

      case BookingStatus.incomplete:
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.incomplete, // ✅ ESTE SÍ EXISTE
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, color: AppColors.incompleteText, size: 14), // ✅ ESTE SÍ EXISTE
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Incompleta',
                  style: TextStyle(
                    color: AppColors.incompleteText, // ✅ ESTE SÍ EXISTE
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

      default:
        return SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () => _handleReserveSlot(context, timeSlot),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Reservar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    }
  }

  // ============================================================================
  // MÉTODOS DE FORMATO
  // ============================================================================

  String _formatDate(DateTime date) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month]}';
  }

  String _getDayName(DateTime date) {
    const days = [
      '', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    return days[date.weekday];
  }

  // ============================================================================
  // HANDLERS DE EVENTOS
  // ============================================================================

  void _handleAddReservation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de agregar reserva próximamente'),
        backgroundColor: Color(0xFF2E7AFF),
      ),
    );
  }

  /// MÉTODO PRINCIPAL - Muestra el modal nativo de reservas Flutter-Firebase
  void _handleReserveSlot(BuildContext context, String timeSlot) async {
    final provider = context.read<BookingProvider>();
    final courtName = AppConstants.getCourtName(provider.selectedCourtId);
    
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevenir cierre accidental
      builder: (context) => ReservationFormModal(
        courtId: provider.selectedCourtId,
        courtName: courtName,
        date: _formatDateForSystem(provider.selectedDate),
        timeSlot: timeSlot,
        sport: 'PADEL', // 🔧 Para páginas de pádel
      ),
    );
  }

  /// Método original para WebView (backup - no se usa actualmente)
  Future<void> _showGASWebView(
    BuildContext context,
    BookingProvider provider, 
    String timeSlot
  ) async {
    final userEmail = await UserService.getCurrentUserEmail();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationWebView(
          userEmail: userEmail,
          courtId: provider.selectedCourtId,
          date: _formatDateForGAS(provider.selectedDate),
          timeSlot: timeSlot,
        ),
      ),
    );
  }

  String _formatDateForSystem(DateTime date) {
    // Formato YYYY-MM-DD para sistema interno
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateForGAS(DateTime date) {
    // Formato YYYY-MM-DD que espera el sistema GAS
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _handleSlotTap(BuildContext context, Booking? booking) {
    if (booking != null) {
      // Mostrar detalles de la reserva
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reserva ${booking.timeSlot}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancha: ${AppConstants.getCourtName(booking.courtId)}'),  // ← CAMBIADO
              Text('Fecha: ${_formatDate(context.read<BookingProvider>().selectedDate)}'),
              Text('Estado: ${_getStatusText(booking.status)}'),
              const SizedBox(height: 8),
              const Text('Jugadores:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...booking.players.map((player) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${player.name}'),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }
}
