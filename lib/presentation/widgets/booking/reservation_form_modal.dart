// lib/presentation/widgets/booking/reservation_form_modal.dart - VALIDACIÓN COMPLETA + EMAILS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_user_service.dart';
import '../../../core/services/user_service.dart';
import '../../../domain/entities/booking.dart';

class ReservationFormModal extends StatefulWidget {
  final String courtId;
  final String courtName;
  final String date;
  final String timeSlot;

  const ReservationFormModal({
    Key? key,
    required this.courtId,
    required this.courtName,
    required this.date,
    required this.timeSlot,
  }) : super(key: key);

  @override
  State<ReservationFormModal> createState() => _ReservationFormModalState();
}

class _ReservationFormModalState extends State<ReservationFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  
  List<ReservationPlayer> _selectedPlayers = [];
  List<ReservationPlayer> _availablePlayers = [];
  List<ReservationPlayer> _filteredPlayers = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _searchController.addListener(_filterPlayers);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSlotAvailability();
      _filterPlayers();
    });
  }

  // 🔥 VALIDACIÓN INICIAL: Verificar disponibilidad al abrir modal
  void _checkInitialSlotAvailability() {
    final provider = context.read<BookingProvider>();
    final playerNames = _selectedPlayers.map((p) => p.name).toList();
    
    final validation = provider.canCreateBooking(
      widget.courtId, 
      widget.date, 
      widget.timeSlot, 
      playerNames
    );

    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.reason;
      });
      
      // Auto-cerrar si hay conflicto inicial
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _initializeForm() {
    print('🚀 MODAL: Inicializando formulario...');
    
    // Inicializar listas vacías
    _availablePlayers = [];
    _filteredPlayers = [];
    
    // 🔥 USUARIO DINÁMICO: Configurar usuario actual primero
    _setCurrentUser().then((_) {
      print('✅ MODAL: Usuario principal configurado, cargando desde Firebase...');
      // Después cargar usuarios desde Firebase
      _loadUsersFromFirebase();
    });
  }

  /// 🔥 NUEVO: Configurar usuario actual dinámicamente
  Future<void> _setCurrentUser() async {
    try {
      // Obtener usuario actual del servicio
      final currentEmail = await UserService.getCurrentUserEmail();
      final currentName = await UserService.getCurrentUserName();
      
      print('✅ MODAL: Usuario actual - $currentName ($currentEmail)');
      
      // Agregar como usuario principal (organizador)
      _selectedPlayers.add(ReservationPlayer(
        name: currentName,
        email: currentEmail,
        isMainBooker: true,
      ));
      
    } catch (e) {
      print('❌ MODAL: Error obteniendo usuario actual: $e');
      
      // Fallback de emergencia
      _selectedPlayers.add(ReservationPlayer(
        name: 'USUARIO TEMPORAL',
        email: 'temp@cgp.cl',
        isMainBooker: true,
      ));
    }
  }

  /// 🔥 CARGAR USUARIOS DESDE FIREBASE
  Future<void> _loadUsersFromFirebase() async {
    print('🚀 MODAL: Iniciando carga de usuarios desde Firebase...');
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar usuarios reales desde Firebase
      print('🔥 MODAL: Llamando a FirebaseUserService.getAllUsers()...');
      final usersData = await FirebaseUserService.getAllUsers();
      
      print('🔥 MODAL: Recibidos ${usersData.length} usuarios de Firebase');
      
      // Convertir a ReservationPlayer
      final users = usersData.map((userData) {
        return ReservationPlayer(
          name: userData['name'],
          email: userData['email'],
          isMainBooker: false,
        );
      }).toList();
      
      print('🔥 MODAL: Convertidos ${users.length} usuarios a ReservationPlayer');
      
      // Agregar usuarios especiales VISITA al final
      final visitUsers = [
        ReservationPlayer(name: 'VISITA1 PADEL', email: 'visita1@cgp.cl'),
        ReservationPlayer(name: 'VISITA2 PADEL', email: 'visita2@cgp.cl'),
        ReservationPlayer(name: 'VISITA3 PADEL', email: 'visita3@cgp.cl'),
        ReservationPlayer(name: 'VISITA4 PADEL', email: 'visita4@cgp.cl'),
      ];

      final allUsers = [...users, ...visitUsers];
      
      setState(() {
        _availablePlayers = allUsers;
        _isLoading = false;
      });

      print('✅ MODAL: ${allUsers.length} usuarios cargados en total (${users.length} Firebase + ${visitUsers.length} VISITA)');
      
      // Filtrar inmediatamente para mostrar usuarios
      _filterPlayers();
      
    } catch (e) {
      print('❌ MODAL: Error cargando usuarios: $e');
      
      // Fallback: usar usuarios de prueba EXPANDIDOS
      final fallbackUsers = [
        ReservationPlayer(name: 'ANA M BELMAR P', email: 'ana@buzeta.cl'),
        ReservationPlayer(name: 'CLARA PARDO B', email: 'clara@garciab.cl'),
        ReservationPlayer(name: 'JUAN F GONZALEZ P', email: 'juan@hotmail.com'),
        ReservationPlayer(name: 'FELIPE BENITEZ G', email: 'fgarciabenitez@gmail.com'),
        ReservationPlayer(name: 'PEDRO MARTINEZ L', email: 'pedro.martinez@example.com'),
        ReservationPlayer(name: 'MARIA GONZALEZ R', email: 'maria.gonzalez@example.com'),
        ReservationPlayer(name: 'CARLOS RODRIGUEZ M', email: 'carlos.rodriguez@example.com'),
        ReservationPlayer(name: 'LUIS FERNANDEZ B', email: 'luis.fernandez@example.com'),
        ReservationPlayer(name: 'SOFIA MARTINEZ T', email: 'sofia.martinez@example.com'),
        ReservationPlayer(name: 'DIEGO SANCHEZ L', email: 'diego.sanchez@example.com'),
        // Usuarios VISITA
        ReservationPlayer(name: 'VISITA1 PADEL', email: 'visita1@cgp.cl'),
        ReservationPlayer(name: 'VISITA2 PADEL', email: 'visita2@cgp.cl'),
        ReservationPlayer(name: 'VISITA3 PADEL', email: 'visita3@cgp.cl'),
        ReservationPlayer(name: 'VISITA4 PADEL', email: 'visita4@cgp.cl'),
      ];
      
      setState(() {
        _availablePlayers = fallbackUsers;
        _isLoading = false;
      });
      
      print('🔄 MODAL: Usando ${fallbackUsers.length} usuarios de fallback');
      _filterPlayers();
    }
  }

  // 🔥 MÉTODO FALTANTE: _filterPlayers
  void _filterPlayers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredPlayers = _availablePlayers
            .where((player) => 
                !_selectedPlayers.any((selected) => selected.email == player.email))
            .toList();
      } else {
        _filteredPlayers = _availablePlayers
            .where((player) => 
                !_selectedPlayers.any((selected) => selected.email == player.email) &&
                (player.name.toLowerCase().contains(query) ||
                 player.email.toLowerCase().contains(query)))
            .toList();
      }
    });
  }

  // 🔥 VALIDACIÓN AL AGREGAR JUGADOR
  void _addPlayer(ReservationPlayer player) {
    if (_selectedPlayers.length >= 4) return;

    // Validar conflictos antes de agregar
    final provider = context.read<BookingProvider>();
    final testPlayerNames = [..._selectedPlayers.map((p) => p.name), player.name];
    
    final validation = provider.canCreateBooking(
      widget.courtId,
      widget.date, 
      widget.timeSlot,
      testPlayerNames
    );

    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.reason;
      });
      
      // Limpiar error después de unos segundos
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
      return;
    }

    setState(() {
      _selectedPlayers.add(player);
      _searchController.clear();
      _errorMessage = null; // Limpiar errores previos
      _filterPlayers();
    });
  }

  void _removePlayer(ReservationPlayer player) {
    if (!player.isMainBooker) {
      setState(() {
        _selectedPlayers.remove(player);
        _errorMessage = null; // Limpiar errores al remover
        _filterPlayers();
      });
    }
  }

  bool get _canCreateReservation => _selectedPlayers.length == 4 && _errorMessage == null;

  // 🔥 CREACIÓN DE RESERVA CON VALIDACIÓN FINAL + EMAILS
  Future<void> _createReservation() async {
    if (!_canCreateReservation) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<BookingProvider>();
      
      // 🔥 VALIDACIÓN FINAL antes de crear
      final playerNames = _selectedPlayers.map((p) => p.name).toList();
      final validation = provider.canCreateBooking(
        widget.courtId, 
        widget.date, 
        widget.timeSlot,
        playerNames
      );
      
      if (!validation.isValid) {
        throw Exception(validation.reason!);
      }

      // Convertir jugadores a formato BookingPlayer
      final bookingPlayers = _selectedPlayers.map((player) => BookingPlayer(
        name: player.name,
        email: player.email,
        isConfirmed: true,
      )).toList();

      print('🔥 Creando reserva con emails: ${widget.courtId} ${widget.date} ${widget.timeSlot}');
      print('🔥 Jugadores: ${playerNames.join(", ")}');
      
      // 🚀 NUEVO: Crear reserva CON emails automáticos
      final success = await provider.createBookingWithEmails(
        courtNumber: widget.courtId,
        date: widget.date,
        timeSlot: widget.timeSlot,
        players: bookingPlayers,
      );
      
      if (success) {
        // Actualizar UI
        await provider.refresh();
        
        print('🎉 Reserva creada exitosamente con emails - UI actualizada');

        // Mostrar confirmación
        _showSuccessDialog();
      } else {
        throw Exception('Error al crear la reserva');
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      print('❌ Error creando reserva: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Reserva Confirmada!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu reserva de pádel ha sido confirmada exitosamente:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.sports_tennis, 'Cancha', widget.courtName),
                  _buildDetailRow(Icons.calendar_today, 'Fecha', _formatDisplayDate()),
                  _buildDetailRow(Icons.access_time, 'Hora', widget.timeSlot),
                  _buildDetailRow(Icons.group, 'Jugadores', '${_selectedPlayers.length}'),
                  const SizedBox(height: 8),
                  const Text('Participantes:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ..._selectedPlayers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final player = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        '${index + 1}. ${player.name}${player.isMainBooker ? ' (Organizador)' : ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 📧 NUEVO: Información sobre emails enviados
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se han enviado emails de confirmación a todos los jugadores',
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'La grilla ahora debe aparecer en azul indicando "Reservada".',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar confirmación
              Navigator.of(context).pop(); // Cerrar modal de reserva
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2E7AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Entendido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate() {
    try {
      final parts = widget.date.split('-');
      if (parts.length == 3) {
        const months = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
        return '${parts[2]} de ${months[int.parse(parts[1])]}';
      }
    } catch (e) {
      // En caso de error, devolver fecha original
    }
    return widget.date;
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 TEMPORAL - CONFIRMAR QUE SE USA ESTE ARCHIVO
    print("🚀 MODAL V3 OPTIMIZADO! Sin overflow, compacto y funcional");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70, // 🔧 Reducido de 0.75 a 0.70
          minHeight: 300, // 🔧 Reducido de 350 a 300
        ),
        child: Column(
          children: [
            // Header inline optimizado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.getCourtColorAsColor(widget.courtName),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          '🎾 ',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          widget.courtName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ' • ${_formatDisplayDate()} • ${widget.timeSlot}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Body con padding optimizado
            Expanded(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // 🔧 Reducido padding
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔧 Jugadores seleccionados SUPER COMPACTA
                        Container(
                          padding: const EdgeInsets.all(12), // ✅ Aumentado de 8 a 12
                          margin: const EdgeInsets.only(bottom: 12), // ✅ Aumentado de 8 a 12
                          constraints: const BoxConstraints(
                            minHeight: 60, // ✅ NUEVO: Altura mínima
                            maxHeight: 80, // ✅ Aumentado de 45 a 80
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jugadores (${_selectedPlayers.length}/4)',
                                style: const TextStyle(
                                  fontSize: 15, // ✅ Aumentado de 14 a 15
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8), // ✅ Aumentado de 4 a 8
                              
                              // 🔧 JUGADORES EN HORIZONTAL - CORREGIDO
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _selectedPlayers.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final player = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(right: 12), // ✅ Aumentado margen
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, 
                                          vertical: 4
                                        ), // ✅ NUEVO: Padding interno
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: player.isMainBooker 
                                                ? Colors.blue.withOpacity(0.3) 
                                                : Colors.green.withOpacity(0.3)
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // 🔧 CÍRCULO CON NÚMERO - MÁS GRANDE
                                            Container(
                                              width: 22, // ✅ Aumentado de 18 a 22
                                              height: 22, // ✅ Aumentado de 18 a 22
                                              decoration: BoxDecoration(
                                                color: player.isMainBooker ? Colors.blue : Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12, // ✅ Aumentado de 10 a 12
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8), // ✅ Aumentado spacing
                                            
                                            // 🔧 NOMBRE DEL JUGADOR - MEJORADO
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 100), // ✅ NUEVO: Ancho máximo
                                              child: Text(
                                                player.name.length > 15 
                                                    ? '${player.name.substring(0, 15)}...' // ✅ Aumentado de 12 a 15 caracteres
                                                    : player.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12, // ✅ Aumentado de 11 a 12
                                                  color: player.isMainBooker ? Colors.blue.shade700 : Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            
                                            // 🔧 BOTÓN REMOVER - MÁS GRANDE Y VISIBLE
                                            if (!player.isMainBooker) ...[
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => _removePlayer(player),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.all(2), // ✅ NUEVO: Padding para área táctil
                                                  child: const Icon(
                                                    Icons.remove_circle, 
                                                    color: Colors.red, 
                                                    size: 18 // ✅ Aumentado de 14 a 18
                                                  ),
                                                ),
                                              ),
                                            ],
                                            
                                            // 🔧 INDICADOR DE ORGANIZADOR
                                            if (player.isMainBooker) ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.star, 
                                                color: Colors.amber, 
                                                size: 14
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔧 OPCIONAL: Agregar indicador de scroll si hay muchos jugadores
                        if (_selectedPlayers.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swipe,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Desliza para ver todos los jugadores',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),                        
                        if (_selectedPlayers.length < 4) ...[
                          // Campo de búsqueda
                          Text(
                            'Buscar jugador ${_selectedPlayers.length + 1} de 4:',
                            style: const TextStyle(
                              fontSize: 14, // 🔧 Reducido de 16 a 14
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6), // 🔧 Reducido de 8 a 6
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // 🔧 Reducido padding
                            ),
                          ),
                          
                          const SizedBox(height: 8), // 🔧 Reducido de 12 a 8
                          
                          // 🔧 Lista de jugadores disponibles MÁS COMPACTA
                          Container(
                            height: 150, // 🔧 Reducido de 200 a 150
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _filteredPlayers.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        _searchController.text.isEmpty
                                            ? 'Escribe para buscar jugadores'
                                            : 'No se encontraron jugadores',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14, // 🔧 Reducido de 16 a 14
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 2), // 🔧 Reducido padding
                                    itemCount: _filteredPlayers.length,
                                    itemBuilder: (context, index) {
                                      final player = _filteredPlayers[index];
                                      final isSpecialVisit = ['VISITA1 PADEL', 'VISITA2 PADEL', 'VISITA3 PADEL', 'VISITA4 PADEL']
                                          .contains(player.name.toUpperCase());
                                      
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // 🔧 Reducido margins
                                        decoration: BoxDecoration(
                                          color: isSpecialVisit ? Colors.orange.withOpacity(0.1) : Colors.white,
                                          borderRadius: BorderRadius.circular(6), // 🔧 Reducido border radius
                                          border: Border.all(
                                            color: isSpecialVisit ? Colors.orange.withOpacity(0.3) : Colors.grey[200]!
                                          ),
                                        ),
                                        child: ListTile(
                                          dense: true, // 🔧 NUEVO: Hacer más compacto
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), // 🔧 Reducido padding
                                          title: Text(
                                            player.name,
                                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), // 🔧 Reducido font
                                          ),
                                          subtitle: isSpecialVisit 
                                              ? const Text(
                                                  'Puede jugar en múltiples canchas',
                                                  style: TextStyle(fontSize: 10, color: Colors.orange), // 🔧 Reducido font
                                                )
                                              : null,
                                          trailing: IconButton(
                                            onPressed: () => _addPlayer(player),
                                            icon: Icon(
                                              Icons.add_circle, 
                                              color: isSpecialVisit ? Colors.orange : Colors.green, 
                                              size: 20 // 🔧 Reducido de 24 a 20
                                            ),
                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30), // 🔧 Constraints más pequeños
                                          ),
                                          onTap: () => _addPlayer(player),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                        
                        const SizedBox(height: 8), // 🔧 Reducido de 12 a 8
                        
                        // 🔥 MENSAJE DE ERROR MEJORADO
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10), // 🔧 Reducido padding
                            margin: const EdgeInsets.only(bottom: 12), // 🔧 Reducido margin
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.error, color: Colors.red, size: 18), // 🔧 Reducido tamaño
                                ),
                                const SizedBox(width: 6), // 🔧 Reducido spacing
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Conflicto de horario:',
                                        style: TextStyle(
                                          color: Colors.red, 
                                          fontSize: 13, // 🔧 Reducido font
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                      const SizedBox(height: 2), // 🔧 Reducido spacing
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red, fontSize: 12), // 🔧 Reducido font
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 📧 NUEVO: Indicador de progreso de emails
                        Consumer<BookingProvider>(
                          builder: (context, provider, child) {
                            if (provider.isSendingEmails) {
                              return Container(
                                padding: const EdgeInsets.all(10), // 🔧 Reducido padding
                                margin: const EdgeInsets.only(bottom: 12), // 🔧 Reducido margin
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 14, // 🔧 Reducido tamaño
                                      height: 14, // 🔧 Reducido tamaño
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 10), // 🔧 Reducido spacing
                                    Text(
                                      '📧 Enviando confirmaciones por email...',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 13, // 🔧 Reducido font
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8), // 🔧 Reducido padding
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(fontSize: 14, color: Colors.grey), // 🔧 Reducido font
                                ),
                              ),
                            ),
                            const SizedBox(width: 10), // 🔧 Reducido spacing
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _canCreateReservation && !_isLoading
                                    ? _createReservation
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _canCreateReservation
                                      ? const Color(0xFF2E7AFF)
                                      : Colors.grey[300],
                                  padding: const EdgeInsets.symmetric(vertical: 8), // 🔧 Reducido padding
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 16, // 🔧 Reducido tamaño
                                        width: 16, // 🔧 Reducido tamaño
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _canCreateReservation
                                            ? 'Confirmar Reserva'
                                            : _errorMessage != null
                                                ? 'Resolver conflictos'
                                                : 'Elije + ${4 - _selectedPlayers.length} players +',
                                        style: TextStyle(
                                          fontSize: 14, // 🔧 Reducido font
                                          fontWeight: FontWeight.w600,
                                          color: _canCreateReservation ? Colors.white : Colors.grey[600],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Clase auxiliar para jugadores en el formulario
class ReservationPlayer {
  final String name;
  final String email;
  final bool isMainBooker;

  ReservationPlayer({
    required this.name,
    required this.email,
    this.isMainBooker = false,
  });
}