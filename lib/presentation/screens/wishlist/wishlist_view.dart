import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';
import 'package:zoneer_mobile/presentation/viewmodels/wishlist/wishlist_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/wishlist/widgets/wishlist_auth_state.dart';
import 'package:zoneer_mobile/presentation/screens/wishlist/widgets/wishlist_empty_state.dart';
import 'package:zoneer_mobile/shared/widgets/cards/property_wishlist_card.dart';

class WishlistView extends ConsumerStatefulWidget {
  const WishlistView({super.key});

  @override
  ConsumerState<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends ConsumerState<WishlistView>
    with SingleTickerProviderStateMixin {
  bool _isManageMode = false;
  final Set<String> _selectedIds = {};

  // Animation controller for the bottom action bar
  late final AnimationController _barController;
  late final Animation<Offset> _barSlide;

  @override
  void initState() {
    super.initState();

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _barSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic),
        );

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser != null) {
      Future.microtask(() {
        ref.read(wishlistViewmodelProvider.notifier).loadWishlist(authUser.id);
      });
    }
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  // ── Manage mode helpers ────────────────────────────────────────────────────

  void _enterManageMode() {
    setState(() {
      _isManageMode = true;
      _selectedIds.clear();
    });
    _barController.forward();
  }

  void _exitManageMode() {
    _barController.reverse().then((_) {
      setState(() {
        _isManageMode = false;
        _selectedIds.clear();
      });
    });
  }

  void _toggleSelection(String propertyId) {
    setState(() {
      if (_selectedIds.contains(propertyId)) {
        _selectedIds.remove(propertyId);
      } else {
        _selectedIds.add(propertyId);
      }
    });
  }

  void _toggleSelectAll(List<String> allIds) {
    setState(() {
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  Future<void> _deleteSelected(String userId) async {
    if (_selectedIds.isEmpty) return;

    final toDelete = Set<String>.from(_selectedIds);

    // Optimistically exit manage mode then delete
    _exitManageMode();

    await ref
        .read(wishlistViewmodelProvider.notifier)
        .deleteSelected(userId, toDelete);
  }

  void _showDeleteConfirmation(String userId, int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFE53935),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Remove $count ${count == 1 ? 'item' : 'items'}?',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The selected ${count == 1 ? 'property' : 'properties'} will be removed from your wishlist.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.greyLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteSelected(userId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      return const WishlistAuthState();
    }

    final wishlistAsync = ref.watch(wishlistViewmodelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: _buildAppBar(wishlistAsync),
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────────────────
          wishlistAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading wishlist: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(wishlistViewmodelProvider.notifier)
                        .loadWishlist(authUser.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (wishlistItems) {
              if (wishlistItems.isEmpty) {
                return const WishlistEmptyState();
              }

              final propertiesAsync = ref.watch(wishlistPropertiesProvider);

              return propertiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading properties: $err'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(wishlistPropertiesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (properties) {
                  final propertyMap = {for (var p in properties) p.id: p};
                  final validItems = wishlistItems
                      .where((w) => propertyMap.containsKey(w.propertyId))
                      .toList();

                  final allIds = validItems.map((w) => w.propertyId).toList();
                  final allSelected =
                      _selectedIds.length == allIds.length && allIds.isNotEmpty;

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      _isManageMode ? 100 : 24,
                    ),
                    itemCount: validItems.length + 1,
                    itemBuilder: (context, index) {
                      // ── Header row ──────────────────────────────
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${validItems.length} ${validItems.length == 1 ? 'item' : 'items'} saved',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              // Select All (visible only in manage mode)
                              if (_isManageMode)
                                GestureDetector(
                                  onTap: () => _toggleSelectAll(allIds),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: allSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: allSelected
                                                ? AppColors.primary
                                                : AppColors.grey,
                                            width: 1.8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: allSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 13,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        allSelected
                                            ? 'Deselect All'
                                            : 'Select All',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      final item = validItems[index - 1];
                      final property = propertyMap[item.propertyId]!;
                      final isSelected = _selectedIds.contains(property.id);

                      return WishlistPropertyCard(
                        property: property,
                        actionButtonLabel: 'View Details',
                        isManageMode: _isManageMode,
                        isSelected: isSelected,
                        onSelectionToggle: _isManageMode
                            ? () => _toggleSelection(property.id)
                            : null,
                        onTap: _isManageMode
                            ? () => _toggleSelection(property.id)
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PropertyDetailPage(id: property.id),
                                ),
                              ),
                        onRemove: _isManageMode
                            ? null
                            : () => ref
                                  .read(wishlistViewmodelProvider.notifier)
                                  .removeFromWishlist(authUser.id, property.id),
                      );
                    },
                  );
                },
              );
            },
          ),

          // ── Floating bottom action bar (manage mode) ──────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _barSlide,
              child: _buildBottomBar(authUser.id),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(AsyncValue wishlistAsync) {
    return AppBar(
      backgroundColor: const Color(0xFFF6F6F6),
      iconTheme: const IconThemeData(color: Colors.black),
      elevation: 0,
      centerTitle: true,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isManageMode
            ? Text(
                _selectedIds.isEmpty
                    ? 'Select Items'
                    : '${_selectedIds.length} Selected',
                key: const ValueKey('manage'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              )
            : const Text(
                'My Wishlist',
                key: ValueKey('default'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
      actions: [
        // Only show Manage when there are items
        wishlistAsync.maybeWhen(
          data: (items) => items.isNotEmpty
              ? TextButton(
                  onPressed: _isManageMode ? _exitManageMode : _enterManageMode,
                  child: Text(
                    _isManageMode ? 'Done' : 'Manage',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar(String userId) {
    final hasSelection = _selectedIds.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item count badge
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              hasSelection
                  ? '${_selectedIds.length} selected'
                  : 'Tap items to select',
              key: ValueKey(hasSelection),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          // Delete button
          AnimatedOpacity(
            opacity: hasSelection ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: hasSelection
                  ? () => _showDeleteConfirmation(userId, _selectedIds.length)
                  : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text(
                'Remove',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE53935),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
