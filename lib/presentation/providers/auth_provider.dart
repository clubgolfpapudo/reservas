// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/services/firebase_user_service.dart';
import '../../core/services/web_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseUserService _userService = FirebaseUserService();
  
  bool _isUserValidated = false;
  String? _currentUserEmail;
  String? _currentUserName;
  bool _isLoading = false;

  bool get isUserValidated => _isUserValidated;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get isLoading => _isLoading;

  // Validar usuario Y guardar sesión
  Future<bool> validateUser(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final users = await FirebaseUserService.getAllUsers();
      
      final user = users.firstWhere(
        (user) => user['email']?.toString().toLowerCase() == email.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (user.isNotEmpty) {
        _isUserValidated = true;
        _currentUserEmail = email;
        _currentUserName = user['name']?.toString() ?? '';
        
        // Guardar en localStorage
        WebStorageService.saveSession(_currentUserEmail!, _currentUserName!);
        
        print('=== Usuario validado: $email ===');
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isUserValidated = false;
        _currentUserEmail = null;
        _currentUserName = null;
        
        print('=== Usuario no encontrado: $email ===');
        
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('=== Error validando usuario: $e ===');
      
      _isUserValidated = false;
      _currentUserEmail = null;
      _currentUserName = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    WebStorageService.clearSession();
    
    _isUserValidated = false;
    _currentUserEmail = null;
    _currentUserName = null;
    _isLoading = false;
    notifyListeners();
    
    print('=== Usuario deslogueado ===');
  }

  // Auto-login desde localStorage
  Future<void> checkAutoLogin() async {
    print('=== INICIO checkAutoLogin ===');
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si hay sesión guardada
      if (WebStorageService.hasSession()) {
        final session = WebStorageService.getSession();
        final savedEmail = session['email'];
        final savedName = session['name'];

        if (savedEmail != null && savedEmail.isNotEmpty) {
          print('=== Sesión encontrada: $savedEmail ===');
          
          // Verificar que el usuario aún existe en Firebase
          final users = await FirebaseUserService.getAllUsers();
          final userExists = users.any(
            (user) => user['email']?.toString().toLowerCase() == savedEmail.toLowerCase(),
          );

          if (userExists) {
            _isUserValidated = true;
            _currentUserEmail = savedEmail;
            _currentUserName = savedName ?? '';
            
            print('=== Auto-login exitoso ===');
            
            _isLoading = false;
            notifyListeners();
            return;
          } else {
            print('=== Usuario no existe, limpiando sesión ===');
            await logout();
          }
        }
      }

      // Backward compatibility: verificar parámetros URL
      final uri = Uri.base;
      final emailFromUrl = uri.queryParameters['email'];
      
      if (emailFromUrl != null && emailFromUrl.isNotEmpty) {
        print('=== Email desde URL: $emailFromUrl ===');
        await validateUser(emailFromUrl);
        return;
      }

      print('=== No hay sesión guardada ===');

    } catch (e) {
      print('=== Error en checkAutoLogin: $e ===');
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getCurrentUser() {
    return {
      'email': _currentUserEmail,
      'name': _currentUserName,
      'isValidated': _isUserValidated,
    };
  }
  
  void signOut() {
    logout();
  }
}