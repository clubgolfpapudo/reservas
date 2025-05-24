// lib/presentation/widgets/booking/time_slot_block.dart
import 'package:flutter/material.dart';
import '../../providers/booking_provider.dart';
import '../../../domain/entities/user.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Widget que representa un bloque de horario con su estado
class TimeSlotBlock extends StatefulWidget {
  final String time;
  final TimeSlotStatus status;
  final List<String> players;
  final bool isUserAllowed;
  final UserRole? userRole;
  final VoidCallback? onReservePressed;
  final VoidCallback? onTap;

  const TimeSlotBlock({
    Key? key,
    required this.time,
    required this.status,
    this.players = const [],
    this.isUserAllowed = true,
    this.userRole,
    this.onReservePressed,
    this.onTap,
  }) : super(key: key);

  @override
  State<TimeSlotBlock> createState() => _TimeSlotBlockState();
}

class _TimeSlotBlockState extends State<TimeSlotBlock>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.standard,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    if (widget.status == TimeSlotStatus.available) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _toggleExpansion,
      child: AnimatedContainer(
        duration: AppAnimations.medium,
        curve: AppAnimations.standard,
        margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: _isExpanded ? AppSizes.spacingL : AppSizes.spacingM,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: _getBorderColor(),
            width: 1.0,
          ),
          boxShadow: AppShadows.light,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primera fila: Hora y estado/botón
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hora
                Text(
                  widget.time,
                  style: AppTextStyles.timeSlotTime.copyWith(
                    color: _getTextColor(),
                  ),
                ),

                // Estado o botón de reservar
                _buildActionWidget(),
              ],
            ),

            // Restricción de usuario (si aplica)
            if (!widget.isUserAllowed && widget.status == TimeSlotStatus.available)
              _buildRestrictionMessage(),

            // Segunda fila: Jugadores (expandible)
            if (widget.players.isNotEmpty) _buildPlayersSection(),
          ],
        ),
      ),
    );
  }

  /// Construye el widget de acción (botón o estado)
  Widget _buildActionWidget() {
    if (widget.status == TimeSlotStatus.available) {
      if (!widget.isUserAllowed) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingS,
            vertical: AppSizes.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.mediumGray.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Text(
            'RESTRINGIDO',
            style: AppTextStyles.timeSlotStatus.copyWith(
              fontSize: 16,
              color: AppColors.mediumGray,
            ),
          ),
        );
      }

      return ElevatedButton(
        onPressed: widget.onReservePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingM,
            vertical: AppSizes.spacingS,
          ),
        ),
        child: Text(
          'RESERVAR',
          style: AppTextStyles.buttonText.copyWith(
            fontSize: 16,
          ),
        ),
      );
    }

    return Text(
      widget.status.statusText,
      style: AppTextStyles.timeSlotStatus.copyWith(
        color: _getTextColor(),
      ),
    );
  }

  /// Construye el mensaje de restricción
  Widget _buildRestrictionMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spacingS),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppSizes.iconS,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSizes.spacingXS),
          Expanded(
            child: Text(
              _getRestrictionMessage(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de jugadores
  Widget _buildPlayersSection() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jugadores:',
              style: AppTextStyles.bodySmall.copyWith(
                color: _getTextColor().withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXS),
            Text(
              widget.players.join(' • '),
              style: AppTextStyles.timeSlotPlayers.copyWith(
                color: _getTextColor(),
              ),
            ),
            if (widget.status == TimeSlotStatus.incomplete) ...[
              const SizedBox(height: AppSizes.spacingXS),
              Text(
                'Faltan ${4 - widget.players.length} jugadores',
                style: AppTextStyles.caption.copyWith(
                  color: _getTextColor().withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Obtiene el color de fondo según el estado
  Color _getBackgroundColor() {
    return widget.status.backgroundColor;
  }

  /// Obtiene el color del borde según el estado
  Color _getBorderColor() {
    switch (widget.status) {
      case TimeSlotStatus.available:
        return AppColors.availableBorder;
      case TimeSlotStatus.reserved:
        return AppColors.reservedBorder;
      case TimeSlotStatus.incomplete:
        return AppColors.incompleteBorder;
    }
  }

  /// Obtiene el color del texto según el estado
  Color _getTextColor() {
    return widget.status.textColor;
  }

  /// Obtiene el mensaje de restricción según el rol del usuario
  String _getRestrictionMessage() {
    if (widget.userRole == null) return 'No disponible para tu categoría';

    switch (widget.userRole!) {
      case UserRole.visita:
        return 'Horario restringido para visitas';
      case UserRole.filial:
        return 'Horario restringido para filial';
      default:
        return 'Horario no disponible';
    }
  }
}