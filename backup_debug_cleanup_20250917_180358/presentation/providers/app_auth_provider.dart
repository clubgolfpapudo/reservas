// lib/presentation/providers/app_auth_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/services/firebase_user_service.dart';

class AppauthProvider with ChangeNotifier {
  final FirebaseUserService _userService = FirebaseUserService();
  
  bool _isUserValidated = false;
  String? _currentUserEmail;
  String? _currentUserName;
  bool _isLoading = false;

  // Getters
  bool get isUserValidated => _isUserValidated;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get isLoading => _isLoading;

  // Validar usuario usando el sistema existente de 502+ usuarios
  Future<bool> validateUser(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Usar el servicio existente que ya tiene los 502+ usuarios
      final users = await FirebaseUserService.getAllUsers();
      
      // Buscar usuario por email (case insensitive)
      final user = users.firstWhere(
        (user) => user['email']?.toString().toLowerCase() == email.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (user.isNotEmpty) {
        // Usuario encontrado
        _isUserValidated = true;
        _currentUserEmail = email;
        _currentUserName = user['name']?.toString() ?? '';
        
        if (kDebugMode) {
          print('✅ Usuario validado: $email - ${_currentUserName}');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Usuario no encontrado
        _isUserValidated = false;
        _currentUserEmail = null;
        _currentUserName = null;
        
        if (kDebugMode) {
          print('❌ Usuario no encontrado: $email');
        }
        
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validando usuario: $e');
      }
      
      _isUserValidated = false;
      _currentUserEmail = null;
      _currentUserName = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout / cambiar usuario
  void logout() {
    _isUserValidated = false;
    _currentUserEmail = null;
    _currentUserName = null;
    _isLoading = false;
    notifyListeners();
    
    if (kDebugMode) {
      print('🔓 Usuario deslogueado');
    }
  }

  // Verificar si hay parámetros URL para auto-login
  Future<void> checkAutoLogin() async {
    try {
      final uri = Uri.base;
      final email = uri.queryParameters['email'];
      
      if (email != null && email.isNotEmpty) {
        if (kDebugMode) {
          print('🔍 Auto-login detectado para: $email');
        }
        await validateUser(email);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en auto-login: $e');
      }
    }
  }

  // Obtener información del usuario actual
  Map<String, dynamic> getCurrentUser() {
    return {
      'email': _currentUserEmail,
      'name': _currentUserName,
      'isValidated': _isUserValidated,
    };
  }
  
  void signOut() {
    // Aquí puedes limpiar tokens, cerrar sesión en Firebase, etc.
    print('[LOG] Usuario ha cerrado sesión');
    // notifyListeners(); si aplica
  }
}
