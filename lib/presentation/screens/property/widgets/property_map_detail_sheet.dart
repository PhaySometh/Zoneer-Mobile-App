import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/property/enums/property_status.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/media_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/fullscreen_image_viewer.dart';

/// Full property card shown in the bottom sheet when a marker is tapped.
/// Photo grid · title · price + badge · location · amenity chips · description · CTA.
class PropertyMapDetailSheet extends ConsumerWidget {
  final PropertyModel selectedProperty;

  // Kept for API compatibility.
  final List<PropertyModel> allProperties;
  final void Function(PropertyModel) onPropertySelected;

  const PropertyMapDetailSheet({
    super.key,
    required this.selectedProperty,
    required this.allProperties,
    required this.onPropertySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = selectedProperty;
    final isRented = p.propertyStatus == PropertyStatus.rented;

    // Async fetch of additional media; show thumbnail-only grid while loading.
    final mediaAsync = ref.watch(mediaViewmodelProvider(p.id));
    final List<String> images = [
      if (p.thumbnail.isNotEmpty) p.thumbnail,
      ...mediaAsync.whenOrNull(
            data: (list) => list.map((m) => m.url).where((u) => u.isNotEmpty),
          ) ??
          <String>[],
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Photo grid ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: images.isNotEmpty
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                              images: images,
                              initialIndex: 0,
                            ),
                          ),
                        )
                    : null,
                child: SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      // Large image — left 60%
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: SizedBox(
                            height: double.infinity,
                            child: _buildImage(
                                images.isNotEmpty ? images[0] : ''),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Two stacked images — right 40%
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            // Top-right slot
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: _buildImage(
                                    images.length > 1
                                        ? images[1]
                                        : (images.isNotEmpty ? images[0] : ''),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Bottom-right slot with +N overlay
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(12),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _buildImage(
                                        images.length > 2
                                            ? images[2]
                                            : (images.isNotEmpty
                                                ? images[0]
                                                : ''),
                                      ),
                                      // +N overlay when there are more than 3 images
                                      if (images.length > 3)
                                        Container(
                                          color: Colors.black
                                              .withValues(alpha: 0.55),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '+${images.length - 3}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Title ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                p.address,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // ── Price + status/listing tags ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '\$${p.price.toStringAsFixed(0)}/Month',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  // Rented badge (only when rented)
                  if (isRented)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Rented',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  // Urgent tag
                  if (!isRented && p.badgeOptions?['urgent'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Urgent',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Negotiable tag
                  if (!isRented && p.badgeOptions?['negotiable'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.handshake_outlined,
                              color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Negotiable',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Location row ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Amenity chips ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  _amenityChip(Icons.king_bed_outlined, '${p.bedroom} Beds'),
                  _amenityChip(
                      Icons.bathtub_outlined, '${p.bathroom} Baths'),
                  _amenityChip(
                      Icons.square_foot, '${p.squareArea.toInt()} m²'),
                ],
              ),
            ),

            // ── Description ───────────────────────────────────────
            if (p.description != null && p.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  p.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── View Full Details button ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailPage(id: p.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View Full Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) return Container(color: Colors.grey[300]);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey[200]),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _amenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
