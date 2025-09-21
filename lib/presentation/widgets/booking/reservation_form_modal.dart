/// lib/presentation/widgets/booking/reservation_form_modal.dart
/// 
/// PROPÃ“SITO:
/// Modal complejo para crear y gestionar reservas de Pádel. Componente más crítico
/// del sistema que maneja auto-completado del organizador, búsqueda de usuarios,
/// validación de conflictos en tiempo real, y creación de reservas con emails automáticos.
/// 
/// CARACTERÃSTICAS PRINCIPALES:
/// - Auto-completado del organizador desde URL/sesión
/// - Búsqueda y selección de hasta 4 jugadores
/// - Validación en tiempo real de conflictos de horarios
/// - Integración con Firebase para datos de usuarios y teléfonos
/// - UI responsive optimizada para móvil y desktop
/// - Sistema completo de emails automáticos
/// 
/// FLUJO PRINCIPAL:
/// 1. Inicialización â†’ Auto-completar organizador â†’ Cargar usuarios Firebase
/// 2. Búsqueda â†’ Filtrar usuarios â†’ Seleccionar jugadores
/// 3. Validación â†’ Verificar conflictos â†’ Crear reserva â†’ Enviar emailsimport 'dart:convert';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_user_service.dart';
import '../../../core/services/user_service.dart';
import '../../../domain/entities/booking.dart';

class ReservationFormModal extends StatefulWidget {
  /// ID único de la cancha (ej: "court_1", "court_2")
  final String courtId;
  /// Nombre legible de la cancha (ej: "PITE", "LILEN")
  final String courtName;
  /// Fecha de la reserva en formato YYYY-MM-DD
  final String date;
  /// Slot de tiempo en formato HH:MM (ej: "09:00", "14:30")
  final String timeSlot;
  /// Deporte actual (ej: "PADEL", "TENIS")
  final String sport;

  const ReservationFormModal({
    Key? key,
    required this.courtId,
    required this.courtName,
    required this.date,
    required this.timeSlot,
    required this.sport,
    this.bookingToModify,
  }) : super(key: key);

  final Booking? bookingToModify;
  
  @override
  State<ReservationFormModal> createState() => _ReservationFormModalState();
}

class _ReservationFormModalState extends State<ReservationFormModal> {
  // ✅ AGREGAR ESTA FUNCIÃ“N AQUÃ
  IconData _getSportIcon(String courtId) {
    if (courtId.startsWith('padel_')) {
      return Icons.sports_handball;
    } else if (courtId.startsWith('tennis_')) {
      return Icons.sports_tennis;
    } else if (courtId.startsWith('golf_')) {
      return Icons.golf_course;
    }
    return Icons.sports_tennis; // Fallback
  }
  /// Form key para validaciones del formulario
  final _formKey = GlobalKey<FormState>();
  /// Controlador para el campo de búsqueda de usuarios
  final _searchController = TextEditingController();
  
  /// Lista de jugadores seleccionados para la reserva (máximo 4)
  List<ReservationPlayer> _selectedPlayers = [];
  /// Lista completa de usuarios disponibles cargados desde Firebase
  List<ReservationPlayer> _availablePlayers = [];
  /// Lista filtrada de usuarios según el texto de búsqueda
  List<ReservationPlayer> _filteredPlayers = [];
  
  /// Estado de carga para mostrar indicadores
  bool _isLoading = false;
  String? _errorMessage;

  // Límites dinámicos por deporte
  int get _minPlayers => widget.sport == 'TENIS' ? 2 : 4;
  int get _maxPlayers => 4;

  // Determina si se puede crear la reserva según las nuevas reglas  
  bool get _canCreateReservation => 
      (widget.sport == 'GOLF' ? _selectedPlayers.length >= 1 : _selectedPlayers.length >= _minPlayers) &&
      _selectedPlayers.length <= _maxPlayers && 
      _errorMessage == null;

  /// Métodos helper para parametrización por deporte
  String get _sportDisplayName => widget.sport == 'TENIS' ? 'tenis' : 
                                widget.sport == 'GOLF' ? 'golf' : 'Pádel';

  Color get _sportColor => widget.sport == 'TENIS' 
      ? const Color(0xFFD2691E) // Tierra batida para tenis
      : widget.sport == 'GOLF'
          ? const Color(0xFF4CAF50) // Verde para golf  
          : const Color(0xFF2E7AFF); // Azul para Pádel

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _searchController.addListener(_filterPlayers);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkInitialSlotAvailability();
      _filterPlayers();
    });
  }

  /// Validación inicial al abrir el modal
  /// 
  /// Verifica si el slot seleccionado está disponible antes de permitir
  /// que el usuario configure la reserva. Si hay conflictos, muestra error
  /// y cierra el modal automáticamente.
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
      
      // ðŸ”¥ USAR WidgetsBinding para asegurar contexto correcto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showConflictDialog(validation.reason!);
        }
      });
    }
  }

  /// Inicializa el formulario y carga datos necesarios
  /// 
  /// Secuencia de inicialización:
  /// 1. Limpia listas de jugadores
  /// 2. Configura usuario actual como organizador
  /// 3. Carga usuarios desde Firebase
  void _initializeForm() {
    // PERF: print('ðŸš€ MODAL: Inicializando formulario...');
    
    // Inicializar listas vacías
    _availablePlayers = [];
    _filteredPlayers = [];
    
    // ðŸ”¥ USUARIO DINÃMICO: Configurar usuario actual primero
    _setCurrentUser().then((_) {
      // PERF: print('✅ MODAL: Usuario principal configurado, cargando desde Firebase...');
      // Después cargar usuarios desde Firebase
      _loadUsersFromFirebase();
    });
  }

  /// Configura el usuario actual como organizador de la reserva
  /// 
  /// Obtiene el email y nombre del usuario actual desde UserService,
  /// lo agrega como primer jugador (organizador), y valida inmediatamente
  /// si tiene conflictos en el horario seleccionado.
  /// 
  /// Si se detectan conflictos del organizador:
  /// - Muestra Snackbar rojo con mensaje específico
  /// - Auto-cierra el modal después de 4 segundos
  /// 
  /// En caso de error, usa fallback temporal para permitir testing
  Future<void> _setCurrentUser() async {
    try {
      // ðŸ”¥ NUEVO: Usar AuthProvider primero
      final authProvider = context.read<AuthProvider>();
      
      String currentEmail;
      String currentName;
      
      // Intentar obtener de AuthProvider primero
      if (authProvider.isUserValidated && 
          authProvider.currentUserEmail != null && 
          authProvider.currentUserName != null) {
        currentEmail = authProvider.currentUserEmail!;
        currentName = authProvider.currentUserName!;
        // PERF: print('✅ MODAL: Usuario desde AuthProvider - $currentName ($currentEmail)');
      } else {
        // Fallback al UserService original
        currentEmail = await UserService.getCurrentUserEmail();
        currentName = await UserService.getCurrentUserName();
        // PERF: print('âš ï¸ MODAL: Usuario desde UserService fallback - $currentName ($currentEmail)');
      }
      
      // PERF: print('✅ MODAL: Usuario actual - $currentName ($currentEmail)');
      
      // SIEMPRE agregar el usuario primero (para que aparezca en UI)
      _selectedPlayers.add(ReservationPlayer(
        name: currentName,
        email: currentEmail,
        isMainBooker: true,
      ));
      
      // ðŸ”¥ VALIDAR CONFLICTOS DESPUÃ‰S DE AGREGAR (usando WidgetsBinding)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = context.read<BookingProvider>();
          final playerNames = _selectedPlayers.map((p) => p.name).toList();
          
          final validation = provider.canCreateBooking(
            widget.courtId,
            widget.date,
            widget.timeSlot,
            playerNames
          );

          if (!validation.isValid) {
            // PERF: print('âŒ MODAL: Conflicto detectado para organizador: ${validation.reason}');
            
            setState(() {
              _errorMessage = validation.reason;
            });
            
            // ðŸ”¥ MOSTRAR DIÃLOGO DE CONFLICTO
            _showConflictDialog(validation.reason!);
          } else {
            // PERF: print('✅ MODAL: Sin conflictos detectados para organizador');
          }
        }
      });
      
    } catch (e) {
      // PERF: print('âŒ MODAL: Error obteniendo usuario actual: $e');
      
      // Fallback de emergencia
      _selectedPlayers.add(ReservationPlayer(
        name: 'USUARIO TEMPORAL',
        email: 'temp@cgp.cl',
        isMainBooker: true,
      ));
    }
  }

  // ðŸ”¥ FUNCIÃ“N SIMPLIFICADA: Diálogo sin auto-cierre (UX más clara)
  void _showConflictDialog(String conflictMessage) {
    showDialog(
      context: context,
      barrierDismissible: false, // Usuario DEBE presionar botón
      builder: (context) => WillPopScope(
        // Interceptar botón back del navegador/móvil
        onWillPop: () async {
          // PERF: print('ðŸ”¥ DEBUG: WillPopScope ejecutándose');
          Navigator.of(context).pop(); // Cerrar diálogo
          
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // PERF: print('ðŸ”¥ DEBUG: WillPopScope cerrando modal...');
              Navigator.of(context).pop(); // Cerrar modal de reserva
            }
          });
          return false;
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'âš ï¸ Conflicto de Horario',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conflictMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Por favor selecciona otro horario disponible.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // PERF: print('ðŸ”¥ DEBUG: Presionando Entendido');
                // PERF: print('ðŸ”¥ DEBUG: Cerrando diálogo...');
                Navigator.of(context).pop(); // Cerrar diálogo
                
                // PERF: print('ðŸ”¥ DEBUG: Esperando 100ms...');
                Future.delayed(const Duration(milliseconds: 100), () {
                  // PERF: print('ðŸ”¥ DEBUG: Intentando cerrar modal con ROOT navigator...');
                  try {
                    // ðŸ”¥ USAR ROOT NAVIGATOR
                    Navigator.of(context, rootNavigator: true).pop();
                    // PERF: print('✅ DEBUG: Modal cerrado con ROOT navigator');
                  } catch (e) {
                    // PERF: print('âŒ DEBUG: Error con root navigator: $e');
                  }
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carga todos los usuarios desde Firebase Firestore
  /// 
  /// Utiliza FirebaseUserService para obtener la lista completa de usuarios
  /// sincronizados desde Google Sheets. Incluye mapeo de teléfonos y manejo
  /// de la estructura híbrida español/inglés.
  /// 
  /// En caso de error:
  /// - Usa fallback con usuarios de prueba expandido
  /// - Incluye usuarios especiales VISITA para testing
  /// - Permite que el sistema funcione en modo offline/desarrollo
  /// 
  /// @debug Imprime logs detallados para debugging
  Future<void> _loadUsersFromFirebase() async {
    // PERF: print('ðŸš€ MODAL: Iniciando carga de usuarios desde Firebase...');
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar usuarios reales desde Firebase
      // PERF: print('ðŸ”¥ MODAL: Llamando a FirebaseUserService.getAllUsers()...');
      final usersData = await FirebaseUserService.getAllUsers();
      // PERF: print('ðŸ”¥ MODAL: Recibidos ${usersData.length} usuarios de Firebase');

      // ðŸ” DEBUG: Verificar primeros 3 usuarios exactos
      // PERF: print('ðŸ” MODAL DEBUG - Primeros 3 usuarios:');
      for (int i = 0; i < usersData.length && i < 3; i++) {
        final user = usersData[i];
        // PERF: print('  ${i+1}. name: "${user['name']}" | email: "${user['email']}"');
      }
      
      // Convertir a ReservationPlayer
      final users = usersData.map((userData) {
        return ReservationPlayer(
          name: userData['name'].toString().replaceAll(RegExp(r'\.$'), ''),
          email: userData['email'],
          isMainBooker: false,
        );
      }).toList();
      
      // PERF: print('ðŸ”¥ MODAL: Convertidos ${users.length} usuarios a ReservationPlayer');

      final allUsers = users;
      
      setState(() {
        _availablePlayers = allUsers.cast<ReservationPlayer>();
        _isLoading = false;
      });

      // PERF: print('✅ MODAL: ${allUsers.length} usuarios cargados desde Firebase');
      
      // Filtrar inmediatamente para mostrar usuarios
      _filterPlayers();
      
    } catch (e) {
      // PERF: print('âŒ MODAL: Error cargando usuarios: $e');
      
      // Fallback: usar usuarios de prueba EXPANDIDOS
      final fallbackUsers = [
        ReservationPlayer(name: 'ANA M BELMAR P', email: 'ana@buzeta.cl'),
        ReservationPlayer(name: 'CLARA PARDO B', email: 'clara@garciab.cl'),
        ReservationPlayer(name: 'JUAN F GONZALEZ P', email: 'juan@hotmail.com'),
        ReservationPlayer(name: 'PEDRO MARTINEZ L', email: 'pedro.martinez@example.com'),
        ReservationPlayer(name: 'MARIA GONZALEZ R', email: 'maria.gonzalez@example.com'),
        ReservationPlayer(name: 'CARLOS RODRIGUEZ M', email: 'carlos.rodriguez@example.com'),
        ReservationPlayer(name: 'LUIS FERNANDEZ B', email: 'luis.fernandez@example.com'),
        ReservationPlayer(name: 'SOFIA MARTINEZ T', email: 'sofia.martinez@example.com'),
        ReservationPlayer(name: 'DIEGO SANCHEZ L', email: 'diego.sanchez@example.com'),
        // Usuarios VISITA
        ReservationPlayer(name: 'PADEL1 VISITA', email: 'reservaspapudo2@gmail.com'),
        ReservationPlayer(name: 'PADEL2 VISITA', email: 'reservaspapudo3@gmail.com'),
        ReservationPlayer(name: 'PADEL3 VISITA', email: 'reservaspapudo4@gmail.com'),
        ReservationPlayer(name: 'PADEL4 VISITA', email: 'reservaspapudo5@gmail.com'),
      ];
      
      setState(() {
        _availablePlayers = fallbackUsers;
        _isLoading = false;
      });
      
      // PERF: print('ðŸ”„ MODAL: Usando ${fallbackUsers.length} usuarios de fallback');
      _filterPlayers();
    }
  }

  /// Filtra la lista de usuarios según el texto de búsqueda
  /// 
  /// Aplica filtros basados en:
  /// - Texto de búsqueda (nombre o email)
  /// - Excluye usuarios ya seleccionados
  /// - Búsqueda case-insensitive
  /// 
  /// Si no hay texto de búsqueda, muestra todos los usuarios disponibles
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

  /// Agrega un jugador a la reserva con validación de conflictos
  /// 
  /// Antes de agregar el jugador:
  /// 1. Verifica que no se exceda el límite de 4 jugadores
  /// 2. Valida que el jugador no tenga conflictos de horario
  /// 3. Si hay conflictos, muestra mensaje de error sin agregar
  /// 4. Si es válido, agrega el jugador y limpia el campo de búsqueda
  /// 
  /// @param player Jugador a agregar a la reserva
  void _addPlayer(ReservationPlayer player) {
    // PERF: print('DEBUG: Attempting to add player: ${player.name}');
    
    if (_selectedPlayers.length >= _maxPlayers) return;

    // Validate conflicts
    final provider = context.read<BookingProvider>();
    final testPlayerNames = [..._selectedPlayers.map((p) => p.name), player.name];
    
    final validation = provider.canCreateBooking(
      widget.courtId,
      widget.date,
      widget.timeSlot,
      testPlayerNames
    );

    if (!validation.isValid) {
      // PERF: print('DEBUG: Conflict detected: ${validation.reason}');
      
      // ðŸ†• MOSTRAR TOAST EN LUGAR DEL MENSAJE ABAJO
      _showConflictToast(
        player.name, 
        validation.reason ?? 'El jugador ya tiene una reserva en este horario'
      );
      return; // No agregar el jugador
    }

    // ðŸ†• SOLO UN setState - CORREGIDO
    // PERF: print('DEBUG: No conflict - adding player');
    setState(() {
      _selectedPlayers.add(player);
      _searchController.clear();
      _errorMessage = null;
      _filterPlayers();
    });
  }

  /// Remueve un jugador de la reserva
  /// 
  /// Solo permite remover jugadores que no sean el organizador principal.
  /// Al remover, actualiza los filtros y limpia mensajes de error.
  /// 
  /// @param player Jugador a remover de la reserva
  void _removePlayer(ReservationPlayer player) {
    if (!player.isMainBooker) {
      setState(() {
        _selectedPlayers.remove(player);
        _errorMessage = null; // Limpiar errores al remover
        _filterPlayers();
      });
    }
  }

  // 🔧 AGREGAR ESTE MÃ‰TODO AQUÃ (después de los otros helpers)
  String _extractCourtNumber(String courtId) {
    // Extraer número del final del ID
    if (courtId.contains('_court_')) {
      return courtId.split('_court_').last;
    }
    return '1'; // Fallback
  }

  /// Crea la reserva con validación final y envío de emails
  /// 
  /// Proceso completo de creación:
  /// 1. Validación final de conflictos con todos los jugadores
  /// 2. Mapeo de teléfonos desde Firebase para cada jugador
  /// 3. Creación de BookingPlayer objects con datos completos
  /// 4. Llamada a createBookingWithEmails para crear y notificar
  /// 5. Actualización de UI y mostrar diálogo de confirmación
  /// 
  /// En caso de error:
  /// - Muestra mensaje específico del error
  /// - Mantiene el modal abierto para correcciones
  /// 
  /// @throws Exception Si la validación falla o hay errores de red/Firebase
  Future<void> _createReservation() async {
    if (!_canCreateReservation) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<BookingProvider>();

      // ðŸ”¥ VALIDACIÃ“N FINAL antes de crear
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

      // Obtener usuarios de Firebase para mapear teléfonos
      final usersData = await FirebaseUserService.getAllUsers();

      // Crear booking players con teléfonos
      final List<BookingPlayer> bookingPlayers = [];

      for (final selectedPlayer in _selectedPlayers) {
        String? userPhone;
        String? userId;
        try {
          // Buscar los datos del usuario en la lista de Firebase para obtener el teléfono y el ID
          final userData = usersData.firstWhere(
            (user) => user['email']?.toString().toLowerCase() == selectedPlayer.email.toLowerCase(),
          );
          // Asumimos que la respuesta de Firebase ahora tiene un ID
          userId = userData['id']?.toString(); 
          userPhone = userData['phone']?.toString();
        } catch (e) {
          // Usuario no encontrado en la base de datos, no tiene ID ni teléfono
          userId = null; 
          userPhone = null; 
        }

        // Usar ID
        final random = Random();
        bookingPlayers.add(BookingPlayer(
          id: userId ?? '${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}',
          name: selectedPlayer.name,
          email: selectedPlayer.email,
        ));
      }

      // En el método _createReservation, ANTES de createBookingWithEmails
      // PERF: print('ðŸš¨ CREANDO RESERVA:');
      // PERF: print('  🔧 widget.courtId: ${widget.courtId}');
      // PERF: print('  🔧 widget.courtName: ${widget.courtName}');
      // PERF: print('  🔧 widget.sport: ${widget.sport}');
      // PERF: print('ðŸ”¥ Creando reserva con emails: ${widget.courtId} ${widget.date} ${widget.timeSlot}');
      // PERF: print('ðŸ”¥ Jugadores: ${playerNames.join(", ")}');

      // ✅ CRÃTICO: Crear reserva CON emails automáticos
      final success = await provider.createBookingWithEmails(
        courtId: widget.courtId,  // ↑ USAR courtId COMPLETO
        date: widget.date,
        timeSlot: widget.timeSlot,
        players: bookingPlayers,
        context: context,
      );

      if (success) {
        // Actualizar UI
        await provider.refresh();

        // PERF: print('✅ Reserva creada exitosamente con emails - UI actualizada');

        // Mostrar confirmación
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSuccessDialog();
        }
      } else {
        throw Exception('Error al crear la reserva');
      }

    } catch (e) {
      // PERF: print('âŒ Error en _createReservation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear reserva: $e')),
        );
      }
    }
  }

  /// Muestra diálogo de confirmación de reserva exitosa
  /// 
  /// Incluye:
  /// - Detalles completos de la reserva (cancha, fecha, hora, jugadores)
  /// - Lista de participantes con indicador del organizador
  /// - Confirmación de envío de emails
  /// - Botón para cerrar modal y diálogo
  void _showSuccessDialog() {
    final String deporte = _sportDisplayName.toLowerCase().trim();
    final int numJugadores = _selectedPlayers.length;

    String _getGrillaColorMensaje(String deporte, int numJugadores) {
      if (deporte == 'Pádel') return 'azul';
      if (deporte == 'tenis') {
        if (numJugadores >= 2 && numJugadores < 4) return 'amarillo';
        if (numJugadores == 4) return 'color ladrillo';
      }
      return 'azul';
    }

    // final String grillaColor = _getGrillaColorMensaje(deporte, numJugadores);

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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu reserva de $_sportDisplayName ha sido confirmada exitosamente:',
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
                    _buildDetailRow(_getSportIcon(widget.courtId), 'Cancha', _getDisplayCourtName(widget.courtId)),
                    _buildDetailRow(Icons.calendar_today, 'Fecha', _formatDisplayDate()),
                    _buildDetailRow(Icons.access_time, 'Hora', widget.timeSlot),
                    _buildDetailRow(Icons.group, 'Jugadores', '$numJugadores'),
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
                widget.sport == 'TENIS'
                    ? _selectedPlayers.length < 4
                        ? 'La grilla ahora debe aparecer en color amarillo indicando "Reservada".'
                        : 'La grilla ahora debe aparecer en color ladrillo indicando "Reservada".'
                    : widget.sport == 'GOLF'
                        ? _selectedPlayers.length < 4
                            ? 'La grilla ahora debe aparecer en color verde indicando "Reservar" (otros pueden unirse).'
                            : 'La grilla ahora debe aparecer en color verde indicando "Reservada".'
                        : 'La grilla ahora debe aparecer en azul indicando "Reservada".', // Pádel siempre "Reservada"
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // PERF: print('ðŸ”¥ DEBUG: Presionando Entendido');
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 100), () {
                try {
                  Navigator.of(context, rootNavigator: true).pop();
                  // PERF: print('✅ DEBUG: Modal cerrado con ROOT navigator');
                } catch (e) {
                  // PERF: print('âŒ DEBUG: Error con root navigator: $e');
                }
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: _sportColor,
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

  /// Construye una fila de detalle para el diálogo de confirmación
  /// 
  /// @param icon Icono para mostrar junto al detalle
  /// @param label Etiqueta del campo
  /// @param value Valor a mostrar
  /// @return Widget con la fila formateada
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

  /// Formatea la fecha para mostrar de manera amigable
  /// 
  /// Convierte fecha de formato YYYY-MM-DD a formato legible
  /// como "15 de Junio" en español.
  /// 
  /// @return String con fecha formateada o fecha original si hay error
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

  /// Convierte ID de cancha a nombre legible
  String _getDisplayCourtName(String courtId) {
    // 🔧 FIX SIMPLE: Auto-corrección para inconsistencias
    if (widget.sport.toUpperCase() == 'PADEL' && courtId.startsWith('tennis_')) {
      courtId = 'padel_court_1'; // Corregir a PITE
    }
    if (widget.sport.toUpperCase() == 'TENIS' && courtId.startsWith('padel_')) {
      courtId = 'tennis_court_1'; // Corregir a Cancha 1
    }
    
    // PERF: print('🔧 MODAL DEBUG: _getDisplayCourtName recibió: "$courtId"');
    
    switch (courtId) {
      // GOLF
      case 'golf_tee_1': return 'Hoyo 1';
      case 'golf_tee_10': return 'Hoyo 10';
      
      // PÃDEL
      case 'padel_court_1': return 'PITE';
      case 'padel_court_2': return 'LILEN';
      case 'padel_court_3': return 'PLAIYA';
      
      // TENIS
      case 'tennis_court_1': return 'Cancha 1';
      case 'tennis_court_2': return 'Cancha 2';
      case 'tennis_court_3': return 'Cancha 3';
      case 'tennis_court_4': return 'Cancha 4';
      
      default: 
        // PERF: print('🔧 MODAL DEBUG: FALLBACK - courtId no reconocido: "$courtId"');
        return courtId; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    // ðŸ”¥ TEMPORAL - CONFIRMAR QUE SE USA ESTE ARCHIVO
    // PERF: print("ðŸš€ MODAL V4 FLEXIBLE! Pádel: 4 fijo, Tenis: 2-4 flexible");
    // DEBUG temporal - agregar antes de los botones
    // PERF: print('ðŸ” DEBUG ESTADO BOTÃ“N:');
    // PERF: print('   sport: ${widget.sport}');
    // PERF: print('   _selectedPlayers.length: ${_selectedPlayers.length}');
    // PERF: print('   _minPlayers: $_minPlayers'); 
    // PERF: print('   _maxPlayers: $_maxPlayers');
    // PERF: print('   _errorMessage: $_errorMessage');
    // PERF: print('   _canCreateReservation: $_canCreateReservation');

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
                color: _sportColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          widget.sport.toUpperCase().contains('PADEL') 
                            ? Icons.sports_handball 
                            : widget.sport.toUpperCase() == 'TENIS' 
                              ? Icons.sports_baseball 
                              : Icons.golf_course,
                          color: Colors.white,  // ↑ BLANCO para contraste con fondo azul
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getDisplayCourtName(widget.courtName),  // Convertir ID a nombre legible
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
                                widget.sport == 'TENIS' 
                                ? 'Jugadores (${_selectedPlayers.length}/$_minPlayers-$_maxPlayers)'
                                : 'Jugadores (${_selectedPlayers.length}/$_maxPlayers)',
                                style: const TextStyle(
                                  fontSize: 15, // ✅ Aumentado de 14 a 15
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8), // ✅ Aumentado de 4 a 8
                              
                              // JUGADORES EN HORIZONTAL - CORREGIDO
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
                                            // CÍRCULO CON NÚMERO - MÁS GRANDE
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
                                            
                                            // 🔧 BOTÃ“N REMOVER - MÃS GRANDE Y VISIBLE
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
                            widget.sport == 'TENIS'
                                ? _selectedPlayers.length < _minPlayers
                                    ? 'Buscar jugador ${_selectedPlayers.length + 1} (mínimo $_minPlayers para tenis):'
                                    : 'Buscar jugador ${_selectedPlayers.length + 1} (opcional, máximo $_maxPlayers):'
                                : 'Buscar jugador ${_selectedPlayers.length + 1} de $_maxPlayers:',
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
                                      final isSpecialVisit = ['PADEL1 VISITA', 'PADEL2 VISITA', 'PADEL3 VISITA', 'PADEL4 VISITA']
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
                                          dense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                          title: Text(
                                            player.name,
                                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                          ),
                                          subtitle: isSpecialVisit 
                                              ? const Text(
                                                  'Puede jugar en múltiples canchas',
                                                  style: TextStyle(fontSize: 10, color: Colors.orange),
                                                )
                                              : null,
                                          trailing: IconButton(
                                            onPressed: () {
                                              // PERF: print('DEBUG: IconButton pressed for: ${player.name}');
                                              _addPlayer(player);
                                            },
                                            icon: Icon(
                                              Icons.add_circle, 
                                              color: isSpecialVisit ? Colors.orange : Colors.green, 
                                              size: 20
                                            ),
                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                          ),
                                          onTap: () {
                                            // PERF: print('DEBUG: ListTile tapped for: ${player.name}');
                                            _addPlayer(player);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                        
                        const SizedBox(height: 8), // 🔧 Reducido de 12 a 8
                        
                        // ðŸ”¥ MENSAJE DE ERROR MEJORADO
                        // if (_errorMessage != null)
                        //   Container(
                        //     padding: const EdgeInsets.all(10),
                        //     margin: const EdgeInsets.only(bottom: 12),
                        //     decoration: BoxDecoration(
                        //       color: Colors.red.withOpacity(0.1),
                        //       borderRadius: BorderRadius.circular(8),
                        //       border: Border.all(color: Colors.red.withOpacity(0.3)),
                        //     ),
                        //     child: Row(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         const Padding(
                        //           padding: EdgeInsets.only(top: 2),
                        //           child: Icon(Icons.error, color: Colors.red, size: 18),
                        //         ),
                        //         const SizedBox(width: 6),
                        //         Expanded(
                        //           child: Column(
                        //             crossAxisAlignment: CrossAxisAlignment.start,
                        //             children: [
                        //               const Text(
                        //                 'Conflicto de horario:',
                        //                 style: TextStyle(
                        //                   color: Colors.red, 
                        //                   fontSize: 13,
                        //                   fontWeight: FontWeight.w600
                        //                 ),
                        //               ),
                        //               const SizedBox(height: 2),
                        //               Text(
                        //                 _errorMessage!,
                        //                 style: const TextStyle(color: Colors.red, fontSize: 12),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),

                        // ðŸ“§ NUEVO: Indicador de progreso de emails
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
                                    side: BorderSide(color: Colors.red[300]!, width: 1.5),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(fontSize: 16, color: Colors.red[700], fontWeight: FontWeight.w600), // 🔧 Mejorado contraste
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
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _canCreateReservation
                                            ? widget.sport == 'TENIS' && _selectedPlayers.length < 4
                                                ? 'Confirmar (Reservada)'
                                                : 'Confirmar Reserva'
                                            : _errorMessage != null
                                                ? 'Resolver conflictos'
                                                : widget.sport == 'TENIS'
                                                    ? _selectedPlayers.length < _minPlayers
                                                        ? 'Mínimo $_minPlayers jugadores'
                                                        : 'Agregar jugador'
                                                    : 'Faltan ${_maxPlayers - _selectedPlayers.length} jugadores',
                                        style: TextStyle(
                                          fontSize: 14,
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

  // Método para mostrar toast de conflicto
  void _showConflictToast(String playerName, String conflictReason) {
    // Usar el context del Scaffold padre, no del modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                conflictReason,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: 50,  // Cambiar de bottom a top
          left: 16,
          right: 16,
        ),
        elevation: 1000, // Z-index muy alto para aparecer sobre el modal
      ),
    );
  }
}

/// Clase auxiliar para representar jugadores en el formulario de reserva
/// 
/// Esta clase es específica del modal y diferente de BookingPlayer (entidad de dominio).
/// Se usa durante el proceso de selección antes de convertir a BookingPlayer final.
class ReservationPlayer {
  /// Nombre completo del jugador
  final String name;
  /// Email único del jugador para identificación  
  final String email;
  /// Indica si este jugador es el organizador principal (no se puede remover)
  final bool isMainBooker;

  ReservationPlayer({
    required this.name,
    required this.email,
    this.isMainBooker = false,
  });
}



