import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_sections_viewmodel.dart';

class HomePropertiesCategory extends ConsumerWidget {
  const HomePropertiesCategory({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'icon': Icons.home, 'label': 'Home', 'type': 'house'},
    {'icon': Icons.meeting_room_outlined, 'label': 'Room', 'type': 'room'},
    {'icon': Icons.villa, 'label': 'Condo', 'type': 'condo'},
    {'icon': Icons.apartment_outlined, 'label': 'Apartment', 'type': 'apartment'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedHomeCategoryProvider);

    final isAllSelected = selectedType.isEmpty;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" button
          GestureDetector(
            onTap: () => ref.read(selectedHomeCategoryProvider.notifier).update(''),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              decoration: BoxDecoration(
                color: isAllSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isAllSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  'All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isAllSelected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          // Category buttons
          ..._categories.map((category) {
            final type = category['type'] as String;
            final isSelected = selectedType == type;

            return GestureDetector(
              onTap: () => ref.read(selectedHomeCategoryProvider.notifier).update(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 20,
                      color: isSelected ? AppColors.white : AppColors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
