// lib/presentation/pages/golf_reservations_page.dart
import 'package:cgp_reservas/core/services/firebase_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking/animated_compact_stats.dart';
import '../widgets/booking/reservation_form_modal.dart';
import '../widgets/booking/reservation_webview.dart';
import '../widgets/common/date_navigation_header.dart';
// import '../../core/constants/golf_constants.dart';
import '../../core/services/user_service.dart';
// import '../../core/theme/golf_theme.dart';
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

    // VERIFICACIÓN DE AUTENTICACIÓN AL INICIO
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print('=== VERIFICACIÓN INICIAL GOLF PAGE ===');
      print('Firebase user en initState: ${firebaseUser?.uid ?? "NULL"}');
      print('Firebase user email: ${firebaseUser?.email ?? "NULL"}');
      
      if (firebaseUser == null) {
        print('ERROR: Usuario no autenticado en Firebase, redirigiendo a login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Redirigiendo al login...'),
            backgroundColor: Colors.red,
          ),
        );
        // Redirigir al login después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        });
        return;
      }
      
      // Resto del código existente...
      final provider = context.read<BookingProvider>();
      provider.fetchUsers();
      print('Golf INIT: provider.selectedCourtId = ${provider.selectedCourtId}');
      provider.selectCourt('golf_tee_1');
      print('Golf INIT: Inicializado para vista combinada');
    });

    _pageController = PageController(
      initialPage: context.read<BookingProvider>().currentDateIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      
      // Agregar esta línea para cargar los usuarios
      provider.fetchUsers();
      
      print('⛳ GOLF INIT: provider.selectedCourtId = ${provider.selectedCourtId}');
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
    final availableTimeSlots = [
      '07:00', '07:12', '07:24', '07:36', '07:48',
      '08:00', '08:12', '08:24', '08:36', '08:48',
      '09:00', '09:12', '09:24', '09:36', '09:48',
      '10:00', '10:12', '10:24', '10:36', '10:48',
      '11:00', '11:12', '11:24', '11:36', '11:48',
      '12:00', '12:12', '12:24', '12:36', '12:48',
      '13:00', '13:12', '13:24', '13:36', '13:48',
      '14:00', '14:12', '14:24', '14:36', '14:48',
      '15:00', '15:12', '15:24', '15:36', '15:48',
      '16:00', '16:12', '16:24', '16:36', '16:48',
    ];

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
      // availableSlots = timeSlots.where((slot) => !GolfConstants.isHoyo10Suspended(slot)).toList();
      availableSlots = timeSlots; // Sin filtro por ahora
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
            child: GestureDetector(
              onTap: booking != null ? () => _handleSlotTap(context, booking!) : null,
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
                    Column(
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
                              // Si el slot está vacío, usa la función para crear una nueva reserva
                              _handleReserveSlot(context, hoyoId, timeSlot);
                            } else {
                              // Si el slot está incompleto, usa la función para modificar la reserva existente
                              _handleSlotTap(context, booking!);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              // color: GolfColors.primaryGreen,
                              color: const Color(0xFF4CAF50),
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
        // return GolfColors.primaryGreenLight; // Verde claro para incompletas
        return const Color(0xFFE8F5E8); // Verde claro para incompletas
      case 4:
        // return GolfColors.primaryGreen; // Verde oscuro para reservadas
        return const Color(0xFF4CAF50); // Verde oscuro para reservadas
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
        // return GolfColors.primaryGreen.withOpacity(0.5);
        return const Color(0xFF2E7D32);
      case 4:
        // return GolfColors.primaryGreenDark;
        return const Color(0xFF2E7D32);
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
        // return GolfColors.primaryGreenDark;
        return const Color(0xFF2E7D32);
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
                      // color: isSelected ? GolfColors.primaryGreen : Colors.grey[100],
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[100],
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
                      // ? const Icon(Icons.check, color: GolfColors.primaryGreen)
                      ? const Icon(Icons.check, color: const Color(0xFF4CAF50))
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
                    // color: GolfColors.primaryGreen,
                    color: const Color(0xFF4CAF50),
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
        // backgroundColor: GolfColors.primaryGreen,
        backgroundColor: const Color(0xFF4CAF50),
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

  Future<void> _handleSlotTap(BuildContext context, Booking booking) async {
    final provider = context.read<BookingProvider>();

    print('=== INICIO DEBUG AUTENTICACIÓN ===');
    
    // 1. VERIFICAR ESTADO INICIAL DE FIREBASE AUTH
    print('DEBUG - Firebase Auth inicializado: ${FirebaseAuth.instance.app != null}');
    print('DEBUG - Firebase Auth current user (inicial): ${FirebaseAuth.instance.currentUser?.uid ?? "NULL"}');
    print('DEBUG - Firebase Auth current user email: ${FirebaseAuth.instance.currentUser?.email ?? "NULL"}');
    
    String? currentUserId;
    String? currentUserName;
    
    try {
      // 1. Verificar el usuario actual directamente
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print('DEBUG - Firebase user objeto: ${firebaseUser != null ? "EXISTS" : "NULL"}');
      
      if (firebaseUser != null) {
        currentUserId = firebaseUser.uid;
        currentUserName = firebaseUser.displayName ?? firebaseUser.email ?? 'Usuario';
        print('DEBUG - Usuario obtenido de FirebaseAuth: $currentUserId');
        print('DEBUG - Nombre usuario: $currentUserName');
        print('DEBUG - Email usuario: ${firebaseUser.email}');
        print('DEBUG - Usuario verificado: ${firebaseUser.emailVerified}');
      } else {
        print('DEBUG - firebaseUser es NULL, intentando forzar reload...');
        
        // 2. Intentar forzar un reload del usuario actual
        try {
          await FirebaseAuth.instance.currentUser?.reload();
          final reloadedUser = FirebaseAuth.instance.currentUser;
          print('DEBUG - Usuario después de reload: ${reloadedUser?.uid ?? "STILL NULL"}');
          
          if (reloadedUser != null) {
            currentUserId = reloadedUser.uid;
            currentUserName = reloadedUser.displayName ?? reloadedUser.email ?? 'Usuario';
            print('DEBUG - Usuario obtenido tras reload: $currentUserId');
          }
        } catch (reloadError) {
          print('ERROR en reload: $reloadError');
        }
      }
      
      // 3. Si sigue siendo null, intentar escuchar cambios de estado
      if (currentUserId == null) {
        print('DEBUG - Intentando escuchar authStateChanges...');
        try {
          final authState = await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 5),
          );
          print('DEBUG - AuthState user: ${authState?.uid ?? "NULL"}');
          
          if (authState != null) {
            currentUserId = authState.uid;
            currentUserName = authState.displayName ?? authState.email ?? 'Usuario';
            print('DEBUG - Usuario obtenido de authStateChanges: $currentUserId');
          }
        } catch (timeoutError) {
          print('ERROR en authStateChanges timeout: $timeoutError');
        }
      }
      
    } catch (e) {
      print('ERROR GENERAL al obtener usuario: $e');
      print('ERROR Stack trace: ${e.toString()}');
    }

    print('=== RESULTADO FINAL DEBUG ===');
    print('DEBUG - currentUserId final: ${currentUserId ?? "NULL"}');
    print('DEBUG - currentUserName final: ${currentUserName ?? "NULL"}');
    
    // 2. VERIFICAR SI SE PUDO IDENTIFICAR AL USUARIO
    if (currentUserId == null) {
      print('ERROR CRÍTICO - No se pudo identificar al usuario después de todos los intentos');
      
      // Mostrar información de diagnóstico al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error de autenticación. Su sesión puede haber expirado.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Recargar App',
            textColor: Colors.white,
            onPressed: () {
              // Forzar logout y recarga completa
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ),
      );
      return;
    }

    print('=== CONTINUANDO CON LÓGICA DE RESERVA ===');
    print('DEBUG - Booking ID: ${booking.id}');
    print('DEBUG - Jugadores actuales: ${booking.players.length}');
    print('DEBUG - Provider users count: ${provider.users?.length ?? 0}');

    // 3. VERIFICAR SI EL JUGADOR YA ESTÁ EN LA RESERVA
    final isPlayerAlreadyInBooking = booking.players.any((player) {
      print('DEBUG - Comparando player.id: ${player.id} con currentUserId: $currentUserId');
      return player.id == currentUserId;
    });

    if (isPlayerAlreadyInBooking) {
      print('DEBUG - Usuario ya está en la reserva');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya eres parte de esta reserva.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 4. VERIFICAR CAPACIDAD MÁXIMA
    if (booking.players.length >= 4) {
      print('DEBUG - Reserva ya está completa');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta reserva ya está completa.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    print('DEBUG - Mostrando diálogo de confirmación');
    
    // 5. PEDIR CONFIRMACIÓN
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: Text(
          '¿Deseas unirte a esta reserva?\n\n'
          'Horario: ${booking.timeSlot}\n'
          'Jugadores actuales: ${booking.players.length}/4\n'
          'Quedarán ${3 - booking.players.length} espacios disponibles'
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    print('DEBUG - Usuario confirmó: ${confirmed == true}');

    // 6. SI CONFIRMA, AGREGAR EL JUGADOR
    if (confirmed == true) {
      try {
        print('DEBUG - Iniciando proceso de agregar jugador...');
        
        // Buscar usuario en la lista del provider
        BookingPlayer? currentUserData;
        
        if (provider.users != null && provider.users!.isNotEmpty) {
          try {
            currentUserData = provider.users!.firstWhere(
              (user) => user.id == currentUserId,
            );
            print('DEBUG - Usuario encontrado en provider: ${currentUserData.name}');
          } catch (e) {
            print('DEBUG - Usuario no encontrado en provider, creando temporal...');
            currentUserData = BookingPlayer(
              id: currentUserId!,
              name: currentUserName ?? 'Usuario Desconocido',
            );
          }
        } else {
          print('DEBUG - Provider users está vacío o null');
          currentUserData = BookingPlayer(
            id: currentUserId!,
            name: currentUserName ?? 'Usuario Desconocido',
          );
        }

        print('DEBUG - Llamando addPlayerToBooking con:');
        print('  - bookingId: ${booking.id}');
        print('  - playerId: ${currentUserData.id}');
        print('  - playerName: ${currentUserData.name}');

        await provider.addPlayerToBooking(
          booking.id!, 
          currentUserData.id, 
          currentUserData.name
        );
        
        print('DEBUG - addPlayerToBooking completado exitosamente');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido a la reserva con éxito.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
      } catch (e) {
        print('ERROR al agregar jugador: $e');
        print('ERROR Stack trace completo: ${e.toString()}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al unirse a la reserva: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    
    print('=== FIN DEBUG AUTENTICACIÓN ===');
  }
}