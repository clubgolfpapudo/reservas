// lib/presentation/pages/golf_reservations_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking/animated_compact_stats.dart';
import '../widgets/booking/reservation_form_modal.dart';
import '../widgets/booking/reservation_webview.dart';
import '../widgets/common/date_navigation_header.dart';
import '../../core/constants/golf_constants.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/golf_theme.dart';
import '../../domain/entities/booking.dart';
import '../../../core/constants/app_constants.dart';

class GolfReservationsPage extends StatefulWidget {
  const GolfReservationsPage({Key? key}) : super(key: key);

  @override
  State<GolfReservationsPage> createState() => _GolfReservationsPageState();
}

class _GolfReservationsPageState extends State<GolfReservationsPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: context.read<BookingProvider>().currentDateIndex,
    );

    // Inicialización para Golf - ambos hoyos en una vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      print('⛳ GOLF INIT: provider.selectedCourtId = ${provider.selectedCourtId}');
      
      // Para golf no necesitamos seleccionar un hoyo específico ya que mostramos ambos
      provider.selectCourt('golf_tee_1');
      print('⛳ GOLF INIT: Inicializado para vista combinada');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GolfColors.primaryGreenLight,
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          return Column(
            children: [
              // Header con navegación de fechas
              DateNavigationHeader(
                title: 'Golf',
                selectedDate: bookingProvider.selectedDate,
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

              // Estadísticas compactas
              AnimatedCompactStats(
                bookings: bookingProvider.currentBookings,
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
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: GolfColors.primaryGreen,
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
                backgroundColor: GolfColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return _buildGolfTimeSlotsGrid(context, provider);
  }

  Widget _buildGolfTimeSlotsGrid(BuildContext context, BookingProvider provider) {
    final availableTimeSlots = GolfConstants.DEFAULT_TIME_SLOTS;

    if (availableTimeSlots.isEmpty) {
      return _buildNoSlotsAvailable(context, provider);
    }

    return Row(
      children: [
        // Hoyo 1 - Columna izquierda
        Expanded(
          child: Column(
            children: [
              // Header Hoyo 1
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: GolfColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.golf_course, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Hoyo 1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Lista de horarios Hoyo 1
              Expanded(
                child: _buildHoyoTimeSlots(context, provider, 'golf_tee_1', availableTimeSlots, false),
              ),
            ],
          ),
        ),

        // Divisor
        Container(
          width: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),

        // Hoyo 10 - Columna derecha
        Expanded(
          child: Column(
            children: [
              // Header Hoyo 10
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: GolfColors.primaryGreenDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.golf_course, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Hoyo 10',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Lista de horarios Hoyo 10
              Expanded(
                child: _buildHoyoTimeSlots(context, provider, 'golf_tee_10', availableTimeSlots, true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHoyoTimeSlots(BuildContext context, BookingProvider provider, String hoyoId, 
                            List<String> timeSlots, bool isHoyo10) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        final booking = provider.getBookingForTimeSlot(timeSlot); // Necesitaríamos filtrar por hoyoId
        final isSuspended = isHoyo10 && GolfConstants.isHoyo10Suspended(timeSlot);

        // Determinar número de jugadores
        int playerCount = 0;
        BookingStatus? status;
        List<BookingPlayer> players = [];

        if (booking != null && booking.courtId == hoyoId) {
          playerCount = booking.players.length;
          players = booking.players.toList();
          
          // Lógica específica de golf: solo 4 jugadores = Reservada, menos = Incompleta
          if (playerCount == 4) {
            status = BookingStatus.complete;
          } else if (playerCount >= 1) {
            status = BookingStatus.incomplete;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _getGolfSlotBackgroundColor(playerCount, isSuspended),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _getGolfSlotBorderColor(playerCount, isSuspended),
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTap: (!isSuspended && booking != null) ? () => _handleSlotTap(context, booking) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hora
                  Text(
                    timeSlot,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getGolfTextColor(playerCount, isSuspended),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Estado/Acción
                  if (isSuspended)
                    Text(
                      'Suspendido',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (playerCount > 0)
                    Column(
                      children: [
                        Text(
                          '$playerCount/4',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getGolfTextColor(playerCount, isSuspended),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          playerCount == 4 ? 'Reservada' : 'Incompleta',
                          style: TextStyle(
                            fontSize: 9,
                            color: _getGolfTextColor(playerCount, isSuspended),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () => _handleReserveSlot(context, hoyoId, timeSlot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GolfColors.primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Reservar',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Colores específicos para golf
  Color _getGolfSlotBackgroundColor(int playerCount, bool isSuspended) {
    if (isSuspended) {
      return Colors.grey[100]!;
    }
    
    switch (playerCount) {
      case 0:
        return Colors.white; // Sin reservas
      case 1:
      case 2:
      case 3:
        return GolfColors.primaryGreenLight; // Verde claro para incompletas
      case 4:
        return GolfColors.primaryGreen; // Verde oscuro para reservadas
      default:
        return Colors.white;
    }
  }

  Color _getGolfSlotBorderColor(int playerCount, bool isSuspended) {
    if (isSuspended) {
      return Colors.grey[300]!;
    }
    
    switch (playerCount) {
      case 0:
        return Colors.grey[300]!;
      case 1:
      case 2:
      case 3:
        return GolfColors.primaryGreen.withOpacity(0.5);
      case 4:
        return GolfColors.primaryGreenDark;
      default:
        return Colors.grey[300]!;
    }
  }

  Color _getGolfTextColor(int playerCount, bool isSuspended) {
    if (isSuspended) {
      return Colors.grey[500]!;
    }
    
    switch (playerCount) {
      case 0:
        return Colors.black87;
      case 1:
      case 2:
      case 3:
        return GolfColors.primaryGreenDark;
      case 4:
        return Colors.white;
      default:
        return Colors.black87;
    }
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
                      color: isSelected ? GolfColors.primaryGreen : Colors.grey[100],
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
                      ? const Icon(Icons.check, color: GolfColors.primaryGreen)
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

  Widget _buildNoSlotsAvailable(BuildContext context, BookingProvider provider) {
    final isToday = provider.selectedDate.day == DateTime.now().day;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.golf_course_outlined,
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
                    color: GolfColors.primaryGreen,
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
        backgroundColor: GolfColors.primaryGreen,
      ),
    );
  }

  /// Método principal - Muestra el modal de reservas para golf
  void _handleReserveSlot(BuildContext context, String hoyoId, String timeSlot) async {
    final provider = context.read<BookingProvider>();
    
    final hoyoName = hoyoId == 'golf_tee_1' ? 'Hoyo 1' : 'Hoyo 10';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReservationFormModal(
        courtId: hoyoId,
        courtName: hoyoName,
        date: _formatDateForSystem(provider.selectedDate),
        timeSlot: timeSlot,
        sport: 'GOLF',
      ),
    );
  }

  String _formatDateForSystem(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _handleSlotTap(BuildContext context, Booking? booking) {
    if (booking != null) {
      final hoyoName = booking.courtId == 'golf_tee_1' ? 'Hoyo 1' : 'Hoyo 10';
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reserva ${booking.timeSlot}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$hoyoName'),
              Text('Fecha: ${_formatDate(context.read<BookingProvider>().selectedDate)}'),
              Text('Jugadores: ${booking.players.length}/4'),
              Text('Estado: ${booking.players.length == 4 ? "Reservada" : "Incompleta"}'),
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