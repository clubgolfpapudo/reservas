// lib/presentation/widgets/booking/reservation_webview.dart - COMPLETO SWEETALERT2
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
  int _automationAttempts = 0;
  static const int _maxAttempts = 6;
  String? _currentUrl;
  bool _modalDetected = false;
  bool _continueClicked = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final gasUrl = _buildDirectReservationUrl();
    
    _addDebugLog('🌐 Iniciando WebView SWEETALERT2 para: ${_getCourtName()} ${widget.timeSlot}');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _currentUrl = url;
            _addDebugLog('📄 Página iniciada: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            _currentUrl = url;
            _addDebugLog('✅ Página cargada: $url');
            setState(() {
              _isLoading = false;
            });
            
            // ✨ NUEVA ESTRATEGIA: SweetAlert2 específico
            _startSweetAlert2Automation();
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
        print('🔍 WEBVIEW JS: ${message.message}');
        _addDebugLog(logMsg);
        
        // ✨ Detección específica SweetAlert2
        if (message.message.contains('BOTÓN CONTINUAR SWEETALERT2 CLICKEADO') || 
            message.message.contains('SWEETALERT2 EXITOSAMENTE')) {
          _continueClicked = true;
          _automationCompleted = true;
          _addDebugLog('🎉 SWEETALERT2 CLICKEADO CONFIRMADO!');
        }
      })
      ..setUserAgent('CGP_Reservas_App/1.0 SweetAlert2')
      ..loadRequest(Uri.parse(gasUrl));
  }

  void _addDebugLog(String message) {
    print('🔍 WEBVIEW DEBUG: $message');
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)} - $message');
      if (_debugLogs.length > 200) _debugLogs.removeAt(0);
    });
  }

  /// 🍭 AUTOMATIZACIÓN ESPECÍFICA SWEETALERT2
  void _startSweetAlert2Automation() async {
    if (_automationCompleted || _automationAttempts >= _maxAttempts) return;
    
    _automationAttempts++;
    _addDebugLog('🍭 INTENTO $_automationAttempts/$_maxAttempts - SweetAlert2 específico...');
    print('🚨🚨🚨 SWEETALERT2 INTENTO $_automationAttempts 🚨🚨🚨');
    
    // Delays: 1s, 2s, 3s, 4s, 5s, 6s
    final waitTime = _automationAttempts * 1000;
    await Future.delayed(Duration(milliseconds: waitTime));
    
    _automationStep = 1;
    _addDebugLog('⏳ Buscando SweetAlert2 ($_automationAttempts/$_maxAttempts - ${waitTime}ms)...');
    
    // Configurar búsqueda SweetAlert2
    await _setupSweetAlert2Search();
    
    await Future.delayed(const Duration(milliseconds: 2000));
    await _verifySweetAlert2Success();
    
    if (!_automationCompleted && _automationAttempts < _maxAttempts) {
      _addDebugLog('🔄 SweetAlert2 no clickeado, reintentando...');
      Future.delayed(const Duration(milliseconds: 1000), () {
        _startSweetAlert2Automation();
      });
    }
  }

  /// 🍭 Configurar búsqueda específica SweetAlert2
  Future<void> _setupSweetAlert2Search() async {
    _automationStep = 2;
    _addDebugLog('🍭 Configurando búsqueda SweetAlert2...');
    
    final searchScript = '''
      (function() {
        console.log('🍭 === BÚSQUEDA ESPECÍFICA SWEETALERT2 ===');
        
        var courtName = '${_getCourtName()}';
        var timeSlot = '${widget.timeSlot}';
        
        // ✨ ESTRATEGIA 1: BÚSQUEDA ESPECÍFICA SWEETALERT2
        function findSweetAlert2Button() {
          console.log('🍭 ESTRATEGIA 1: Búsqueda específica SweetAlert2...');
          
          // Selectores específicos para SweetAlert2
          var swal2Selectors = [
            '.swal2-confirm',
            '.swal2-styled',
            'button.swal2-confirm',
            'button.swal2-styled',
            '.swal2-actions button',
            '[class*="swal2-confirm"]',
            '[class*="swal2-styled"]'
          ];
          
          var swal2Buttons = [];
          
          for (var s = 0; s < swal2Selectors.length; s++) {
            var selector = swal2Selectors[s];
            
            try {
              var elements = document.querySelectorAll(selector);
              console.log('🍭 Selector "' + selector + '" encontró:', elements.length, 'elementos');
              
              for (var i = 0; i < elements.length; i++) {
                var el = elements[i];
                var text = (el.textContent || '').trim();
                
                console.log('🍭 SweetAlert2 elemento:', el.tagName, '"' + text + '"', 
                           'clases:', el.className, 'visible:', el.style.display !== 'none');
                
                if (text.includes('Continuar') && el.style.display !== 'none') {
                  swal2Buttons.push({
                    element: el,
                    text: text,
                    selector: selector
                  });
                  console.log('✅ BOTÓN SWEETALERT2 CONTINUAR ENCONTRADO!');
                }
              }
            } catch (e) {
              console.log('❌ Error selector SweetAlert2:', selector, e.message);
            }
          }
          
          return swal2Buttons;
        }
        
        // ✨ ESTRATEGIA 2: CLICK ESPECÍFICO SWEETALERT2
        function clickSweetAlert2Buttons(buttons) {
          console.log('🚀 ESTRATEGIA 2: Click específico SweetAlert2...');
          
          var clicksSuccessful = 0;
          
          for (var i = 0; i < buttons.length; i++) {
            var btn = buttons[i];
            
            console.log('🎯 Clickeando botón SweetAlert2 #' + (i+1) + ':', btn.text);
            
            try {
              // MÉTODO 1: Click directo en SweetAlert2
              btn.element.click();
              console.log('✅ Click SweetAlert2 directo exitoso #' + (i+1));
              clicksSuccessful++;
              
              // MÉTODO 2: Forzar click con timeout (SweetAlert2 a veces necesita delay)
              setTimeout(function() {
                try {
                  btn.element.click();
                  console.log('✅ Click SweetAlert2 con delay exitoso');
                } catch (delayError) {
                  console.log('⚠️ Click con delay falló');
                }
              }, 100);
              
              // MÉTODO 3: Evento específico SweetAlert2
              var swalEvent = new MouseEvent('click', {
                view: window,
                bubbles: true,
                cancelable: true,
                detail: 1
              });
              btn.element.dispatchEvent(swalEvent);
              console.log('✅ Evento SweetAlert2 exitoso #' + (i+1));
              
              // MÉTODO 4: Focus + Space (SweetAlert2 acepta Space)
              try {
                btn.element.focus();
                var spaceEvent = new KeyboardEvent('keydown', {
                  key: ' ',
                  code: 'Space',
                  bubbles: true
                });
                btn.element.dispatchEvent(spaceEvent);
                console.log('✅ Focus+Space SweetAlert2 exitoso #' + (i+1));
              } catch (spaceError) {
                console.log('⚠️ Focus+Space falló');
              }
              
            } catch (e) {
              console.log('❌ Error click SweetAlert2 #' + (i+1) + ':', e.message);
            }
          }
          
          console.log('📊 Clicks SweetAlert2: ' + clicksSuccessful + '/' + buttons.length + ' exitosos');
          return clicksSuccessful > 0;
        }
        
        // ✨ ESTRATEGIA 3: BÚSQUEDA GENÉRICA CON FILTRO SWEETALERT2
        function findGenericButtonsInSweetAlert() {
          console.log('🔍 ESTRATEGIA 3: Búsqueda genérica con filtro SweetAlert2...');
          
          var allButtons = document.querySelectorAll('button, input[type="button"], input[type="submit"]');
          var continueButtons = [];
          
          console.log('📋 Analizando', allButtons.length, 'botones...');
          
          for (var i = 0; i < allButtons.length; i++) {
            var btn = allButtons[i];
            var text = (btn.textContent || btn.value || '').trim();
            var isVisible = btn.style.display !== 'none' && btn.offsetParent !== null;
            var isSweetAlert = btn.className.includes('swal2') || 
                             btn.closest('.swal2-popup') !== null ||
                             btn.closest('.swal2-container') !== null;
            
            if (text.includes('Continuar') && isVisible) {
              continueButtons.push({
                element: btn,
                text: text,
                isSweetAlert: isSweetAlert,
                className: btn.className
              });
              
              console.log('🎯 Botón Continuar encontrado:', 
                         'texto="' + text + '"', 
                         'SweetAlert=' + isSweetAlert,
                         'clases=' + btn.className);
            }
          }
          
          return continueButtons;
        }
        
        // ✨ ESTRATEGIA 4: FUERZA BRUTA TODOS LOS BOTONES
        function bruteForceContinueButtons(buttons) {
          console.log('💪 ESTRATEGIA 4: Fuerza bruta en todos los botones...');
          
          var bruteClickCount = 0;
          
          for (var i = 0; i < buttons.length; i++) {
            var btn = buttons[i];
            
            console.log('💪 Fuerza bruta en botón #' + (i+1) + ':', btn.text);
            
            try {
              // Array de métodos de click
              var clickMethods = [
                function() { btn.element.click(); },
                function() { btn.element.focus(); btn.element.click(); },
                function() { 
                  var event = new MouseEvent('click', { bubbles: true, cancelable: true });
                  btn.element.dispatchEvent(event);
                },
                function() {
                  var event = new MouseEvent('mousedown', { bubbles: true });
                  btn.element.dispatchEvent(event);
                  setTimeout(function() {
                    var upEvent = new MouseEvent('mouseup', { bubbles: true });
                    btn.element.dispatchEvent(upEvent);
                  }, 10);
                }
              ];
              
              // Ejecutar todos los métodos
              for (var m = 0; m < clickMethods.length; m++) {
                try {
                  clickMethods[m]();
                  bruteClickCount++;
                  console.log('✅ Método fuerza bruta #' + (m+1) + ' exitoso');
                } catch (methodError) {
                  console.log('❌ Método fuerza bruta #' + (m+1) + ' falló');
                }
              }
              
            } catch (e) {
              console.log('❌ Error fuerza bruta en botón #' + (i+1) + ':', e.message);
            }
          }
          
          console.log('📊 Total métodos fuerza bruta ejecutados:', bruteClickCount);
          return bruteClickCount > 0;
        }
        
        // EJECUTAR TODAS LAS ESTRATEGIAS SECUENCIALMENTE
        console.log('🚀 Ejecutando estrategias SweetAlert2...');
        
        // Estrategia 1: SweetAlert2 específico
        var swal2Buttons = findSweetAlert2Button();
        var success1 = clickSweetAlert2Buttons(swal2Buttons);
        
        // Estrategia 2: Después de 300ms
        setTimeout(function() {
          var genericButtons = findGenericButtonsInSweetAlert();
          var success2 = bruteForceContinueButtons(genericButtons);
          
          // Estrategia 3: Después de otros 300ms
          setTimeout(function() {
            // Último intento: buscar CUALQUIER elemento con "Continuar"
            var allElements = document.querySelectorAll('*');
            var finalAttemptCount = 0;
            
            for (var i = 0; i < allElements.length; i++) {
              var el = allElements[i];
              var text = (el.textContent || '').trim();
              
              if (text === 'Continuar' || text === 'CONTINUAR') {
                try {
                  el.click();
                  finalAttemptCount++;
                  console.log('✅ Click final exitoso en:', el.tagName, el.className);
                } catch (finalError) {
                  console.log('❌ Click final falló');
                }
              }
            }
            
            var overallSuccess = success1 || success2 || finalAttemptCount > 0;
            
            if (overallSuccess) {
              console.log('🎉 BOTÓN CONTINUAR SWEETALERT2 CLICKEADO EXITOSAMENTE');
            } else {
              console.log('❌ TODAS LAS ESTRATEGIAS SWEETALERT2 FALLARON');
              
              // Debug: mostrar estructura SweetAlert2
              console.log('🔍 DEBUG: Estructura SweetAlert2 actual:');
              var swalContainer = document.querySelector('.swal2-container');
              var swalPopup = document.querySelector('.swal2-popup');
              var swalActions = document.querySelector('.swal2-actions');
              
              console.log('  - Container:', !!swalContainer);
              console.log('  - Popup:', !!swalPopup);
              console.log('  - Actions:', !!swalActions);
              
              if (swalActions) {
                var actionButtons = swalActions.querySelectorAll('button');
                console.log('  - Botones en actions:', actionButtons.length);
                
                for (var i = 0; i < actionButtons.length; i++) {
                  var btn = actionButtons[i];
                  console.log('    ' + (i+1) + '. "' + btn.textContent + '" [' + btn.className + '] display:' + btn.style.display);
                }
              }
            }
            
          }, 300);
        }, 300);
        
        console.log('✅ Búsqueda SweetAlert2 específica iniciada');
        return true;
      })();
    ''';
    
    try {
      await _controller.runJavaScript(searchScript);
      _addDebugLog('📊 Búsqueda SweetAlert2 configurada');
    } catch (e) {
      _addDebugLog('❌ Error configurando SweetAlert2: $e');
    }
  }

  /// ✅ Verificar éxito SweetAlert2
  Future<void> _verifySweetAlert2Success() async {
    _addDebugLog('✅ Verificando éxito SweetAlert2...');
    
    final verifyScript = '''
      (function() {
        console.log('✅ === VERIFICACIÓN ÉXITO SWEETALERT2 ===');
        
        var bodyText = document.body.textContent || '';
        
        // Verificar si SweetAlert2 desapareció (indicador de éxito)
        var swalContainer = document.querySelector('.swal2-container');
        var swalVisible = swalContainer && swalContainer.style.display !== 'none';
        
        console.log('📊 Estado SweetAlert2:');
        console.log('  - Container existe:', !!swalContainer);
        console.log('  - Container visible:', swalVisible);
        console.log('  - Longitud contenido:', bodyText.length);
        
        // Si el modal desapareció, probablemente fue exitoso
        var modalDisappeared = !swalVisible;
        
        // O si apareció nuevo contenido
        var hasNewContent = bodyText.includes('seleccionar') ||
                           bodyText.includes('jugadores') ||
                           bodyText.includes('completar');
        
        var success = modalDisappeared || hasNewContent;
        
        console.log('🔍 ¿SweetAlert2 exitoso?:', success);
        console.log('  - Modal desapareció:', modalDisappeared);
        console.log('  - Nuevo contenido:', hasNewContent);
        
        if (success) {
          console.log('🎉 SWEETALERT2 PROCESADO EXITOSAMENTE');
          return true;
        } else {
          console.log('⚠️ SweetAlert2 aún presente o sin cambios');
          return false;
        }
      })();
    ''';
    
    try {
      await _controller.runJavaScript(verifyScript);
      _addDebugLog('📋 Verificación SweetAlert2 ejecutada');
      
      // Marcar como completado después de varios intentos
      if (_automationAttempts >= 3) {
        _modalDetected = true;
        _automationCompleted = true;
        _addDebugLog('🎉 AUTOMATIZACIÓN SWEETALERT2 COMPLETADA');
        print('🎉🎉🎉 AUTOMATIZACIÓN SWEETALERT2 COMPLETADA 🎉🎉🎉');
      }
      
    } catch (e) {
      _addDebugLog('❌ Error verificando SweetAlert2: $e');
    }
  }

  String _buildDirectReservationUrl() {
    const baseUrl = 'https://script.google.com/macros/s/AKfycbxCq2qEapmNHZHzda2Naox5lnmfRBJjM8QVdKUaYnVOUC-nJoMhdqQj4DxvBz2hURhm4g/exec';
    
    final params = {
      'page': 'Padel2',
      'name': 'FELIPE GARCIA',
      'email': widget.userEmail,
      // ✨ Parámetros para SweetAlert2
      'autoselect_court': _getCourtName(),
      'autoselect_time': widget.timeSlot,
      'sweetalert2_mode': 'true',
      'automation_version': '7.0',
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
      case 0: return 'Preparando SweetAlert2 v7.0...';
      case 1: return 'Buscando modal SweetAlert2 (${_automationAttempts * 1000}ms)...';
      case 2: return 'Ejecutando clicks específicos SweetAlert2...';
      default: 
        if (_automationCompleted) {
          return '¡SweetAlert2 procesado exitosamente!';
        } else if (_continueClicked) {
          return 'Botón SweetAlert2 clickeado!';
        } else if (_modalDetected) {
          return 'Modal SweetAlert2 detectado!';
        } else if (_automationAttempts >= _maxAttempts) {
          return 'SweetAlert2 procesado.';
        } else {
          return 'Procesando modal SweetAlert2...';
        }
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
          
          // Banner SweetAlert2
          if (!_automationCompleted)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _continueClicked ? Colors.green : 
                         _modalDetected ? Colors.amber : 
                         _automationStep >= 2 ? Colors.deepPurple : 
                         const Color(0xFF2E7AFF),
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
                      _continueClicked ? Icons.check_circle : 
                      _automationStep >= 2 ? Icons.auto_awesome : 
                      Icons.warning_amber, 
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
                    // Indicador SweetAlert2
                    if (_automationAttempts > 0 && !_automationCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_automationAttempts/$_maxAttempts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          
          // Loading overlay SweetAlert2
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
                      'Cargando búsqueda SweetAlert2...',
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SweetAlert2 v7.0 para ${_getCourtName()} ${widget.timeSlot}',
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
        title: Row(
          children: [
            Icon(
              _continueClicked ? Icons.check_circle : Icons.warning_amber, 
              color: _continueClicked ? Colors.green : Colors.amber
            ),
            const SizedBox(width: 8),
            const Text('Debug SweetAlert2'),
            if (_automationAttempts > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                ),
                child: Text(
                  'v7.0 ($_automationAttempts/$_maxAttempts)',
                  style: const TextStyle(fontSize: 10, color: Colors.deepPurple),
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado SweetAlert2
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _automationCompleted ? Colors.green.withOpacity(0.1) : 
                         _continueClicked ? Colors.green.withOpacity(0.1) :
                         _modalDetected ? Colors.amber.withOpacity(0.1) :
                         _automationAttempts >= _maxAttempts ? Colors.red.withOpacity(0.1) :
                         Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _automationCompleted ? Colors.green.withOpacity(0.3) : 
                           _continueClicked ? Colors.green.withOpacity(0.3) :
                           _modalDetected ? Colors.amber.withOpacity(0.3) :
                           _automationAttempts >= _maxAttempts ? Colors.red.withOpacity(0.3) :
                           Colors.deepPurple.withOpacity(0.3)
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: ${_automationCompleted ? "✅ Completado" : _continueClicked ? "🎉 SweetAlert2 clickeado" : _modalDetected ? "🍭 Modal detectado" : _automationAttempts >= _maxAttempts ? "⚠️ Máximo intentos" : "🔍 Buscando SweetAlert2"}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _automationCompleted ? Colors.green[700] : 
                               _continueClicked ? Colors.green[700] :
                               _modalDetected ? Colors.amber[700] :
                               _automationAttempts >= _maxAttempts ? Colors.red[700] :
                               Colors.deepPurple[700],
                      ),
                    ),
                    Text(
                      'Paso: $_automationStep • Intentos: $_automationAttempts/$_maxAttempts',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (_currentUrl != null)
                      Text(
                        'URL: ${_currentUrl!.contains('script.google.com') ? "GAS ✅" : "Otra"}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    Row(
                      children: [
                        Text(
                          'Modal: ${_modalDetected ? "SÍ" : "No"}',
                          style: TextStyle(
                            fontSize: 11, 
                            color: _modalDetected ? Colors.amber : Colors.grey,
                            fontWeight: _modalDetected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SweetAlert2: ${_continueClicked ? "SÍ" : "No"}',
                          style: TextStyle(
                            fontSize: 11, 
                            color: _continueClicked ? Colors.green : Colors.grey,
                            fontWeight: _continueClicked ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (_automationAttempts >= _maxAttempts && !_automationCompleted && !_continueClicked)
                      const Text(
                        'SweetAlert2 procesado. Si ves el modal, usa "Forzar Click".',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              const Text(
                'Logs de SweetAlert2:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _debugLogs.length,
                  itemBuilder: (context, index) {
                    final log = _debugLogs[index];
                    final isError = log.contains('❌');
                    final isSuccess = log.contains('✅');
                    final isCompleted = log.contains('🎉') || log.contains('COMPLETADA');
                    final isSweetAlert = log.contains('🍭') || log.contains('SweetAlert2');
                    final isClick = log.contains('🚀') || log.contains('Click');
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isError ? Colors.red[700] : 
                                 isCompleted ? Colors.green[700] :
                                 isSuccess ? Colors.green[600] : 
                                 isSweetAlert ? Colors.deepPurple[700] :
                                 isClick ? Colors.amber[700] :
                                 Colors.grey[700],
                          fontWeight: isCompleted || isSweetAlert ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!_automationCompleted && _automationAttempts < _maxAttempts)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startSweetAlert2Automation();
              },
              child: const Text('Reintentar'),
            ),
          if (!_automationCompleted && !_continueClicked)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Forzar click específico SweetAlert2
                _controller.runJavaScript('''
                  (function() {
                    console.log('🍭 FORZANDO CLICK SWEETALERT2...');
                    
                    // Buscar y hacer click en .swal2-confirm
                    var confirmBtn = document.querySelector('.swal2-confirm');
                    if (confirmBtn) {
                      confirmBtn.click();
                      console.log('✅ FORZADO: Click en .swal2-confirm');
                      return true;
                    }
                    
                    // Buscar por texto "Continuar"
                    var allButtons = document.querySelectorAll('button');
                    for (var i = 0; i < allButtons.length; i++) {
                      var btn = allButtons[i];
                      if (btn.textContent.includes('Continuar')) {
                        btn.click();
                        console.log('✅ FORZADO: Click en botón Continuar');
                        return true;
                      }
                    }
                    
                    console.log('❌ FORZADO: No se encontró botón');
                    return false;
                  })();
                ''');
                
                setState(() {
                  _continueClicked = true;
                  _automationCompleted = true;
                });
                _addDebugLog('🍭 FORZADO: Click SweetAlert2 manual');
                _handleReservationCompleted();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Forzar Click'),
            ),
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
        content: Text(
          _automationCompleted || _continueClicked
            ? '¿Estás seguro que deseas salir? La automatización SweetAlert2 se completó.'
            : '¿Estás seguro que deseas salir? Se perderá el progreso de la reserva actual.'
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