import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/property/providers/map_focus_provider.dart';
import 'package:zoneer_mobile/features/inquiry/views/inquiry.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/viewmodels/properties_viewmodel.dart';
import 'package:zoneer_mobile/features/property/widgets/amenity_item.dart';
import 'package:zoneer_mobile/features/property/widgets/circle_icon.dart';
import 'package:zoneer_mobile/features/property/widgets/image_widget.dart';
import 'package:zoneer_mobile/features/property/widgets/landlord_card.dart';
import 'package:zoneer_mobile/features/user/viewmodels/user_provider.dart';
import 'package:zoneer_mobile/features/user/views/auth/auth_required_screen.dart';
import 'package:zoneer_mobile/features/wishlist/models/wishlist_model.dart';
import 'package:zoneer_mobile/features/wishlist/viewmodels/wishlist_viewmodel.dart';

class PropertyDetailPage extends ConsumerStatefulWidget {
  final String id;

  const PropertyDetailPage({super.key, required this.id});

  @override
  ConsumerState<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends ConsumerState<PropertyDetailPage> {
  bool _isTogglingWishlist = false;

  void _toggleWishlist(BuildContext context) async {
    if (_isTogglingWishlist) return;

    setState(() {
      _isTogglingWishlist = true;
    });

    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthRequiredScreen()),
      );
      return;
    }

    try {
      final isInWishlist = await ref.read(
        isPropertyInWishlistProvider(widget.id).future,
      );

      bool success;
      String successMessage;

      if (isInWishlist) {
        // Remove from wishlist
        success = await ref
            .read(wishlistViewmodelProvider.notifier)
            .removeFromWishlist(authUser.id, widget.id);
        successMessage = 'Removed from wishlist';
      } else {
        // Add to wishlist
        final wishlistModel = WishlistModel(
          userId: authUser.id,
          propertyId: widget.id,
        );
        success = await ref
            .read(wishlistViewmodelProvider.notifier)
            .addToWishlist(wishlistModel);
        successMessage = 'Added to wishlist';
      }

      if (context.mounted) {
        if (success) {
          ref.invalidate(isPropertyInWishlistProvider(widget.id));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              duration: const Duration(seconds: 2),
              backgroundColor: isInWishlist ? Colors.red : AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update wishlist'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Wishlist error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingWishlist = false;
        });
      }
    }
  }

  void _scheduleTour(BuildContext context, PropertyModel property) {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthRequiredScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Inquiry(property: property)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyViewModelProvider(widget.id));
    final isInWishlistAsync = ref.watch(
      isPropertyInWishlistProvider(widget.id),
    );
    final isInWishlist = isInWishlistAsync.value ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleIcon(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),
        actions: [
          CircleIcon(
            icon: Icons.share_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 4),
          CircleIcon(
            icon: isInWishlist
                ? Icons.favorite
                : Icons.favorite_border_outlined,
            onTap: _isTogglingWishlist
                ? null
                : () => _toggleWishlist(context),
            iconColor: isInWishlist ? Colors.red : null,
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: property.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (property) {
          final landlordAsync = property.landlordId != null
              ? ref.watch(userByIdProvider(property.landlordId!))
              : null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageWidget(
                  thumbnail: property.thumbnail,
                  propertyId: widget.id,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              property.name?.isNotEmpty == true
                                  ? property.name!
                                  : 'House in ${property.address}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '\$${property.price} / month',
                            style: const TextStyle(
                              fontSize: 20,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: Color.fromARGB(255, 118, 118, 118),
                          ),
                          Text(
                            property.address,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 118, 118, 118),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AmenityItem(
                            icon: Icons.bed_outlined,
                            label: 'Bedrooms',
                            value: property.bedroom.toString(),
                          ),
                          AmenityItem(
                            icon: Icons.bathtub_outlined,
                            label: 'Bathrooms',
                            value: property.bathroom.toString(),
                          ),
                          AmenityItem(
                            icon: Icons.crop_square_outlined,
                            label: 'Area',
                            value: property.squareArea.toString(),
                          ),
                        ],
                      ),

                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (property.description != null &&
                          property.description!.isNotEmpty)
                        Text(property.description!),

                      // Amenities
                      if (_hasAnyAmenities(property)) ...[
                        const SizedBox(height: 5),
                        _buildAmenitiesSection(property),
                      ],

                      const SizedBox(height: 16),

                      // Map section
                      if (property.latitude != null && property.longitude != null) ...
                        [
                          const Text(
                            'Location',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 200,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    property.latitude!,
                                    property.longitude!,
                                  ),
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: AppConfig.mapboxTileUrl,
                                    userAgentPackageName: 'com.zoneer.mobile',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          property.latitude!,
                                          property.longitude!,
                                        ),
                                        width: 36,
                                        height: 36,
                                        child: const Icon(
                                          Icons.location_pin,
                                          color: AppColors.primary,
                                          size: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref.read(mapFocusProvider.notifier).focus(
                                  LatLng(
                                    property.latitude!,
                                    property.longitude!,
                                  ),
                                );
                                ref
                                    .read(navigationProvider.notifier)
                                    .changeTab(NavigationTab.map);
                                Navigator.of(context).popUntil(
                                  (route) => route.isFirst,
                                );
                              },
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('View in Our Map'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                      if (landlordAsync != null)
                        landlordAsync.maybeWhen(
                          data: (landlord) => LandlordCard(landlord: landlord),
                          orElse: () => const SizedBox(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: property.maybeWhen(
        orElse: () => const SizedBox(),
        data: (property) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '\$${property.price}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    ' /Month',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _scheduleTour(context, property),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    'Schedule Tour',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Amenity helpers
  // -------------------------------------------------------------------------

  static const _kPropertyFeatures = {
    'wifi': ('WiFi', Icons.wifi),
    'air_con': ('Air Conditioning', Icons.ac_unit),
    'parking': ('Parking', Icons.local_parking),
    'balcony': ('Balcony', Icons.balcony),
    'pool': ('Swimming Pool', Icons.pool),
    'gym': ('Gym', Icons.fitness_center),
    'elevator': ('Elevator', Icons.elevator),
    'furnished': ('Furnished', Icons.chair),
    'washing_machine': ('Washing Machine', Icons.local_laundry_service),
    'kitchen': ('Kitchen', Icons.kitchen),
  };

  static const _kSecurityFeatures = {
    'cctv': ('CCTV', Icons.videocam),
    'security_guard': ('Security Guard', Icons.security),
    'key_card': ('Key Card Access', Icons.credit_card),
    'gated': ('Gated Community', Icons.fence),
  };

  static const _kBadgeOptions = {
    'pet_friendly': ('Pet Friendly', Icons.pets),
    'utilities_included': ('Utilities Included', Icons.electrical_services),
    'near_school': ('Near School', Icons.school),
    'near_market': ('Near Market', Icons.storefront),
  };

  bool _hasAnyAmenities(PropertyModel p) {
    bool hasEntries(Map<String, dynamic>? map) =>
        map != null && map.entries.any((e) => e.value == true);
    return hasEntries(p.propertyFeatures) ||
        hasEntries(p.securityFeatures) ||
        hasEntries(p.badgeOptions);
  }

  Widget _buildAmenitiesSection(PropertyModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.propertyFeatures != null)
          _buildAmenityGroup(
            'Property Features',
            p.propertyFeatures!,
            _kPropertyFeatures,
          ),
        if (p.securityFeatures != null)
          _buildAmenityGroup(
            'Security',
            p.securityFeatures!,
            _kSecurityFeatures,
          ),
        if (p.badgeOptions != null)
          _buildAmenityGroup(
            'Highlights',
            p.badgeOptions!,
            _kBadgeOptions,
          ),
      ],
    );
  }

  Widget _buildAmenityGroup(
    String title,
    Map<String, dynamic> values,
    Map<String, (String, IconData)> definitions,
  ) {
    final active = values.entries
        .where((e) => e.value == true && definitions.containsKey(e.key))
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: active.map((e) {
              final (label, icon) = definitions[e.key]!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
