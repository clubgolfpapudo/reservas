// lib/presentation/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/booking/time_slot_block.dart';
import '../../widgets/booking/court_tab_button.dart';
import '../../widgets/booking/date_selector.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/user_selector_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Pantalla principal que muestra las reservas por día y cancha
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Inicializar datos cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... tu AppBar actual (no cambiar) ...
      
      body: Column(
        children: [
          // 🔥 NUEVO: Selector de usuario
          UserSelectorWidget(
            onUserChanged: () {
              setState(() {
                print('✅ Usuario cambiado, refrescando...');
              });
            },
          ),
          
          // 🔥 TU CONTENIDO ACTUAL (envolver en Expanded)
          Expanded(
            child: /* AQUÍ VA TODO TU CÓDIGO ACTUAL DEL BODY */
            // No cambies nada de tu código actual, solo envuélvelo en Expanded
          ),
        ],
      ),
    );
  }

  /// Construye el header con título y bienvenida
  Widget _buildHeader(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título principal
          Row(
            children: [
              Text(
                'Reservas ',
                style: AppTextStyles.headline1.copyWith(
                  color: AppColors.darkGray,
                ),
              ),
              Icon(
                Icons.sports_tennis,
                size: AppSizes.iconXL,
                color: AppColors.primaryBlue,
              ),
              Expanded(
                child: Consumer<BookingProvider>(
                  builder: (context, provider, child) {
                    final selectedDate = provider.selectedDate;
                    return Text(
                      ' ${selectedDate.day} de ${_getMonthName(selectedDate.month)}',
                      style: AppTextStyles.headline1.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.spacingS),
          
          // Saludo personalizado
          if (userProvider.isAuthenticated) ...[
            Text(
              '${userProvider.welcomeMessage}, ${userProvider.displayName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            
            // Mostrar warnings si existen
            if (userProvider.userWarnings.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingXS),
              ...userProvider.userWarnings.map(
                (warning) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingS,
                    vertical: AppSizes.spacingXS,
                  ),
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingXS),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    border: Border.all(
                      color: AppColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: AppSizes.iconS,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSizes.spacingXS),
                      Expanded(
                        child: Text(
                          warning,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Construye el selector de fecha horizontal
  Widget _buildDateSelector(BookingProvider bookingProvider) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
      child: DateSelector(
        selectedDate: bookingProvider.selectedDate,
        availableDates: bookingProvider.availableDates,
        onDateSelected: (date) {
          bookingProvider.selectDate(date);
        },
      ),
    );
  }

  /// Construye el selector de canchas
  Widget _buildCourtSelector(BookingProvider bookingProvider) {
    if (bookingProvider.courts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: bookingProvider.courts.map((court) {
          final isSelected = court.id == bookingProvider.selectedCourtId;
          
          return CourtTabButton(
            court: court.name,
            isSelected: isSelected,
            onTap: () {
              bookingProvider.selectCourt(court.id);
            },
          );
        }).toList(),
      ),
    );
  }

  /// Construye la lista de horarios disponibles
  Widget _buildTimeSlotsList(
    BookingProvider bookingProvider, 
    UserProvider userProvider
  ) {
    if (bookingProvider.isLoading) {
      return const AppLoadingIndicator(
        message: 'Cargando horarios...',
      );
    }

    if (bookingProvider.errorMessage != null) {
      return _buildErrorWidget(bookingProvider.errorMessage!);
    }

    if (bookingProvider.courts.isEmpty) {
      return _buildEmptyState('No hay canchas disponibles');
    }

    return RefreshIndicator(
      onRefresh: () => bookingProvider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        // 🔥 USAR HORARIOS DINÁMICOS según la fecha seleccionada
        itemCount: AppConstants.getAllTimeSlots(bookingProvider.selectedDate).length,
        itemBuilder: (context, index) {
          final availableTimeSlots = AppConstants.getAllTimeSlots(bookingProvider.selectedDate);
          final timeSlot = availableTimeSlots[index];
          final booking = bookingProvider.getBookingForTimeSlot(timeSlot);
          final status = bookingProvider.getTimeSlotStatus(timeSlot);
          
          // Verificar si el usuario puede usar este horario
          final canUserUseThisTime = userProvider.isTimeSlotAllowed(timeSlot);
          
          return TimeSlotBlock(
            time: timeSlot,
            status: status,
            players: booking?.players.map((p) => p.name).toList() ?? [],
            isUserAllowed: canUserUseThisTime,
            userRole: userProvider.currentUser?.role,
            onReservePressed: status == TimeSlotStatus.available && canUserUseThisTime
                ? () => _handleReservePressed(bookingProvider, timeSlot)
                : null,
          );
        },
      ),
    );
  }

  /// Construye widget de error
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconXXL,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            'Error',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingL),
            child: Text(
              error,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          ElevatedButton(
            onPressed: () {
              context.read<BookingProvider>().refresh();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Construye estado vacío
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: AppSizes.iconXXL,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            message,
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  /// Maneja cuando se presiona el botón de reservar
  void _handleReservePressed(BookingProvider bookingProvider, String timeSlot) {
    bookingProvider.startBookingProcess(timeSlot);
    
    // En una implementación completa, aquí navegaríamos al WebView
    // Por ahora mostramos un snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Iniciando reserva para ${bookingProvider.selectedCourtName} '
          'el ${bookingProvider.getFormattedDateName(bookingProvider.selectedDate)} '
          'a las $timeSlot',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Obtiene el nombre del mes
  String _getMonthName(int month) {
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return months[month];
  }
}