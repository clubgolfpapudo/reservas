// lib/presentation/widgets/court_tab_button.dart
import 'package:flutter/material.dart';

class CourtTabButton extends StatelessWidget {
  final String court;
  final bool isSelected;
  final VoidCallback onTap;
  
  const CourtTabButton({
    Key? key,
    required this.court,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
            width: 2.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Text(
          court,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected 
                ? Colors.red.shade600  // Color rojo para texto seleccionado según el diseño
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}