// lib/presentation/pages/common/sport_selector_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/sport_button.dart';
import '../reservations_page.dart';
import '../tennis_reservations_page.dart';

class SportSelectorPage extends StatefulWidget {
  const SportSelectorPage({super.key});

  @override
  State<SportSelectorPage> createState() => _SportSelectorPageState();
}

class _SportSelectorPageState extends State<SportSelectorPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUrlParameters();
  }

  void _checkUrlParameters() {
    // Verificar si hay parámetros en la URL para auto-completar
    final uri = Uri.base;
    final email = uri.queryParameters['email'];
    final name = uri.queryParameters['name'];
    
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
    if (name != null && name.isNotEmpty) {
      _nameController.text = Uri.decodeComponent(name);
    }
    
    // Si tenemos ambos parámetros, validar automáticamente
    if (email != null && email.isNotEmpty && name != null && name.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateUser();
      });
    }
  }

  Future<void> _validateUser() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingrese su email';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isValid = await authProvider.validateUser(_emailController.text.trim());
      
      if (isValid) {
        setState(() {
          _isValidating = false;
        });
        // Usuario válido - mostrar selector de deportes
      } else {
        setState(() {
          _isValidating = false;
          _errorMessage = 'Email no encontrado en la base de socios del club';
        });
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Error al validar usuario. Intente nuevamente.';
      });
    }
  }

  void _navigateToSport(String sport) {
    if (sport == 'padel') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ReservationsPage()),
      );
    } else if (sport == 'tennis') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TennisReservationsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isUserValidated = authProvider.isUserValidated;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo y título del club
              const Icon(
                Icons.sports_tennis,
                size: 80,
                color: Color(0xFF2E7AFF),
              ),
              const SizedBox(height: 24),
              const Text(
                'CLUB DE GOLF PAPUDO',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7AFF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sistema de Reservas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              if (!isUserValidated) ...[
                // Formulario de validación
                const Text(
                  'Ingrese su email para continuar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'ejemplo@email.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                    errorText: _errorMessage,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isValidating ? null : _validateUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isValidating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Validar Usuario',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ] else ...[
                // Selector de deportes
                const Text(
                  'Selecciona tu deporte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: SportButton(
                        title: 'Pádel',
                        subtitle: '3 canchas',
                        icon: Icons.sports_tennis,
                        color: const Color(0xFF2E7AFF),
                        onTap: () => _navigateToSport('padel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SportButton(
                        title: 'Tenis',
                        subtitle: '4 canchas',
                        icon: Icons.sports_tennis,
                        color: const Color(0xFF8D6E63),
                        onTap: () => _navigateToSport('tennis'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Botón Golf (próximamente)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Golf estará disponible próximamente'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4CAF50)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Golf - Próximamente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botón cambiar usuario
                TextButton(
                  onPressed: () {
                    authProvider.logout();
                    _emailController.clear();
                    _nameController.clear();
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: const Text(
                    'Cambiar usuario',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}