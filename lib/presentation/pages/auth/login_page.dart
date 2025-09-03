// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../../core/theme/corporate_theme.dart';
import '../../../core/constants/app_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
  }

  Future<void> _launchRegistrationForm() async {
    final Uri url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSfTWfH6tgPk9orGb8CUmAqHdtBFCRq-nlJLyJA2XVDr7OmCew/viewform?usp=sf_link');
    if (!await launchUrl(url)) {
      print('No se pudo abrir el enlace de registro');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente corporativo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CorporateTheme.backgroundLight,
                  Color(0xFFF0F2F5),
                ],
              ),
            ),
          ),
          
          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // ← Agregar esta línea
                        children: [
                          const SizedBox(height: 60),
                          
                          // Logo del Club de Golf Papudo
                          _buildClubLogo(),
                          
                          const SizedBox(height: 40),
                          
                          // Título y subtítulo
                          _buildHeader(),
                          
                          const SizedBox(height: 50),
                          
                          // Formulario de login
                          _buildLoginForm(),
                          
                          const SizedBox(height: 30),
                          
                          // Información adicional
                          _buildFooterInfo(),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildClubLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: CorporateTheme.elevatedShadow,
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/club_logo.png', // Logo oficial del club
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback temporal con colores corporativos
              return Container(
                decoration: const BoxDecoration(
                  gradient: CorporateTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.golf_course,
                  size: 60,
                  color: CorporateTheme.goldAccent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Título principal
        // Text(
          // AppConstants.clubName.toUpperCase(),
          // style: const TextStyle(
          //   fontSize: 28,
          //   fontWeight: FontWeight.bold,
          //   color: CorporateTheme.primaryNavyBlue,
          //   letterSpacing: 1.2,
          // ),
          // textAlign: TextAlign.center,
        // ),
        
        const SizedBox(height: 8),
        
        // Año de fundación
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: CorporateTheme.goldAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CorporateTheme.goldAccent.withOpacity(0.3),
            ),
          ),
          child: Text(
            'FUNDADO EN ${AppConstants.clubYear}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CorporateTheme.primaryNavyBlue,
              letterSpacing: 0.8,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Subtítulo
        Text(
          AppConstants.systemTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: CorporateTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CorporateTheme.corporateShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono de usuario
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                gradient: CorporateTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título del formulario
            const Text(
              'Ingresa tu email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CorporateTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Campo de email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'ejemplo@clubgolfpapudo.cl',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: CorporateTheme.primaryNavyBlue,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: CorporateTheme.primaryNavyBlue,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Por favor ingresa un email válido';
                }
                return null;
              },
              onChanged: (value) => setState(() {}),
            ),
            
            const SizedBox(height: 32),
            
            // Botón de validar usuario
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: CorporateTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: CorporateTheme.corporateShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _emailController.text.isNotEmpty && !_isLoading
                          ? () => _validateUser(authProvider)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Validar Usuario',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),

            // Texto con link de registro (versión simplificada para test)
            const Text(
              'Si tu correo no está registrado, regístralo aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Column(
      children: [
        // Separador decorativo
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      CorporateTheme.primaryNavyBlue.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Información del sistema
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CorporateTheme.goldAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CorporateTheme.goldAccent.withOpacity(0.2),
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.info_outline,
                color: CorporateTheme.primaryNavyBlue,
                size: 24,
              ),
              
              SizedBox(height: 12),
              
              Text(
                'Sistema de Reservas Multi-Deporte',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CorporateTheme.primaryNavyBlue,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8),
              
              Text(
                '🏌️ Golf • 🎾 Tenis • 🏓 Pádel',
                style: TextStyle(
                  fontSize: 13,
                  color: CorporateTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 12),
              
              Text(
                'Ingrese con el email registrado en el Club para acceder a las reservas.',
                style: TextStyle(
                  fontSize: 12,
                  color: CorporateTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Copyright
        Text(
          '© ${DateTime.now().year} ${AppConstants.clubName}',
          style: const TextStyle(
            fontSize: 11,
            color: CorporateTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _validateUser(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await authProvider.signInWithEmail(_emailController.text.trim());
      
      if (success && mounted) {
        // Navegación exitosa manejada por AuthProvider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('¡Bienvenido a ${AppConstants.clubName}!'),
              ],
            ),
            backgroundColor: CorporateTheme.greenGolf,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Email no encontrado. Verifique que esté registrado en el sistema.',
                  ),
                ),
              ],
            ),
            backgroundColor: CorporateTheme.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}