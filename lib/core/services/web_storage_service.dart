import 'dart:html' as html;

class WebStorageService {
  static const String _keyUserEmail = 'cgp_user_email';
  static const String _keyUserName = 'cgp_user_name';
  static const String _keyIsLoggedIn = 'cgp_is_logged_in';

  // Guardar sesión
  static void saveSession(String email, String name) {
    try {
      html.window.localStorage[_keyUserEmail] = email;
      html.window.localStorage[_keyUserName] = name;
      html.window.localStorage[_keyIsLoggedIn] = 'true';
      print('=== SESSION SAVED: $email ===');
    } catch (e) {
      print('=== ERROR SAVING SESSION: $e ===');
    }
  }

  // Leer sesión
  static Map<String, String?> getSession() {
    try {
      final email = html.window.localStorage[_keyUserEmail];
      final name = html.window.localStorage[_keyUserName];
      final isLoggedIn = html.window.localStorage[_keyIsLoggedIn];

      print('=== READING SESSION ===');
      print('=== Email: $email ===');
      print('=== Name: $name ===');
      print('=== IsLoggedIn: $isLoggedIn ===');

      return {
        'email': email,
        'name': name,
        'isLoggedIn': isLoggedIn,
      };
    } catch (e) {
      print('=== ERROR READING SESSION: $e ===');
      return {};
    }
  }

  // Limpiar sesión
  static void clearSession() {
    try {
      html.window.localStorage.remove(_keyUserEmail);
      html.window.localStorage.remove(_keyUserName);
      html.window.localStorage.remove(_keyIsLoggedIn);
      print('=== SESSION CLEARED ===');
    } catch (e) {
      print('=== ERROR CLEARING SESSION: $e ===');
    }
  }

  // Verificar si hay sesión
  static bool hasSession() {
    final isLoggedIn = html.window.localStorage[_keyIsLoggedIn];
    return isLoggedIn == 'true';
  }
}