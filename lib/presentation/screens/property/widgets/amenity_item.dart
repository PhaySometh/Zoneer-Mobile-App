import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';

class AmenityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AmenityItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary,),
            const SizedBox(width: 4),
            Text(value),
          ],
        ),
      ],
    );
  }
}
