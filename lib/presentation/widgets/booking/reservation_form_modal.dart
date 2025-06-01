// lib/presentation/widgets/booking/reservation_form_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../../core/constants/app_constants.dart';
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
  
  // Lista de jugadores seleccionados (incluye al usuario principal)
  List<ReservationPlayer> _selectedPlayers = [];
  
  // Lista filtrada de jugadores disponibles
  List<ReservationPlayer> _availablePlayers = [];
  List<ReservationPlayer> _filteredPlayers = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _searchController.addListener(_filterPlayers);
    
    // INICIALIZAR LISTA FILTRADA DESPUÉS DE CONFIGURAR TODO
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterPlayers();
    });
  }

  void _initializeForm() {
    // Agregar usuario principal automáticamente
    _selectedPlayers.add(ReservationPlayer(
      name: 'FELIPE GARCIA',
      email: 'felipe@garciab.cl',
      isMainBooker: true,
    ));

    // Simular lista de jugadores disponibles (en producción vendrá de Firebase)
    _availablePlayers = [
      ReservationPlayer(name: 'ANA M BELMAR P', email: 'anita@buzeta.cl'),
      ReservationPlayer(name: 'CLARA PARDO B', email: 'clara@garciab.cl'),
      ReservationPlayer(name: 'JUAN F GONZALEZ P', email: 'fgarcia88@hotmail.com'),
      ReservationPlayer(name: 'PEDRO MARTINEZ L', email: 'pedro.martinez@example.com'),
      ReservationPlayer(name: 'PEDRO SILVA G', email: 'pedro.silva@example.com'),
      ReservationPlayer(name: 'PEDRO JIMENEZ R', email: 'pedro.jimenez@example.com'),
      ReservationPlayer(name: 'ADRIEN GRYNBLAT B', email: 'adrien@example.com'),
      ReservationPlayer(name: 'AGUSTIN RODRIGUEZ D', email: 'agustin@example.com'),
      ReservationPlayer(name: 'AGUSTIN VICUÑA', email: 'avicuna@example.com'),
      ReservationPlayer(name: 'AUGUSTINA BASUALTO C', email: 'augustina@example.com'),
      ReservationPlayer(name: 'ALBERTO FRAUENBERG D', email: 'alberto@example.com'),
      ReservationPlayer(name: 'ALEJANDRA CHAMUDES G', email: 'alejandra@example.com'),
    ];
    
    // NO inicializar _filteredPlayers aquí - se hace en _filterPlayers()
  }

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

  void _addPlayer(ReservationPlayer player) {
    if (_selectedPlayers.length < 4) {
      setState(() {
        _selectedPlayers.add(player);
        _searchController.clear();
        _filterPlayers();
      });
    }
  }

  void _removePlayer(ReservationPlayer player) {
    if (!player.isMainBooker) {
      setState(() {
        _selectedPlayers.remove(player);
        _filterPlayers();
      });
    }
  }

  bool get _canCreateReservation => _selectedPlayers.length == 4;

  Future<void> _createReservation() async {
    if (!_canCreateReservation) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final booking = Booking(
        courtNumber: widget.courtId,
        date: widget.date,
        timeSlot: widget.timeSlot,
        players: _selectedPlayers.map((player) => BookingPlayer(
          name: player.name,
          email: player.email,
          isConfirmed: true,
        )).toList(),
        status: BookingStatus.complete,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<BookingProvider>();
      await provider.createBooking(booking);

      // Mostrar confirmación y cerrar modal
      _showSuccessDialog();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creando reserva: $e';
      });
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
              'Tu reserva ha sido confirmada exitosamente:',
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
            Text(
              'Se enviarán emails de confirmación a todos los jugadores.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: 400,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.sports_tennis,
                    color: AppConstants.getCourtColorAsColor(widget.courtName),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courtName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${_formatDisplayDate()} • ${widget.timeSlot}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Jugadores seleccionados
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jugadores (${_selectedPlayers.length}/4)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._selectedPlayers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (!player.isMainBooker)
                              IconButton(
                                onPressed: () => _removePlayer(player),
                                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              
              if (_selectedPlayers.length < 4) ...[
                const SizedBox(height: 16),
                
                // Campo de búsqueda
                Text(
                  'Buscar jugador ${_selectedPlayers.length + 1} de 4:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Lista de jugadores disponibles
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 200, // Altura máxima fija para evitar overflow
                      minHeight: 100,
                    ),
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
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _filteredPlayers.length,
                            itemBuilder: (context, index) {
                              final player = _filteredPlayers[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    radius: 18,
                                    child: Text(
                                      player.name[0],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    player.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _addPlayer(player),
                                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 24),
                                  ),
                                  onTap: () => _addPlayer(player),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _canCreateReservation
                                  ? 'Confirmar Reserva'
                                  : 'Selecciona ${4 - _selectedPlayers.length} jugadores más',
                              style: TextStyle(
                                fontSize: 16,
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