// lib/presentation/pages/admin_reservations_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Providers
import '../providers/booking_provider.dart';

// Entities & Models
import '../../domain/entities/booking.dart';
import '../../domain/entities/user.dart';

// Utilities
import '../../core/constants/app_constants.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({Key? key}) : super(key: key);

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedSport = 'all';
  final TextEditingController _playerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = _getSmartInitialDate(); 
    // PERF: print('DEBUG Admin: Fecha inicial inteligente: $_selectedDate');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReservations(_selectedDate);
      
      // FORZAR CARGA DE USUARIOS
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.fetchUsers().then((_) {
        // PERF: print('DEBUG Admin: fetchUsers completado');
        // PERF: print('DEBUG Admin: Usuarios disponibles: ${bookingProvider.users?.length ?? 0}');
      }).catchError((error) {
        // PERF: print('DEBUG Admin: Error en fetchUsers: $error');
      });
    });
  }

  DateTime _getSmartInitialDate() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    // Si es antes de las 8:00 AM, mostrar hoy
    if (currentTimeInMinutes < 8 * 60) {
        return DateTime(now.year, now.month, now.day);
    }
    
    // Obtener Ãºltimo horario segÃºn los deportes disponibles
    final lastGolfSlot = AppConstants.getLastTimeSlotForSport('golf');
    final lastPadelSlot = AppConstants.getLastTimeSlotForSport('padel');
    final lastTennisSlot = AppConstants.getLastTimeSlotForSport('tennis');
    
    // Usar el Ãºltimo horario mÃ¡s tardÃ­o como referencia
    final latestEndTime = [lastGolfSlot, lastPadelSlot, lastTennisSlot]
        .map((time) {
            final parts = time.split(':');
            return int.parse(parts[0]) * 60 + int.parse(parts[1]);
        })
        .reduce((a, b) => a > b ? a : b);
    
    // Si ya pasÃ³ la mayorÃ­a de horarios del dÃ­a, mostrar maÃ±ana
    if (currentTimeInMinutes > (latestEndTime - 120)) { // 2 horas antes del Ãºltimo horario
        return DateTime(now.year, now.month, now.day + 1);
    }
    
    // Caso por defecto: mostrar hoy
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _playerSearchController.dispose();
    super.dispose();
  }

  void _fetchReservations(DateTime date) {
    // PERF: print('DEBUG Admin: _fetchReservations llamado para fecha: $date');
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    // Normalizar fecha (sin hora)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    // PERF: print('DEBUG Admin: Fecha original: $date');
    // PERF: print('DEBUG Admin: Fecha normalizada: $normalizedDate');

    bookingProvider.fetchBookingsForSelectedDate(normalizedDate);
    // PERF: print('DEBUG Admin: fetchBookingsForSelectedDate ejecutado con fecha normalizada');
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchReservations(_selectedDate);
    }
  }

  void _goToPreviousDay() {
    final newDate = _selectedDate.subtract(const Duration(days: 1));
    if (newDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
      setState(() {
        _selectedDate = newDate;
      });
      _fetchReservations(_selectedDate);
    }
  }

  void _goToNextDay() {
    final newDate = _selectedDate.add(const Duration(days: 1));
    if (newDate.isBefore(DateTime.now().add(const Duration(days: 4)))) {
      setState(() {
        _selectedDate = newDate;
      });
      _fetchReservations(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel de AdministraciÃ³n',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),

      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingProvider.error != null) {
            return Center(child: Text('Error: ${bookingProvider.error}'));
          }

          final filteredBookings = bookingProvider.bookings.where((booking) {
            // PERF: print('DEBUG Filter: Comparando booking.date="${booking.date}" con _selectedDate="${DateFormat('yyyy-MM-dd').format(_selectedDate)}"');
            
            final bookingDate = DateFormat('yyyy-MM-dd').parse(booking.date);
            final isDateMatch = bookingDate.day == _selectedDate.day &&
                bookingDate.month == _selectedDate.month &&
                bookingDate.year == _selectedDate.year;

            final playerSearchQuery = _playerSearchController.text.toLowerCase();
            final isPlayerMatch = booking.players.any((player) =>
                player.name.toLowerCase().contains(playerSearchQuery));

            final isSportMatch = _selectedSport == 'all' ||
                AppConstants.getCourtSport(booking.courtId) == _selectedSport;

            // PERF: print('DEBUG Filter: isDateMatch=$isDateMatch, isSportMatch=$isSportMatch, isPlayerMatch=$isPlayerMatch');

            return isDateMatch && isSportMatch && isPlayerMatch;
          }).toList();

          // PERF: print('DEBUG UI: Consumer reconstruyendo con ${filteredBookings.length} reservas filtradas');
          // PERF: print('DEBUG UI: bookingProvider.isLoading = ${bookingProvider.isLoading}');
          // PERF: print('DEBUG UI: Lista de reservas: ${filteredBookings.map((b) => "${b.courtId}-${b.timeSlot}").toList()}');

          return Column(
            children: [
              // BÃºsqueda por jugador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _playerSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre de jugador',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              // Filtros de fecha y deporte con flechas
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dropdown de deportes a la izquierda
                    DropdownButton<String>(
                      value: _selectedSport,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todos')),
                        DropdownMenuItem(value: 'padel', child: Text('Pádel')),
                        DropdownMenuItem(value: 'tennis', child: Text('Tenis')),
                        DropdownMenuItem(value: 'golf', child: Text('Golf')),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                            _selectedSport = newValue!;
                        });
                      },
                    ),
                    // NavegaciÃ³n de fechas centrada
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: _selectedDate.isAtSameMomentAs(DateTime.now().subtract(const Duration(days: 1)))
                              ? null
                              : _goToPreviousDay,
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: _selectedDate.isAtSameMomentAs(DateTime.now().add(const Duration(days: 3)))
                              ? null
                              : _goToNextDay,
                        ),
                      ],
                    ),
                    // Espaciador para balancear el layout
                    const SizedBox(width: 80),
                    ],
                  ),
                ),
                // Lista de Reservas
                Expanded(
                  child: filteredBookings.isEmpty
                      ? const Center(child: Text('No hay reservas para esta fecha y deporte.'))
                      : ListView.builder(
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return _buildBookingTile(context, booking, bookingProvider);
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingTile(BuildContext context, Booking booking, BookingProvider bookingProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('${AppConstants.getCourtName(booking.courtId)} - ${booking.timeSlot}'),
        subtitle: Text('Jugadores: ${booking.players.map((p) => p.name).join(', ')}'),
        trailing: Text(DateFormat('dd MMM').format(DateFormat('yyyy-MM-dd').parse(booking.date))),
        onTap: () => _showEditBookingModal(context, booking, bookingProvider),
      ),
    );
  }

  void _showEditBookingModal(BuildContext context, Booking booking, BookingProvider bookingProvider) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: _EditBookingModalContent(
              booking: booking,
              bookingProvider: bookingProvider,
            ),
          ),
        );
      },
    );
    _fetchReservations(_selectedDate);
  }
}

class _EditBookingModalContent extends StatefulWidget {
  final Booking booking;
  final BookingProvider bookingProvider;

  const _EditBookingModalContent({
    Key? key,
    required this.booking,
    required this.bookingProvider,
  }) : super(key: key);

  @override
  State<_EditBookingModalContent> createState() => _EditBookingModalContentState();
}

class _EditBookingModalContentState extends State<_EditBookingModalContent> {
  late List<BookingPlayer> _players;
  final TextEditingController _userSearchController = TextEditingController();
  final Random _random = Random();
  List<BookingPlayer> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.booking.players);
    
    // PERF: print('DEBUG Modal: Usuarios en provider: ${widget.bookingProvider.users?.length ?? "null"}');
    // PERF: print('DEBUG Modal: Provider instance: ${widget.bookingProvider}');
    
    // Cargar usuarios si no estÃ¡n disponibles - DIFERIDO
    if (widget.bookingProvider.users == null) {
      // PERF: print('DEBUG Modal: Cargando usuarios...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.bookingProvider.fetchUsers().then((_) {
          // PERF: print('DEBUG Modal: Usuarios cargados: ${widget.bookingProvider.users?.length ?? 0}');
          if (mounted) {
            setState(() {});
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  void _filterUsers(String query) {
    // PERF: print('DEBUG Buscar: "$query"');
    
    final allUsers = widget.bookingProvider.users;
    if (allUsers != null) {
      // PERF: print('DEBUG: Filtrando entre ${allUsers.length} usuarios');
        
      final filtered = allUsers
          .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
        
      // PERF: print('DEBUG: Encontrados ${filtered.length} usuarios');
      if (filtered.isNotEmpty) {
        // PERF: print('DEBUG: Primer resultado: "${filtered.first.name}" (ID: ${filtered.first.id})'); // â† AGREGAR ID AQUÃ
      }
        
      setState(() {
        _filteredUsers = filtered;
      });
    } else {
      // PERF: print('DEBUG: allUsers es null');
    }
  }

  void _addPlayer(BookingPlayer player) {
    // PERF: print('DEBUG _addPlayer: Intentando agregar ${player.name} (ID original: ${player.id})');
    // PERF: print('DEBUG _addPlayer: Jugadores actuales: ${_players.length}/4');
    
    // Usar el mismo generador de IDs que el resto del sistema
    BookingPlayer playerToAdd = player;
    
    if (player.id == null || player.id == 'null-uid' || player.id!.isEmpty) {
      // USAR EL MISMO FORMATO: '${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}'
      final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(999999)}';
      
      // Crear nuevo objeto con ID Ãºnico
      playerToAdd = BookingPlayer(
        id: uniqueId,
        name: player.name,
        email: player.email,
        phone: player.phone,
      );
      
      // PERF: print('DEBUG _addPlayer: ID Ãºnico generado: $uniqueId');
    }
    
    // Verificar que no exista duplicado (ahora con ID Ãºnico garantizado)
    final isDuplicate = _players.any((p) => p.id == playerToAdd.id);
    // PERF: print('DEBUG _addPlayer: Â¿Ya existe este ID? $isDuplicate');
    
    // Verificar condiciones de adiciÃ³n
    if (_players.length < 4 && !isDuplicate) {
      setState(() {
        _players.add(playerToAdd);
      });
      _userSearchController.clear();
      _filteredUsers = [];
      // PERF: print('DEBUG _addPlayer: Jugador agregado exitosamente con ID: ${playerToAdd.id}. Total: ${_players.length}');
    } else {
      // PERF: print('DEBUG _addPlayer: NO se pudo agregar - ${isDuplicate ? "ID duplicado" : "LÃ­mite alcanzado (${_players.length}/4)"}');
    }
  }

  void _removePlayer(BookingPlayer player) {
    // PERF: print('DEBUG: Intentando eliminar jugador:');
    // PERF: print('  - Nombre: ${player.name}');
    // PERF: print('  - ID: ${player.id}');
    // PERF: print('DEBUG: IDs de todos los jugadores:');
    for (int i = 0; i < _players.length; i++) {
      // PERF: print('  - Jugador $i: ${_players[i].name} (ID: ${_players[i].id})');
    }

    setState(() {
      // _players.removeWhere((p) => p.name == player.name && p.email == player.email);
      _players.removeWhere((p) => p.id == player.id);
    });
  }

  Future<void> _saveChanges() async {
    await widget.bookingProvider.editBookingPlayers(
      bookingId: widget.booking.id!,
      updatedPlayers: _players,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _deleteBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar EliminaciÃ³n'),
        content: const Text('Â¿EstÃ¡s seguro de que deseas eliminar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.bookingProvider.deleteBooking(bookingId: widget.booking.id!);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Editar Reserva: ${AppConstants.getCourtName(widget.booking.courtId)}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Fecha: ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(widget.booking.date))}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          'Hora: ${widget.booking.timeSlot}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        // Lista de jugadores
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _players.length,
          itemBuilder: (context, index) {
            final player = _players[index];
            return ListTile(
              title: Text(player.name),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removePlayer(player),
              ),
            );
          },
        ),
        // BÃºsqueda de usuarios
        if (_players.length < 4) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _userSearchController,
            decoration: const InputDecoration(
              labelText: 'Buscar y agregar jugador',
              border: OutlineInputBorder(),
            ),
            onChanged: _filterUsers,
          ),
          if (_filteredUsers.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    title: Text(user.name),
                    onTap: () => _addPlayer(user),
                  );
                },
              ),
            ),
        ],
        const SizedBox(height: 20),
        // Botones de acciÃ³n
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Guardar Cambios'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _deleteBooking,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar Reserva'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

