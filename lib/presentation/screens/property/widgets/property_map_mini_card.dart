import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/screens/property/providers/saved_properties_provider.dart';

class PropertyMapMiniCard extends ConsumerWidget {
  final PropertyModel property;
  final bool isSelected;
  final VoidCallback onTap;

  const PropertyMapMiniCard({
    super.key,
    required this.property,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedPropertiesProvider);
    final isSaved = savedIds.contains(property.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.18 : 0.10),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (top 60%)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    property.thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: property.thumbnail,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(color: Colors.grey[300]),
                    // Favorite heart
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(savedPropertiesProvider.notifier)
                            .toggle(property.id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${property.price.toStringAsFixed(0)}/mo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.bed, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(
                        '${property.bedroom}',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.bathroom, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(
                        '${property.bathroom}',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
