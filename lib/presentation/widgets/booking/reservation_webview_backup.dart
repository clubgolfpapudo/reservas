// lib/presentation/widgets/booking/reservation_webview.dart - COMPLETO Y CORREGIDO
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';

class ReservationWebView extends StatefulWidget {
  final String userEmail;
  final String courtId;
  final String date;
  final String timeSlot;

  const ReservationWebView({
    Key? key,
    required this.userEmail,
    required this.courtId,
    required this.date,
    required this.timeSlot,
  }) : super(key: key);

  @override
  State<ReservationWebView> createState() => _ReservationWebViewState();
}

class _ReservationWebViewState extends State<ReservationWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _pageTitle = 'Reservar';
  List<String> _debugLogs = [];
  int _automationStep = 0;
  bool _automationCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final gasUrl = _buildReservationUrl();
    
    _addDebugLog('🌐 Iniciando WebView con automatización para: ${_getCourtName()} ${widget.timeSlot}');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _addDebugLog('📄 Página iniciada: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            _addDebugLog('✅ Página cargada: $url');
            setState(() {
              _isLoading = false;
            });
            
            // ✨ AUTOMATIZACIÓN ESPECÍFICA PARA LA INTERFAZ GAS
            _startTargetedAutomation();
            _updatePageTitle(url);
            _checkForCompletion(url);
          },
          onWebResourceError: (WebResourceError error) {
            _addDebugLog('❌ Error: ${error.description}');
          },
        ),
      )
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        final logMsg = '🔍 JS Console: ${message.message}';
        print('🔍 WEBVIEW JS: ${message.message}'); // ✨ NUEVO: Print directo de JS
        _addDebugLog(logMsg);
      })
      ..setUserAgent('CGP_Reservas_App/1.0')
      ..loadRequest(Uri.parse(gasUrl));
  }

  void _addDebugLog(String message) {
    print('🔍 WEBVIEW DEBUG: $message'); // ✨ NUEVO: Print directo a consola Flutter
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)} - $message');
      if (_debugLogs.length > 150) _debugLogs.removeAt(0);
    });
  }

  /// 🎯 AUTOMATIZACIÓN ESPECÍFICA PARA LA INTERFAZ VISTA EN LA IMAGEN
  void _startTargetedAutomation() async {
    if (_automationCompleted) return;
    
    _addDebugLog('🤖 INICIANDO automatización específica...');
    print('🚨🚨🚨 AUTOMATIZACIÓN INICIADA - PLAIYA 18:00 🚨🚨🚨');
    
    // Paso 1: Esperar carga completa (más tiempo)
    await Future.delayed(const Duration(milliseconds: 4000));
    _automationStep = 1;
    _addDebugLog('⏳ ESPERANDO carga completa...');
    print('⏳ PASO 1: Esperando carga de 4 segundos...');
    
    // Paso 2: Verificar interfaz específica
    await _verifyGASInterface();
    
    // Paso 3: Automatizar clicks secuenciales
    await _executeSequentialClicks();
  }

  /// 🔍 Verificar que tenemos la interfaz correcta del GAS
  Future<void> _verifyGASInterface() async {
    _automationStep = 2;
    _addDebugLog('🔍 Paso 2: Verificando interfaz del sistema GAS...');
    
    final verifyScript = '''
      (function() {
        console.log('🔍 === VERIFICACIÓN AVANZADA INTERFAZ GAS ===');
        
        // Buscar elementos específicos de la interfaz que vimos
        var hasReservasTitle = document.body.textContent.includes('Reservas');
        console.log('¿Tiene título Reservas?:', hasReservasTitle);
        
        // BÚSQUEDA AVANZADA: No solo botones tradicionales
        var allElements = document.querySelectorAll('*');
        var piteElement = null;
        var lilenElement = null;
        var plaiyaElement = null;
        var reservarElements = [];
        
        console.log('🔍 Analizando', allElements.length, 'elementos...');
        
        // Buscar elementos que contengan texto de canchas
        for (var i = 0; i < allElements.length; i++) {
          var el = allElements[i];
          var text = (el.textContent || el.innerText || '').trim();
          
          // Verificar si es un elemento potencialmente clickeable
          var isClickeable = el.tagName === 'BUTTON' || 
                            el.tagName === 'A' || 
                            el.tagName === 'DIV' ||
                            el.tagName === 'SPAN' ||
                            el.onclick !== null ||
                            el.style.cursor === 'pointer' ||
                            el.getAttribute('onclick') !== null ||
                            el.className.includes('button') ||
                            el.className.includes('click') ||
                            el.getAttribute('role') === 'button';
          
          if (text === 'PITE' && isClickeable) {
            piteElement = el;
            console.log('✅ PITE encontrado:', el.tagName, el.className, el.id, 'onclick:', !!el.onclick);
          }
          if (text === 'LILEN' && isClickeable) {
            lilenElement = el;
            console.log('✅ LILEN encontrado:', el.tagName, el.className, el.id, 'onclick:', !!el.onclick);
          }
          if (text === 'PLAIYA' && isClickeable) {
            plaiyaElement = el;
            console.log('✅ PLAIYA encontrado:', el.tagName, el.className, el.id, 'onclick:', !!el.onclick);
          }
          
          // Buscar elementos "Reservar" también
          if (text.includes('Reservar') && isClickeable) {
            reservarElements.push({
              element: el,
              text: text,
              tag: el.tagName,
              className: el.className
            });
          }
        }
        
        // Si no encontramos con criterio estricto, buscar SIN filtro clickeable
        if (!piteElement || !lilenElement || !plaiyaElement) {
          console.log('⚠️ Búsqueda estricta falló, probando búsqueda amplia...');
          
          for (var i = 0; i < allElements.length; i++) {
            var el = allElements[i];
            var text = (el.textContent || el.innerText || '').trim();
            
            if (text === 'PITE' && !piteElement) {
              piteElement = el;
              console.log('📍 PITE encontrado (amplio):', el.tagName, el.className, 'parent:', el.parentElement?.tagName);
            }
            if (text === 'LILEN' && !lilenElement) {
              lilenElement = el;
              console.log('📍 LILEN encontrado (amplio):', el.tagName, el.className, 'parent:', el.parentElement?.tagName);
            }
            if (text === 'PLAIYA' && !plaiyaElement) {
              plaiyaElement = el;
              console.log('📍 PLAIYA encontrado (amplio):', el.tagName, el.className, 'parent:', el.parentElement?.tagName);
            }
          }
        }
        
        console.log('🎯 ELEMENTOS DE RESERVAR ENCONTRADOS:', reservarElements.length);
        reservarElements.forEach(function(item, index) {
          if (index < 3) { // Solo mostrar primeros 3
            console.log('  ' + (index + 1) + '. ' + item.tag + ': "' + item.text + '" [' + item.className + ']');
          }
        });
        
        // Guardar referencias globales para uso posterior
        window.gasElements = {
          pite: piteElement,
          lilen: lilenElement,
          plaiya: plaiyaElement,
          reservarButtons: reservarElements
        };
        
        console.log('📊 RESUMEN FINAL:');
        console.log('  - PITE:', !!piteElement);
        console.log('  - LILEN:', !!lilenElement);
        console.log('  - PLAIYA:', !!plaiyaElement);
        console.log('  - Botones Reservar:', reservarElements.length);
        
        var isValidInterface = hasReservasTitle && (piteElement || lilenElement || plaiyaElement);
        console.log('✅ ¿Interfaz válida?:', isValidInterface);
        
        return isValidInterface;
      })();
    ''';
    
    try {
      await _controller.runJavaScript(verifyScript);
      _addDebugLog('📊 Verificación de interfaz ejecutada');
      
      // Esperar un momento para procesar logs
      await Future.delayed(const Duration(milliseconds: 1000));
      
    } catch (e) {
      _addDebugLog('❌ Error verificando interfaz: $e');
    }
  }

  /// 🖱️ Ejecutar clicks secuenciales automáticos
  Future<void> _executeSequentialClicks() async {
    _automationStep = 3;
    _addDebugLog('🖱️ EJECUTANDO clicks secuenciales...');
    print('🚨 PASO 3: Iniciando clicks automáticos...');
    
    final courtName = _getCourtName();
    final timeSlot = widget.timeSlot;
    
    print('🎯 TARGET: $courtName + $timeSlot');
    
    // PASO 3A: Hacer click en la cancha
    print('🏓 PASO 3A: Click en cancha $courtName...');
    await _clickCourt(courtName);
    
    // PASO 3B: Esperar y hacer click en el horario
    await Future.delayed(const Duration(milliseconds: 1500));
    print('⏰ PASO 3B: Click en horario $timeSlot...');
    await _clickTimeSlot(timeSlot);
    
    // PASO 3C: Hacer click en "Reservar"
    await Future.delayed(const Duration(milliseconds: 1500));
    print('🎯 PASO 3C: Click en botón Reservar...');
    await _clickReservarButton();
    
    _automationCompleted = true;
    _addDebugLog('🎉 AUTOMATIZACIÓN COMPLETADA');
    print('🎉🎉🎉 AUTOMATIZACIÓN COMPLETADA 🎉🎉🎉');
  }

  /// 🏓 Click específico en cancha
  Future<void> _clickCourt(String courtName) async {
    _addDebugLog('🏓 Haciendo click en cancha: $courtName');
    
    final clickCourtScript = '''
      (function() {
        console.log('🎯 CLICK AVANZADO EN CANCHA: $courtName');
        
        var targetCourt = '$courtName';
        var clicked = false;
        
        // Estrategia 0: Buscar por selectores CSS específicos de la estructura visual
        console.log('🎯 ESTRATEGIA 0: Selectores CSS basados en estructura...');
        var cssSelectors = [
          // Posibles selectores para botones de cancha
          'div:contains("' + targetCourt + '")',
          'span:contains("' + targetCourt + '")',
          'button:contains("' + targetCourt + '")',
          '[role="button"]:contains("' + targetCourt + '")',
          // Selectores por posición (PITE=primero, LILEN=segundo, PLAIYA=tercero)
          'div:nth-child(3)', // PLAIYA es el tercer botón
          'span:nth-child(3)',
          // Selectores por estructura de tabs
          '.tab:nth-child(3)',
          '.button:nth-child(3)',
          '.court:nth-child(3)'
        ];
        
        for (var s = 0; s < cssSelectors.length; s++) {
          var selector = cssSelectors[s];
          try {
            // Adaptación manual para :contains (no nativo en CSS)
            if (selector.includes(':contains')) {
              continue; // Saltamos estos por ahora
            }
            
            var elements = document.querySelectorAll(selector);
            if (elements.length > 0) {
              console.log('🎯 Selector encontrado: ' + selector + ' (' + elements.length + ' elementos)');
              
              for (var e = 0; e < elements.length; e++) {
                var el = elements[e];
                var text = (el.textContent || '').trim();
                console.log('  - "' + text + '" (' + el.tagName + ')');
                
                if (text === targetCourt || text.includes(targetCourt)) {
                  try {
                    el.click();
                    console.log('✅ Click exitoso con selector CSS: ' + selector);
                    clicked = true;
                    break;
                  } catch (e) {
                    console.log('❌ Click falló con selector: ' + selector);
                  }
                }
              }
              if (clicked) break;
            }
          } catch (e) {
            // Selector no válido, continuar
          }
        }
        
        if (clicked) {
          return clicked;
        }
        if (window.gasElements && window.gasElements[targetCourt.toLowerCase()]) {
          var element = window.gasElements[targetCourt.toLowerCase()];
          console.log('🎯 Intentando click en elemento guardado:', element.tagName, element.className);
          
          try {
            // Intentar diferentes métodos de click
            element.click();
            console.log('✅ Click directo exitoso en elemento guardado');
            clicked = true;
          } catch (e) {
            console.log('❌ Click directo falló, probando evento:', e.message);
            try {
              var event = new MouseEvent('click', { view: window, bubbles: true, cancelable: true });
              element.dispatchEvent(event);
              console.log('✅ Click por evento exitoso en elemento guardado');
              clicked = true;
            } catch (e2) {
              console.log('❌ Click por evento también falló:', e2.message);
            }
          }
        }
        
        // Estrategia 2: Buscar elemento clickeable manualmente (más amplio)
        if (!clicked) {
          console.log('🔍 Búsqueda manual de elemento ' + targetCourt + '...');
          var allElements = document.querySelectorAll('*');
          
          for (var i = 0; i < allElements.length; i++) {
            var el = allElements[i];
            var text = (el.textContent || el.innerText || '').trim();
            
            if (text === targetCourt) {
              console.log('📍 Elemento encontrado:', el.tagName, el.className, 'parent:', el.parentElement?.tagName);
              
              // Intentar click en el elemento
              try {
                el.click();
                console.log('✅ Click directo exitoso en búsqueda manual');
                clicked = true;
                break;
              } catch (e) {
                console.log('❌ Click directo falló, probando en parent...');
                
                // Si el elemento no es clickeable, probar en el parent
                if (el.parentElement) {
                  try {
                    el.parentElement.click();
                    console.log('✅ Click en parent exitoso');
                    clicked = true;
                    break;
                  } catch (e2) {
                    console.log('❌ Click en parent también falló');
                  }
                }
              }
            }
          }
        }
        
        // Estrategia 3: Simular eventos touch (para móvil)
        if (!clicked) {
          console.log('📱 Intentando eventos touch para móvil...');
          var allElements = document.querySelectorAll('*');
          
          for (var i = 0; i < allElements.length; i++) {
            var el = allElements[i];
            var text = (el.textContent || el.innerText || '').trim();
            
            if (text === targetCourt) {
              try {
                // Simular secuencia touch
                var touchStart = new TouchEvent('touchstart', { bubbles: true, cancelable: true });
                var touchEnd = new TouchEvent('touchend', { bubbles: true, cancelable: true });
                
                el.dispatchEvent(touchStart);
                setTimeout(function() {
                  el.dispatchEvent(touchEnd);
                }, 50);
                
                console.log('✅ Eventos touch simulados para ' + targetCourt);
                clicked = true;
                break;
              } catch (e) {
                console.log('❌ Eventos touch fallaron:', e.message);
              }
            }
          }
        }
        
        if (!clicked) {
          console.log('❌ TODOS LOS MÉTODOS FALLARON para ' + targetCourt);
          console.log('📋 Elementos que contienen ' + targetCourt + ':');
          
          var allElements = document.querySelectorAll('*');
          var count = 0;
          for (var i = 0; i < allElements.length && count < 5; i++) {
            var el = allElements[i];
            var text = (el.textContent || el.innerText || '').trim();
            if (text === targetCourt) {
              console.log('  ' + (count + 1) + '. ' + el.tagName + ' [' + el.className + '] onclick:' + !!el.onclick + ' parent:' + el.parentElement?.tagName);
              count++;
            }
          }
          
          // ✨ NUEVO: Mostrar TODOS los textos disponibles para debug
          console.log('🔍 TODOS LOS TEXTOS DISPONIBLES (primeros 10):');
          var textCount = 0;
          for (var i = 0; i < allElements.length && textCount < 10; i++) {
            var el = allElements[i];
            var text = (el.textContent || el.innerText || '').trim();
            if (text.length > 0 && text.length < 50) { // Solo textos cortos y no vacíos
              console.log('  - "' + text + '" (' + el.tagName + ')');
              textCount++;
            }
          }
        }
        
        return clicked;
      })();
    ''';
    
    try {
      await _controller.runJavaScript(clickCourtScript);
      _addDebugLog('📋 Click avanzado en $courtName ejecutado');
    } catch (e) {
      _addDebugLog('❌ Error en click de cancha: $e');
    }
  }

  /// ⏰ Click específico en horario
  Future<void> _clickTimeSlot(String timeSlot) async {
    _addDebugLog('⏰ Haciendo click en horario: $timeSlot');
    
    final clickTimeScript = '''
      (function() {
        console.log('🎯 CLICK AVANZADO EN HORARIO: $timeSlot');
        
        var targetTime = '$timeSlot';
        var clicked = false;
        
        // Buscar elementos que contengan el horario
        var allElements = document.querySelectorAll('*');
        var candidates = [];
        
        // Primero recopilar todos los candidatos
        for (var i = 0; i < allElements.length; i++) {
          var el = allElements[i];
          var text = (el.textContent || el.innerText || '').trim();
          
          if (text.includes(targetTime)) {
            candidates.push({
              element: el,
              text: text,
              tag: el.tagName,
              className: el.className,
              hasOnClick: !!el.onclick,
              parent: el.parentElement
            });
          }
        }
        
        console.log('📋 Candidatos para ' + targetTime + ':', candidates.length);
        candidates.forEach(function(candidate, index) {
          if (index < 5) { // ✨ Mostrar más candidatos
            console.log('  ' + (index + 1) + '. ' + candidate.tag + ': "' + candidate.text + '" [' + candidate.className + '] onClick:' + candidate.hasOnClick);
          }
        });
        
        // Estrategia 1: Buscar elemento que termine en "Reservar" 
        for (var i = 0; i < candidates.length; i++) {
          var candidate = candidates[i];
          if (candidate.text.includes('Reservar') || candidate.text.includes('Disponible')) {
            console.log('🎯 Intentando click en candidato con Reservar/Disponible...');
            try {
              candidate.element.click();
              console.log('✅ Click exitoso en elemento con Reservar/Disponible');
              clicked = true;
              break;
            } catch (e) {
              console.log('❌ Click falló, probando parent...');
              if (candidate.parent) {
                try {
                  candidate.parent.click();
                  console.log('✅ Click exitoso en parent del elemento');
                  clicked = true;
                  break;
                } catch (e2) {
                  console.log('❌ Click en parent también falló');
                }
              }
            }
          }
        }
        
        // Estrategia 2: Click en cualquier candidato
        if (!clicked) {
          console.log('🔄 Probando click en cualquier candidato...');
          for (var i = 0; i < candidates.length; i++) {
            var candidate = candidates[i];
            
            try {
              candidate.element.click();
              console.log('✅ Click exitoso en candidato general');
              clicked = true;
              break;
            } catch (e) {
              console.log('❌ Click en candidato ' + i + ' falló');
            }
          }
        }
        
        // Estrategia 3: Eventos touch para móvil
        if (!clicked && candidates.length > 0) {
          console.log('📱 Probando eventos touch...');
          var firstCandidate = candidates[0];
          
          try {
            var touchStart = new TouchEvent('touchstart', { bubbles: true, cancelable: true });
            var touchEnd = new TouchEvent('touchend', { bubbles: true, cancelable: true });
            
            firstCandidate.element.dispatchEvent(touchStart);
            setTimeout(function() {
              firstCandidate.element.dispatchEvent(touchEnd);
            }, 50);
            
            console.log('✅ Eventos touch simulados');
            clicked = true;
          } catch (e) {
            console.log('❌ Eventos touch fallaron:', e.message);
          }
        }
        
        if (!clicked) {
          console.log('❌ TODOS LOS MÉTODOS FALLARON para horario ' + targetTime);
        }
        
        return clicked;
      })();
    ''';
    
    try {
      await _controller.runJavaScript(clickTimeScript);
      _addDebugLog('📋 Click avanzado en horario $timeSlot ejecutado');
    } catch (e) {
      _addDebugLog('❌ Error en click de horario: $e');
    }
  }

  /// 🎯 Click en botón "Reservar"
  Future<void> _clickReservarButton() async {
    _addDebugLog('🎯 Buscando y haciendo click en botón Reservar...');
    
    final clickReservarScript = '''
      (function() {
        console.log('🎯 CLICK EN BOTÓN RESERVAR');
        
        var clicked = false;
        var reservarTexts = ['Reservar', 'RESERVAR', 'Continuar', 'CONTINUAR'];
        
        // Buscar botones con texto "Reservar"
        var allElements = document.querySelectorAll('*');
        
        for (var textIndex = 0; textIndex < reservarTexts.length; textIndex++) {
          var searchText = reservarTexts[textIndex];
          
          for (var i = 0; i < allElements.length; i++) {
            var el = allElements[i];
            var text = (el.textContent || el.innerText || '').trim();
            
            if (text === searchText || text.includes(searchText)) {
              // Verificar que es un botón o elemento clickeable
              var isButton = el.tagName === 'BUTTON' || 
                            el.tagName === 'INPUT' ||
                            el.tagName === 'A' ||
                            el.onclick !== null ||
                            el.className.includes('button') ||
                            el.className.includes('btn');
              
              if (isButton) {
                try {
                  console.log('🎯 Intentando click en botón:', searchText, el.tagName, el.className);
                  el.click();
                  console.log('✅ Click exitoso en botón ' + searchText);
                  clicked = true;
                  break;
                  
                } catch (e) {
                  console.log('❌ Error haciendo click en botón:', e.message);
                }
              }
            }
          }
          
          if (clicked) break;
        }
        
        if (!clicked) {
          console.log('❌ No se encontró botón Reservar clickeable');
          console.log('📋 Botones disponibles:');
          var buttons = document.querySelectorAll('button, input[type="button"], input[type="submit"], a');
          for (var i = 0; i < buttons.length && i < 10; i++) {
            var btn = buttons[i];
            var text = (btn.textContent || btn.value || '').trim();
            console.log('  -', btn.tagName, '"' + text + '"', btn.className);
          }
        }
        
        return clicked;
      })();
    ''';
    
    try {
      await _controller.runJavaScript(clickReservarScript);
      _addDebugLog('📋 Búsqueda de botón Reservar ejecutada');
    } catch (e) {
      _addDebugLog('❌ Error buscando botón Reservar: $e');
    }
  }

  String _buildReservationUrl() {
    const baseUrl = 'https://script.google.com/macros/s/AKfycbxCq2qEapmNHZHzda2Naox5lnmfRBJjM8QVdKUaYnVOUC-nJoMhdqQj4DxvBz2hURhm4g/exec';
    
    final params = {
      'page': 'Padel2',
      'name': 'FELIPE GARCIA',
      'email': widget.userEmail,
      // ✨ Parámetros específicos para automatización
      'autoselect_court': _getCourtName(),
      'autoselect_time': widget.timeSlot,
      'skip_selection': 'true',
    };
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$baseUrl?$queryString';
  }

  void _updatePageTitle(String url) {
    if (url.contains('calendly.com')) {
      setState(() {
        _pageTitle = 'Programar Reserva';
      });
    } else {
      final courtName = _getCourtName();
      setState(() {
        _pageTitle = 'Reservar $courtName ${widget.timeSlot}';
      });
    }
  }

  void _checkForCompletion(String url) {
    if (url.contains('completadas') || 
        url.contains('success') || 
        url.contains('finished')) {
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _handleReservationCompleted();
        }
      });
    }
  }

  void _handleReservationCompleted() {
    _addDebugLog('🎉 Reserva completada exitosamente');
    
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
                  _buildDetailRow(Icons.sports_tennis, 'Cancha', _getCourtName()),
                  _buildDetailRow(Icons.calendar_today, 'Fecha', _formatDisplayDate()),
                  _buildDetailRow(Icons.access_time, 'Hora', widget.timeSlot),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              _triggerDataRefresh();
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

  void _triggerDataRefresh() {
    final provider = context.read<BookingProvider>();
    provider.refresh();
    _addDebugLog('🔄 Datos actualizados después de reserva');
  }

  String _getCourtName() {
    switch (widget.courtId) {
      case 'court_1': return 'PITE';
      case 'court_2': return 'LILEN';
      case 'court_3': return 'PLAIYA';
      default: return 'Cancha';
    }
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
      _addDebugLog('⚠️ Error formateando fecha: $e');
    }
    return widget.date;
  }

  String _getStepDescription() {
    switch (_automationStep) {
      case 0: return 'Preparando automatización...';
      case 1: return 'Esperando carga completa...';
      case 2: return 'Verificando interfaz...';
      case 3: return 'Ejecutando clicks automáticos...';
      default: return _automationCompleted ? '¡Automatización completada!' : 'Procesando...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: const Color(0xFF2E7AFF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugLogs(),
          ),
          if (_isLoading || !_automationCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          // Banner de automatización
          if (!_automationCompleted)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _automationStep >= 3 ? Colors.green : const Color(0xFF2E7AFF),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _automationStep >= 3 ? Icons.auto_fix_high : Icons.hourglass_empty, 
                      color: Colors.white, 
                      size: 18
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getCourtName()} • ${widget.timeSlot} • ${_formatDisplayDate()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getStepDescription(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Loading overlay solo al inicio
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF2E7AFF), strokeWidth: 3),
                    const SizedBox(height: 24),
                    const Text(
                      'Cargando sistema de reservas...',
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatización para ${_getCourtName()} ${widget.timeSlot}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Automatización'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _debugLogs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _debugLogs[index],
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _debugLogs.clear());
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar reserva?'),
        content: const Text(
          '¿Estás seguro que deseas salir? Se perderá el progreso de la reserva actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar reserva'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}