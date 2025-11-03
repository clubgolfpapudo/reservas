// lib/presentation/mixins/date_navigation_mixin.dart
// 🔥 NUEVO: Mixin reutilizable para navegación robusta en Golf, Tenis y Pádel

import 'package:flutter/material.dart';
import '../providers/booking_provider.dart';

/// Mixin que proporciona navegación de fechas robusta con:
/// - Debouncing de clicks
/// - Prevención de navegación simultánea
/// - Manejo de errores
/// - Sincronización con PageController
mixin DateNavigationMixin<T extends StatefulWidget> on State<T> {
  
  // Estado de navegación
  bool _isNavigating = false;
  DateTime? _lastNavigationTime;
  static const int _navigationDebounceMs = 350;
  
  /// Getter para saber si está navegando
  bool get isNavigating => _isNavigating;
  
  /// Setter para actualizar estado de navegación
  set isNavigating(bool value) {
    if (mounted && _isNavigating != value) {
      setState(() {
        _isNavigating = value;
      });
    }
  }
  
  /// Navegar a fecha anterior con protección
  void navigateToPreviousDate(
    PageController pageController,
    BookingProvider provider,
  ) {
    if (!_canNavigate(provider.canGoToPreviousDate)) {
      return;
    }
    
    _performNavigation(
      pageController: pageController,
      direction: -1,
      onNavigate: () => pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
  
  /// Navegar a fecha siguiente con protección
  void navigateToNextDate(
    PageController pageController,
    BookingProvider provider,
  ) {
    if (!_canNavigate(provider.canGoToNextDate)) {
      return;
    }
    
    _performNavigation(
      pageController: pageController,
      direction: 1,
      onNavigate: () => pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
  
  /// Navegar a fecha específica por índice
  Future<void> navigateToDateIndex(
    PageController pageController,
    int targetIndex,
  ) async {
    if (_isNavigating) return;
    
    isNavigating = true;
    
    try {
      await pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } catch (e) {
      debugPrint('❌ Error navegando a índice $targetIndex: $e');
    } finally {
      isNavigating = false;
    }
  }
  
  /// Verifica si se puede navegar
  bool _canNavigate(bool providerCanNavigate) {
    // Ya navegando
    if (_isNavigating) {
      debugPrint('🚫 Navegación ya en progreso');
      return false;
    }
    
    // Provider no permite
    if (!providerCanNavigate) {
      debugPrint('🚫 Provider no permite navegación');
      return false;
    }
    
    // Debouncing
    final now = DateTime.now();
    if (_lastNavigationTime != null) {
      final diff = now.difference(_lastNavigationTime!).inMilliseconds;
      if (diff < _navigationDebounceMs) {
        debugPrint('🚫 Click demasiado rápido, ignorando (${diff}ms)');
        return false;
      }
    }
    
    return true;
  }
  
  /// Ejecuta navegación con manejo de errores
  Future<void> _performNavigation({
    required PageController pageController,
    required int direction,
    required Future<void> Function() onNavigate,
  }) async {
    // Marcar inicio de navegación
    final now = DateTime.now();
    isNavigating = true;
    _lastNavigationTime = now;
    
    final directionArrow = direction < 0 ? '⬅️' : '➡️';
    debugPrint('$directionArrow Iniciando navegación...');
    
    try {
      await onNavigate();
      debugPrint('✅ Navegación completada');
    } catch (error) {
      debugPrint('❌ Error en navegación: $error');
    } finally {
      isNavigating = false;
    }
  }
  
  /// Listener para PageController que resetea estado al terminar animación
  void handlePageControllerChange(PageController pageController) {
    if (!pageController.position.isScrollingNotifier.value) {
      isNavigating = false;
    }
  }
  
  /// Limpia estado de navegación
  void cleanupNavigation() {
    _isNavigating = false;
    _lastNavigationTime = null;
  }
}