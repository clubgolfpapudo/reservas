// lib/presentation/widgets/common/compact_header.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class CompactHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBackPressed;
  final VoidCallback? onAddPressed;

  const CompactHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.onBackPressed,
    this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2E7AFF),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Botón back y textos
            Expanded(
              child: Row(
                children: [
                  if (onBackPressed != null) ...[
                    GestureDetector(
                      onTap: onBackPressed,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón add
            if (onAddPressed != null)
              GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}