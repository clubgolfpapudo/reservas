/// lib/presentation/widgets/booking/reservation_form_modal.dart
/// 
/// PROPÓSITO:
/// Modal complejo para crear y gestionar reservas de pádel. Este es el componente más crítico
/// del sistema de reservas, responsable de:
/// - Auto-completado del organizador desde URL/sesión
/// - Búsqueda y selección de hasta 4 jugadores
/// - Validación en tiempo real de conflictos de horarios
/// - Integración con Firebase para datos de usuarios y teléfonos
/// - Creación de reservas con envío automático de emails
/// - UI responsive optimizada para móvil y desktop
/// 
/// MOTIVO DE EXISTENCIA:
/// Este modal encapsula toda la lógica compleja de creación de reservas, incluyendo:
/// - Validaciones de reglas de negocio (máximo 4 jugadores, conflictos de horario)
/// - Integración con múltiples servicios (Firebase, Email, User Service)
/// - Manejo de estados de carga y errores
/// - UX optimizada con feedback inmediato al usuario
/// - Compatibilidad con usuarios especiales (VISITA)
/// 
/// DEPENDENCIAS CRÍTICAS:
/// - BookingProvider: Para validaciones y creación de reservas
/// - FirebaseUserService: Para carga de usuarios y mapeo de teléfonos
/// - UserService: Para obtener usuario actual y lógica de negocio
/// 
/// FLUJO PRINCIPAL:
/// 1. Inicialización → Auto-completar organizador → Cargar usuarios Firebase
/// 2. Búsqueda → Filtrar usuarios → Seleccionar jugadores
/// 3. Validación → Verificar conflictos → Crear reserva → Enviar emails
/// 
/// OPTIMIZACIONES IMPLEMENTADAS:
/// - UI compacta para móviles con altura máxima 70% de pantalla
/// - Scroll horizontal para lista de jugadores seleccionados
/// - Validación inmediata al agregar/remover jugadores
/// - Fallback de usuarios de desarrollo cuando Firebase falla
/// - Snackbar con auto-cierre para conflictos del organizador

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_user_service.dart';
import '../../../core/services/user_service.dart';
import '../../../domain/entities/booking.dart';

/// Widget principal del modal de reservas
/// 
/// Este StatefulWidget maneja toda la lógica de creación de reservas incluyendo:
/// - Selección de jugadores con búsqueda en tiempo real
/// - Validaciones de conflictos automáticas
/// - Integración con sistema de emails
/// - UI responsive y optimizada
class ReservationFormModal extends StatefulWidget {
  /// ID único de la cancha (ej: "court_1", "court_2")
  final String courtId;
  
  /// Nombre legible de la cancha (ej: "PITE", "LILEN")
  final String courtName;
  
  /// Fecha de la reserva en formato YYYY-MM-DD
  final String date;
  
  /// Slot de tiempo en formato HH:MM (ej: "09:00", "14:30")
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
  
  /// Mensaje de error para mostrar conflictos o problemas
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _searchController.addListener(_filterPlayers);
    
    // Ejecutar validaciones después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSlotAvailability();
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
      
      // Auto-cerrar si hay conflicto inicial
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
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
    print('🚀 MODAL: Inicializando formulario...');
    
    // Inicializar listas vacías
    _availablePlayers = [];
    _filteredPlayers = [];
    
    // Configurar usuario actual primero, luego cargar desde Firebase
    _setCurrentUser().then((_) {
      print('✅ MODAL: Usuario principal configurado, cargando desde Firebase...');
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
      
      // Validar conflictos del organizador inmediatamente
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
          setState(() {
            _errorMessage = validation.reason;
          });

          print('❌ MODAL: Conflicto detectado para organizador: ${validation.reason}');

          // Mostrar Snackbar con error específico
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ ${validation.reason}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );

          // Auto-cerrar después de mostrar el mensaje
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          print('✅ MODAL: Sin conflictos detectados para organizador');
        }
      }
      
    } catch (e) {
      print('❌ MODAL: Error obteniendo usuario actual: $e');
      
      // Fallback de emergencia para desarrollo/testing
      _selectedPlayers.add(ReservationPlayer(
        name: 'USUARIO TEMPORAL',
        email: 'temp@cgp.cl',
        isMainBooker: true,
      ));
    }
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
    print('🚀 MODAL: Iniciando carga de usuarios desde Firebase...');
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar usuarios reales desde Firebase
      print('🔥 MODAL: Llamando a FirebaseUserService.getAllUsers()...');
      final usersData = await FirebaseUserService.getAllUsers();
      print('🔥 MODAL: Recibidos ${usersData.length} usuarios de Firebase');

      // Debug: Verificar estructura de primeros 3 usuarios
      print('🔍 MODAL DEBUG - Primeros 3 usuarios:');
      for (int i = 0; i < usersData.length && i < 3; i++) {
        final user = usersData[i];
        print('  ${i+1}. name: "${user['name']}" | email: "${user['email']}"');
      }
      
      // Convertir datos de Firebase a ReservationPlayer
      final users = usersData.map((userData) {
        return ReservationPlayer(
          name: userData['name'].toString().replaceAll(RegExp(r'\.$'), ''),
          email: userData['email'],
          isMainBooker: false,
        );
      }).toList();
      
      print('🔥 MODAL: Convertidos ${users.length} usuarios a ReservationPlayer');

      setState(() {
        _availablePlayers = users.cast<ReservationPlayer>();
        _isLoading = false;
      });

      print('✅ MODAL: ${users.length} usuarios cargados desde Firebase');
      
      // Aplicar filtros inmediatamente
      _filterPlayers();
      
    } catch (e) {
      print('❌ MODAL: Error cargando usuarios: $e');
      
      // Fallback robusto con usuarios de prueba expandidos
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
        // Usuarios especiales VISITA para testing
        ReservationPlayer(name: 'PADEL1 VISITA', email: 'reservaspapudo2@gmail.com'),
        ReservationPlayer(name: 'PADEL2 VISITA', email: 'reservaspapudo3@gmail.com'),
        ReservationPlayer(name: 'PADEL3 VISITA', email: 'reservaspapudo4@gmail.com'),
        ReservationPlayer(name: 'PADEL4 VISITA', email: 'reservaspapudo5@gmail.com'),
      ];
      
      setState(() {
        _availablePlayers = fallbackUsers;
        _isLoading = false;
      });
      
      print('🔄 MODAL: Usando ${fallbackUsers.length} usuarios de fallback');
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
    // Verificar límite máximo de jugadores
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
      
      // Auto-limpiar error después de 4 segundos
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
      return;
    }

    // Agregar jugador si no hay conflictos
    setState(() {
      _selectedPlayers.add(player);
      _searchController.clear();
      _errorMessage = null; // Limpiar errores previos
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

  /// Getter que determina si se puede crear la reserva
  /// 
  /// Condiciones para crear reserva:
  /// - Exactamente 4 jugadores seleccionados
  /// - No hay mensajes de error activos
  bool get _canCreateReservation => _selectedPlayers.length == 4 && _errorMessage == null;

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

      // Validación final antes de crear
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

      // Crear booking players con teléfonos mapeados
      final List<BookingPlayer> bookingPlayers = [];
      
      for (final selectedPlayer in _selectedPlayers) {
        String? userPhone;
        try {
          final userData = usersData.firstWhere(
            (user) => user['email']?.toString().toLowerCase() == selectedPlayer.email.toLowerCase(),
          );
          userPhone = userData['phone']?.toString();
        } catch (e) {
          userPhone = null; // Usuario no encontrado en Firebase
        }
        
        bookingPlayers.add(BookingPlayer(
          name: selectedPlayer.name,
          email: selectedPlayer.email,
          phone: userPhone,  // Teléfono mapeado desde Firebase
          isConfirmed: true,
        ));
      }

      print('🔥 Creando reserva con emails: ${widget.courtId} ${widget.date} ${widget.timeSlot}');
      print('🔥 Jugadores: ${playerNames.join(", ")}');

      // CRÍTICO: Crear reserva CON emails automáticos
      final success = await provider.createBookingWithEmails(
        courtNumber: widget.courtId,
        date: widget.date,
        timeSlot: widget.timeSlot,
        players: bookingPlayers,
      );

      if (success) {
        // Actualizar UI del provider
        await provider.refresh();

        print('✅ Reserva creada exitosamente con emails - UI actualizada');

        // Mostrar diálogo de confirmación
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
      print('❌ Error en _createReservation: $e');
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
                'Tu reserva de pádel ha sido confirmada exitosamente:',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              
              // Detalles de la reserva
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
              
              // Confirmación de emails enviados
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

  @override
  Widget build(BuildContext context) {
    // Debug log para confirmar versión del archivo
    print("🚀 MODAL V3 OPTIMIZADO! Sin overflow, compacto y funcional");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70, // Optimizado para móvil
          minHeight: 300,
        ),
        child: Column(
          children: [
            // Header con información de la reserva
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
                        const Text('🎾 ', style: TextStyle(fontSize: 18)),
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
            
            // Cuerpo del modal con formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección de jugadores seleccionados (compacta)
                        _buildSelectedPlayersSection(),

                        // Campo de búsqueda (solo si faltan jugadores)
                        if (_selectedPlayers.length < 4) ...[
                          _buildSearchSection(),
                          const SizedBox(height: 8),
                          _buildAvailablePlayersList(),
                        ],
                        
                        const SizedBox(height: 8),
                        
                        // Mensaje de error si existe
                        if (_errorMessage != null) _buildErrorMessage(),

                        // Indicador de progreso de emails
                        _buildEmailProgressIndicator(),
                        
                        // Botones de acción
                        _buildActionButtons(),
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

  /// Construye la sección de jugadores seleccionados
  /// 
  /// Muestra una lista horizontal scrollable de jugadores con:
  /// - Indicador numérico para cada jugador
  /// - Identificación visual del organizador (estrella)
  /// - Botón para remover jugadores (excepto organizador)
  /// - Scroll horizontal para pantallas pequeñas
  Widget _buildSelectedPlayersSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(
        minHeight: 60,
        maxHeight: 80,
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
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // Lista horizontal de jugadores
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _selectedPlayers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  return _buildPlayerChip(player, index);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un chip individual para un jugador seleccionado
  /// 
  /// @param player Datos del jugador
  /// @param index Posición del jugador en la lista (0-3)
  /// @return Widget del chip con nombre, número y botones
  Widget _buildPlayerChip(ReservationPlayer player, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          // Círculo con número de jugador
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: player.isMainBooker ? Colors.blue : Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Nombre del jugador (truncado si es muy largo)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              player.name.length > 15 
                  ? '${player.name.substring(0, 15)}...'
                  : player.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: player.isMainBooker ? Colors.blue.shade700 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Botón remover (solo para no-organizadores)
          if (!player.isMainBooker) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _removePlayer(player),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.remove_circle, 
                  color: Colors.red, 
                  size: 18
                ),
              ),
            ),
          ],
          
          // Indicador de organizador (estrella)
          if (player.isMainBooker) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Colors.amber, size: 14),
          ],
        ],
      ),
    );
  }

  /// Construye la sección de búsqueda de jugadores
  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buscar jugador ${_selectedPlayers.length + 1} de 4:',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  /// Construye la lista de jugadores disponibles
  /// 
  /// Muestra lista scrollable de usuarios que se pueden agregar:
  /// - Filtra según texto de búsqueda
  /// - Excluye usuarios ya seleccionados
  /// - Destaca usuarios especiales VISITA
  /// - Botones para agregar jugadores
  Widget _buildAvailablePlayersList() {
    return Container(
      height: 150,
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
                    fontSize: 14,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 2),
              itemCount: _filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = _filteredPlayers[index];
                return _buildAvailablePlayerTile(player);
              },
            ),
    );
  }

  /// Construye un tile para un jugador disponible
  /// 
  /// @param player Datos del jugador disponible
  /// @return ListTile configurado con datos del jugador
  Widget _buildAvailablePlayerTile(ReservationPlayer player) {
    final isSpecialVisit = ['PADEL1 VISITA', 'PADEL2 VISITA', 'PADEL3 VISITA', 'PADEL4 VISITA']
        .contains(player.name.toUpperCase());
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isSpecialVisit ? Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(6),
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
          onPressed: () => _addPlayer(player),
          icon: Icon(
            Icons.add_circle, 
            color: isSpecialVisit ? Colors.orange : Colors.green, 
            size: 20
          ),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        ),
        onTap: () => _addPlayer(player),
      ),
    );
  }

  /// Construye el mensaje de error cuando hay conflictos
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Icon(Icons.error, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conflicto de horario:',
                  style: TextStyle(
                    color: Colors.red, 
                    fontSize: 13,
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el indicador de progreso de envío de emails
  Widget _buildEmailProgressIndicator() {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        if (provider.isSendingEmails) {
          return Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  '📧 Enviando confirmaciones por email...',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Construye los botones de acción (Cancelar/Confirmar)
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botón Cancelar
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.red[300]!, width: 1.5),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16, 
                color: Colors.red[700], 
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        
        // Botón Confirmar Reserva
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
                    _getButtonText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _canCreateReservation ? Colors.white : Colors.grey[600],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Obtiene el texto apropiado para el botón de confirmación
  /// 
  /// @return String con el texto según el estado actual
  String _getButtonText() {
    if (_canCreateReservation) {
      return 'Confirmar Reserva';
    } else if (_errorMessage != null) {
      return 'Resolver conflictos';
    } else {
      return 'Elije + ${4 - _selectedPlayers.length} players +';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  String toString() => 'ReservationPlayer(name: $name, email: $email, isMainBooker: $isMainBooker)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservationPlayer &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}