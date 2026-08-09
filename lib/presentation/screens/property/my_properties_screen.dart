import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/core/utils/app_decoration.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/data/repositories/property/property_repository.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/properties_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/upload_property_screen.dart';
import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';

class MyPropertiesScreen extends ConsumerStatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  ConsumerState<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends ConsumerState<MyPropertiesScreen> {
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser!.id;
  }

  Future<void> _deleteProperty(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Remove immediately from UI for instant feedback.
    ref.read(landlordPropertiesProvider(_userId).notifier).removeProperty(id);

    try {
      await ref.read(propertyRepositoryProvider).deleteProperty(id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Property deleted.')));
      }
    } catch (e) {
      // Restore by reloading on failure.
      ref.invalidate(landlordPropertiesProvider(_userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.toString()}')),
        );
      }
    }
  }

  void _goToUpload({PropertyModel? existing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadPropertyScreen(existingProperty: existing),
      ),
    );
    // Create → handled instantly via prependProperty in the viewmodel.
    // Edit → invalidated by the viewmodel, causing a refetch.
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(landlordPropertiesProvider(_userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Properties',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: propertiesAsync.when(
        loading: () => const _MyPropertiesSkeleton(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (myProperties) {
          if (myProperties.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 54,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          Positioned(
                            bottom: 22,
                            right: 22,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No listings yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'List your property to start receiving inquiries from renters.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _goToUpload(),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'List Your Property',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: myProperties.length,
            itemBuilder: (context, index) {
              final property = myProperties[index];
              return _PropertyManageCard(
                key: ValueKey(property.id),
                property: property,
                onEdit: () => _goToUpload(existing: property),
                onDelete: () => _deleteProperty(property.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToUpload(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Upload Property'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loading
// ─────────────────────────────────────────────────────────────────────────────

class _MyPropertiesSkeleton extends StatelessWidget {
  const _MyPropertiesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 3,
      itemBuilder: (_, __) => const _PropertyManageCardSkeleton(),
    );
  }
}

class _PropertyManageCardSkeleton extends StatefulWidget {
  const _PropertyManageCardSkeleton();

  @override
  State<_PropertyManageCardSkeleton> createState() =>
      _PropertyManageCardSkeletonState();
}

class _PropertyManageCardSkeletonState extends State<_PropertyManageCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double radius = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail placeholder
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _box(72, 24, radius: 20),
                        const SizedBox(width: 8),
                        _box(56, 24, radius: 20),
                        const Spacer(),
                        _box(60, 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _box(200, 14),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _box(60, 12),
                        const SizedBox(width: 12),
                        _box(60, 12),
                        const SizedBox(width: 12),
                        _box(60, 12),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _box(double.infinity, 38, radius: 10)),
                        const SizedBox(width: 10),
                        Expanded(child: _box(double.infinity, 38, radius: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PropertyManageCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyManageCard({
    super.key,
    required this.property,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              property.thumbnail,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: Colors.black12,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.black38,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status chip row
                Row(
                  children: [
                    _StatusChip(status: property.propertyStatus!.value),
                    const SizedBox(width: 8),
                    _VerifyBadge(verifyStatus: property.verifyStatus),
                    const Spacer(),
                    Text(
                      '\$${property.price.toStringAsFixed(0)}/mo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Address
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Stats row
                Row(
                  children: [
                    const Icon(
                      Icons.bed_outlined,
                      size: 15,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.bedroom} bed',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.bathtub_outlined,
                      size: 15,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.bathroom} bath',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.square_foot_outlined,
                      size: 15,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.squareArea.toStringAsFixed(0)} m²',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Rented',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isAvailable ? Colors.green[700] : Colors.orange[700],
        ),
      ),
    );
  }
}

class _VerifyBadge extends StatelessWidget {
  final VerifyStatus? verifyStatus;
  const _VerifyBadge({required this.verifyStatus});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String label;

    switch (verifyStatus) {
      case VerifyStatus.verified:
        bgColor = Colors.green.withValues(alpha: 0.12);
        fgColor = Colors.green[700]!;
        icon = Icons.check_circle_outline;
        label = 'Verified';
      case VerifyStatus.rejected:
        bgColor = Colors.red.withValues(alpha: 0.12);
        fgColor = Colors.red[700]!;
        icon = Icons.cancel_outlined;
        label = 'Rejected';
      default:
        bgColor = Colors.amber.withValues(alpha: 0.12);
        fgColor = Colors.amber[800]!;
        icon = Icons.schedule_outlined;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
