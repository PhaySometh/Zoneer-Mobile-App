import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';

/// Vertical column of circular FABs on the right side of the map.
class PropertyMapControls extends StatelessWidget {
  final VoidCallback onMyLocation;

  const PropertyMapControls({
    super.key,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlFab(
          heroTag: 'myLocation',
          icon: Icons.my_location,
          onPressed: onMyLocation,
        ),
      ],
    );
  }
}

class _ControlFab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlFab({
    required this.heroTag,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}
