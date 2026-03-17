import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/property/views/property_detail_page.dart';
import 'package:zoneer_mobile/features/user/views/auth/auth_required_screen.dart';
import 'package:zoneer_mobile/features/wishlist/viewmodels/wishlist_viewmodel.dart';
import 'package:zoneer_mobile/features/wishlist/widgets/wishlist_empty_state.dart';
import 'package:zoneer_mobile/shared/widgets/cards/property_wishlist_card.dart';

class WishlistView extends ConsumerStatefulWidget {
  const WishlistView({super.key});

  @override
  ConsumerState<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends ConsumerState<WishlistView> {
  @override
  void initState() {
    super.initState();
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser != null) {
      Future.microtask(() {
        ref.read(wishlistViewmodelProvider.notifier).loadWishlist(authUser.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      return const AuthRequiredScreen();
    }

    final wishlistAsync = ref.watch(wishlistViewmodelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading wishlist: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(wishlistViewmodelProvider.notifier)
                      .loadWishlist(authUser.id);
                },
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
                    onPressed: () => ref.invalidate(wishlistPropertiesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (properties) {
              final propertyMap = {
                for (var p in properties) p.id: p,
              };
              final validItems = wishlistItems
                  .where((w) => propertyMap.containsKey(w.propertyId))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: validItems.length + 1,
                itemBuilder: (context, index) {
                  // header
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        '${validItems.length} ${validItems.length == 1 ? 'item' : 'items'} saved',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final item = validItems[index - 1];
                  final property = propertyMap[item.propertyId]!;

                  return WishlistPropertyCard(
                    property: property,
                    actionButtonLabel: 'View Details',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailPage(id: property.id),
                      ),
                    ),
                    onRemove: () => ref
                        .read(wishlistViewmodelProvider.notifier)
                        .removeFromWishlist(authUser.id, property.id),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
