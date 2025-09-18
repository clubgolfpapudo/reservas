// lib/presentation/widgets/booking/compact_court_tabs.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class CompactCourtTabs extends StatelessWidget {
  final String selectedCourt;
  final Function(String) onCourtSelected;

  const CompactCourtTabs({
    Key? key,
    required this.selectedCourt,
    required this.onCourtSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final courts = ['PITE', 'LILEN', 'PLAIYA'];

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: courts.map((court) {
          final isSelected = selectedCourt == court;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onCourtSelected(court),
              child: AnimatedContainer(
                duration: AppConstants.fastAnimationDuration,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF2E7AFF).withOpacity(0.3) 
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    court,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected 
                          ? const Color(0xFF2E7AFF)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}