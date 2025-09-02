// lib/presentation/pages/golf_reservations_page.dart
import 'package:cgp_reservas/core/services/firebase_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as AppAuthProvider;
import '../providers/booking_provider.dart';
import '../widgets/booking/animated_compact_stats.dart';
import '../widgets/booking/reservation_form_modal.dart';
import '../widgets/booking/reservation_webview.dart';
import '../widgets/common/date_navigation_header.dart';
import '../../core/constants/golf_constants.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/golf_theme.dart';
import '../../data/services/email_service.dart';
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      
      // CAMBIAR: En lugar del método anterior
      provider.initializeGolfDates(); // Usar la nueva lógica de ventana deslizante
      
      provider.fetchUsers();
      provider.selectCourt('golf_tee_1');
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
      // backgroundColor: GolfColors.primaryGreenLight,
      backgroundColor: const Color(0xFFE8F5E8),
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
          // color: GolfColors.primaryGreen,
          color: const Color(0xFF4CAF50),
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
                // backgroundColor: GolfColors.primaryGreen,
                backgroundColor: const Color(0xFF4CAF50),
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
              // Header Hoyo 1 - Verde estándar
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50), // Verde estándar más contrastante
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
              // Header Hoyo 10 - Verde azulado para contraste
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF00796B), // Verde azulado contrastante
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

  // Nuevo método en la clase _GolfReservationsPageState
  Widget _buildAddPlayerModal(BuildContext context, List<BookingPlayer> allUsers, List<BookingPlayer> bookedPlayers) {
    final bookedPlayerIds = bookedPlayers.map((p) => p.id).toSet();
    final availablePlayers = allUsers.where((user) => !bookedPlayerIds.contains(user.id)).toList();

    return AlertDialog(
      title: const Text('Seleccionar jugador'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availablePlayers.length,
          itemBuilder: (context, index) {
            final player = availablePlayers[index];
            return ListTile(
              title: Text(player.name),
              onTap: () => Navigator.of(context).pop(player),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildHoyoTimeSlots(BuildContext context, BookingProvider provider, String hoyoId, 
                          List<String> timeSlots, bool isHoyo10) {
    final now = DateTime.now();
    final selectedDate = provider.selectedDate;
    final isToday = selectedDate.year == now.year && 
                    selectedDate.month == now.month && 
                    selectedDate.day == now.day;

    // Filtrar horarios suspendidos para Hoyo 10
    List<String> availableSlots = timeSlots;
    if (isHoyo10) {
      availableSlots = timeSlots.where((slot) => !GolfConstants.isHoyo10Suspended(slot)).toList();
      // availableSlots = timeSlots; // Sin filtro por ahora
    }

    // NUEVO: Filtrar horarios pasados si es hoy
    if (isToday) {
      availableSlots = availableSlots.where((slot) {
        final slotTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          int.parse(slot.split(':')[0]),
          int.parse(slot.split(':')[1]),
        );
        return slotTime.isAfter(now);
      }).toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = availableSlots[index];
        
        // Búsqueda directa sin filtros previos
        Booking? booking;
        for (var b in provider.bookings) {  // Usar bookings en lugar de currentBookings
          if (b.courtId == hoyoId && 
              b.timeSlot == timeSlot && 
              b.date == _formatDateForSystem(selectedDate)) {
            booking = b;
            break;
          }
        }

        if (hoyoId == 'golf_tee_10') {
          print('DEBUG Hoyo 10 - TimeSlot: $timeSlot');
          print('DEBUG Available bookings: ${provider.currentBookings.length}');
          for (var b in provider.currentBookings) {
            print('  - Booking: courtId=${b.courtId}, timeSlot=${b.timeSlot}, date=${b.date}');
          }
          print('DEBUG Expected date: ${_formatDateForSystem(selectedDate)}');
          print('DEBUG Found booking for $timeSlot: ${booking != null}');
        }

        // Determinar número de jugadores
        int playerCount = 0;
        BookingStatus? status;
        List<BookingPlayer> players = [];

        if (booking != null) {
          playerCount = booking.players.length;
          players = booking.players.toList();
          
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
              color: _getGolfSlotBackgroundColor(playerCount, false),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _getGolfSlotBorderColor(playerCount, false),
                width: 1,
              ),
            ),
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hora
                  Text(
                    timeSlot,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getGolfTextColor(playerCount, false),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Estado/Acción
                  if (playerCount == 4)
                    GestureDetector(
                      onTap: () => _showCompleteSlotInfo(context, booking!),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$playerCount/4',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getGolfTextColor(playerCount, false),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Reservada',
                            style: TextStyle(
                              fontSize: 9,
                              color: _getGolfTextColor(playerCount, false),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (playerCount > 0) ...[
                          Text(
                            '$playerCount/4',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getGolfTextColor(playerCount, false),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${4 - playerCount} disponibles',
                            style: TextStyle(
                              fontSize: 9,
                              color: _getGolfTextColor(playerCount, false),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                        ],
                        // Reemplaza el GestureDetector que está en el bloque 'else'
                        GestureDetector(
                          onTap: () {
                            if (playerCount == 0) {
                              // Slot vacío - crear nueva reserva
                              _handleReserveSlot(context, hoyoId, timeSlot);
                            } else if (playerCount < 4) {
                              // Slot incompleto - usar el modal mejorado para unirse
                              _handleSlotTap(context, booking!);
                            } else {
                              // Slot completo - mostrar información detallada
                              _showCompleteSlotInfo(context, booking!);
                            }
                          },
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
                        )
                      ],
                    )
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

  Future<void> _handleAddPlayerToBooking(BuildContext context, Booking booking) async {
    final provider = context.read<BookingProvider>();

    // ✅ 1. Primero, asegura que los datos estén cargados antes de cualquier navegación
    if (provider.users == null || provider.users!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando usuarios... Por favor, espere.'),
        ),
      );
      await provider.fetchUsers();
      
      // Si la carga sigue fallando, notifica y detén
      if (provider.users == null || provider.users!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar los usuarios. Intente de nuevo.'),
          ),
        );
        return;
      }
    }

    // ✅ 2. Abre el modal de forma segura, esperando a que el usuario interactúe
    final selectedPlayer = await showDialog<BookingPlayer>(
      context: context,
      builder: (context) => _buildAddPlayerModal(context, provider.users!, booking.players)
    );
    
    // ✅ 3. Si se selecciona un jugador, realiza la acción y muestra un mensaje
    if (selectedPlayer != null) {
      await provider.addPlayerToBooking(booking.id!, selectedPlayer.id, selectedPlayer.name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jugador agregado con éxito'))
      );
    }
  }

  String _formatDateForSystem(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

// Método para terminar despliegue de pantalla para 'hoy'
DateTime _getSmartInitialDate() {
  final now = DateTime.now();
  final lastSlot = GolfConstants.DEFAULT_TIME_SLOTS.last;
  final parts = lastSlot.split(':');
  final lastHour = int.parse(parts[0]);
  final lastMinutes = int.parse(parts[1]);
    
  final lastSlotToday = DateTime(now.year, now.month, now.day, lastHour, lastMinutes);
    
  return now.isAfter(lastSlotToday) ? now.add(Duration(days: 1)) : now;
}

// Método mejorado para slots incompletos
Future<void> _handleSlotTap(BuildContext context, Booking booking) async {
  // Crear lista de jugadores actuales con viñetas
  final currentPlayers = booking.players.map((player) => '• ${player.name}').join('\n');
  final remainingSlots = 4 - booking.players.length - 1;
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.group_add, color: Color(0xFF4CAF50)),
          SizedBox(width: 8),
          Text('Unirse a Reserva'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del slot
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.courtId == 'golf_tee_1' ? 'Hoyo 1' : 'Hoyo 10'} - ${booking.timeSlot}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Espacios: ${booking.players.length}/4 ocupados',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Jugadores actuales
          Text(
            'Jugadores confirmados:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currentPlayers,
              style: TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(height: 16),
          
          // Información de espacios disponibles
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quedarán $remainingSlots espacio${remainingSlots > 1 ? 's' : ''} disponible${remainingSlots > 1 ? 's' : ''} después de unirte',
                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: Text('Confirmar Reserva'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    final provider = context.read<BookingProvider>();
    final authProvider = context.read<AppAuthProvider.AuthProvider>();
    final userEmail = authProvider.currentUserEmail;
    final userName = authProvider.currentUserName;
    
    if (userEmail != null && userName != null && authProvider.isUserValidated) {
      // Verificar duplicados
      final isAlreadyInBooking = booking.players.any((player) => player.id == userEmail);
      if (isAlreadyInBooking) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ya eres parte de esta reserva')),
        );
        return;
      }
      
      // Agregar jugador
      await provider.addPlayerToBooking(booking.id!, userEmail, userName);
      
      // AGREGAR: Envío de correo de confirmación
      try {
        // Obtener la reserva actualizada para el correo
        final updatedBooking = provider.bookings.firstWhere((b) => b.id == booking.id);
        await EmailService.sendBookingConfirmation(updatedBooking);
      } catch (emailError) {
        print('Error enviando correo: $emailError');
        // No mostrar error al usuario, el correo es secundario
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName se unió a la reserva con éxito')),
      );
    }
  }
}

// Nuevo método para mostrar información de slots completos
void _showCompleteSlotInfo(BuildContext context, Booking booking) {
  final playersList = booking.players.map((player) => '• ${player.name}').join('\n');
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.group, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Reserva Completa'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del slot
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.courtId == 'golf_tee_1' ? 'Hoyo 1' : 'Hoyo 10'} - ${booking.timeSlot}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Reserva completa (4/4 jugadores)',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Lista de jugadores
          Text(
            'Jugadores confirmados:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Text(
              playersList,
              style: TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(height: 16),
          
          // Estado de la reserva
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                SizedBox(width: 8),
                Text(
                  'Esta reserva está confirmada y completa',
                  style: TextStyle(fontSize: 12, color: Colors.green[800]),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: Text('Cerrar'),
        ),
      ],
    ),
  );
}
}