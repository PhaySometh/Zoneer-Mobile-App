import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';

/// Reusable horizontal property card with manage-mode selection support.
///
/// Parameters:
/// - [isManageMode]       : when true, shows a checkbox overlay and hides
///                          the delete icon + CTA button.
/// - [isSelected]         : whether this card is currently selected.
/// - [onSelectionToggle]  : called when the user taps the checkbox.
/// - [onRemove]           : shows a trash icon & confirmation (normal mode).
/// - [onTap]              : navigates to detail (normal) or toggles (manage).
/// - [actionButtonLabel]  : label for the CTA button.
class WishlistPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isManageMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final String actionButtonLabel;

  const WishlistPropertyCard({
    super.key,
    required this.property,
    this.isManageMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onRemove,
    this.onTap,
    this.actionButtonLabel = 'View Details',
  });

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove from Wishlist'),
        content: const Text(
          'Are you sure you want to remove this property from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove?.call();
            },
            child: Text(
              'Remove',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Card body ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      property.thumbnail,
                      width: 95,
                      height: 95,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 95,
                        height: 95,
                        color: AppColors.greyLight,
                        child: Icon(
                          Icons.home_outlined,
                          color: AppColors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price row + delete icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '\$${property.price.toStringAsFixed(0)}/month',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            // Delete icon — hidden in manage mode
                            if (!isManageMode && onRemove != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _confirmRemove(context),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.greyLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.primaryLight,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Address
                        Text(
                          property.address,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // CTA — hidden in manage mode
                        if (!isManageMode)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: onTap,
                              label: Text(
                                actionButtonLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              icon: const Icon(
                                Icons.remove_red_eye,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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

            // ── Checkbox overlay (manage mode only) ─────────────────────────
            if (isManageMode)
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onSelectionToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
