import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/core/utils/app_decoration.dart';
import 'package:zoneer_mobile/data/models/user/user_model.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback? onMyProperties;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.onEdit,
    this.onMyProperties,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: (user.profileUrl != null && user.profileUrl!.isNotEmpty)
                ? NetworkImage(user.profileUrl!)
                : null,
            backgroundColor: const Color(0xFFE9E9E9),
            child: (user.profileUrl == null || user.profileUrl!.isEmpty)
                ? const Icon(Icons.person, size: 48, color: Colors.grey)
                : null,
          ),

          const SizedBox(height: 12),
          Text(
            user.fullname,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text("View Profile"),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primary
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,

                  ),
                  
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onMyProperties,
                icon: const Icon(Icons.apartment_outlined, size: 16),
                label: const Text("My Properties"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
