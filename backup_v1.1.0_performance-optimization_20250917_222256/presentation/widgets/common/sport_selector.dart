// lib/presentation/widgets/common/sport_selector.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class SportSelector extends StatelessWidget {
  final String? selectedSport;
  final Function(String) onSportSelected;
  final bool showAsCards;
  final bool compact;

  const SportSelector({
    super.key,
    this.selectedSport,
    required this.onSportSelected,
    this.showAsCards = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector(context);
    } else if (showAsCards) {
      return _buildCardSelector(context);
    } else {
      return _buildTabSelector(context);
    }
  }

  Widget _buildCompactSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: _getSportOptions().map((sport) {
          final isSelected = selectedSport == sport['id'];
          return Expanded(
            child: _buildCompactTab(context, sport, isSelected),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Selecciona el deporte',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Color(AppConstants.corporateNavyBlue),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Tarjetas de deportes
          Column(
            children: _getSportOptions().map((sport) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSportCard(context, sport),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: _getSportOptions().map((sport) {
            final isSelected = selectedSport == sport['id'];
            return Expanded(
              child: _buildSportTab(context, sport, isSelected),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCompactTab(BuildContext context, Map<String, dynamic> sport, bool isSelected) {
    final colorPrimary = Color(sport['primaryColor'] as int);
    
    return GestureDetector(
      onTap: () => onSportSelected(sport['id'] as String),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sport['icon'] as IconData,
              size: 16,
              color: isSelected ? Colors.white : colorPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              sport['name'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportCard(BuildContext context, Map<String, dynamic> sport) {
    final isSelected = selectedSport == sport['id'];
    final colorPrimary = Color(sport['primaryColor'] as int);
    final colorSecondary = Color(sport['secondaryColor'] as int);
    
    return GestureDetector(
      onTap: () => onSportSelected(sport['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorPrimary, colorSecondary],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : colorPrimary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorPrimary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icono del deporte
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : colorPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                sport['icon'] as IconData,
                size: 32,
                color: isSelected ? Colors.white : colorPrimary,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Información del deporte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sport['name'] as String,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Color(AppConstants.corporateNavyBlue),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    sport['description'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Indicador de canchas disponibles
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.8)
                            : colorPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sport['courts']} canchas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? Colors.white.withOpacity(0.8)
                              : colorPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Indicador de selección
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: colorPrimary.withOpacity(0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportTab(BuildContext context, Map<String, dynamic> sport, bool isSelected) {
    final colorPrimary = Color(sport['primaryColor'] as int);
    
    return GestureDetector(
      onTap: () => onSportSelected(sport['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorPrimary, Color(sport['secondaryColor'] as int)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sport['icon'] as IconData,
              size: 24,
              color: isSelected ? Colors.white : colorPrimary,
            ),
            
            const SizedBox(height: 6),
            
            Text(
              sport['name'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colorPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSportOptions() {
    final deportes = [
      {'name': 'Golf'},
      {'name': 'Pádel'},
      {'name': 'Tenis'},
    ];
    print('🔶🔶🔶 ORDEN ACTUAL 🔶🔶🔶');
    print('➡️ ${deportes.map((d) => d['name']).join(' → ')}');

    return deportes;
  }

  // List<Map<String, dynamic>> _getSportOptions() {
  //   return [
  //     {
  //       'id': 'golf',
  //       'name': 'Golf',
  //       'icon': Icons.golf_course,
  //       'description': 'Campo de golf completo',
  //       'courts': '2',
  //       'primaryColor': AppConstants.golfPrimary,
  //       'secondaryColor': AppConstants.golfSecondary,
  //     },
  //     {
  //       'id': 'padel',
  //       'name': 'Pádel',
  //       'icon': Icons.sports_handball,
  //       'description': 'Canchas profesionales',
  //       'courts': '3',
  //       'primaryColor': AppConstants.padelPrimary,
  //       'secondaryColor': AppConstants.padelSecondary,
  //     },
  //     {
  //       'id': 'tenis',
  //       'name': 'Tenis',
  //       'icon': Icons.sports_tennis,
  //       'description': 'Canchas de tierra batida',
  //       'courts': '4',
  //       'primaryColor': AppConstants.tennisPrimary,
  //       'secondaryColor': AppConstants.tennisSecondary,
  //     },
  //   ];
  // }
}

// Widget para mostrar estadísticas rápidas por deporte
class SportStats extends StatelessWidget {
  final String sportId;
  final int totalBookings;
  final int availableSlots;
  final DateTime date;

  const SportStats({
    super.key,
    required this.sportId,
    required this.totalBookings,
    required this.availableSlots,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final sport = _getSportInfo(sportId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(sport['primaryColor'] as int).withOpacity(0.1),
            Color(sport['secondaryColor'] as int).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(sport['primaryColor'] as int).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sport['icon'] as IconData,
                color: Color(sport['primaryColor'] as int),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                sport['name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(sport['primaryColor'] as int),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Reservas', totalBookings.toString()),
              _buildStatItem('Disponibles', availableSlots.toString()),
              _buildStatItem('Ocupación', '${_getOccupancyPercentage()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.corporateNavyBlue),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getSportInfo(String sportId) {
    final sports = {
      'golf': {
        'name': 'Golf',
        'icon': Icons.golf_course,
        'primaryColor': AppConstants.golfPrimary,
        'secondaryColor': AppConstants.golfSecondary,
      },
      'padel': {
        'name': 'Pádel',
        'icon': Icons.sports_handball,
        'primaryColor': AppConstants.padelPrimary,
        'secondaryColor': AppConstants.padelSecondary,
      },
      'tenis': {
        'name': 'Tenis',
        'icon': Icons.sports_tennis,
        'primaryColor': AppConstants.tennisPrimary,
        'secondaryColor': AppConstants.tennisSecondary,
      },
    };
    
    return sports[sportId] ?? sports['golf']!;
  }

  int _getOccupancyPercentage() {
    final total = totalBookings + availableSlots;
    if (total == 0) return 0;
    return ((totalBookings / total) * 100).round();
  }
}

// Widget simple para navegación rápida entre deportes
class QuickSportNavigation extends StatelessWidget {
  final String currentSport;
  final Function(String) onSportChanged;

  const QuickSportNavigation({
    super.key,
    required this.currentSport,
    required this.onSportChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SportSelector(
      selectedSport: currentSport,
      onSportSelected: onSportChanged,
      compact: true,
    );
  }
}