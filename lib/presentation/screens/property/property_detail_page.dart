import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/screens/inquiry/inquiry.dart';
import 'package:zoneer_mobile/data/models/property/enums/property_status.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/screens/property/providers/map_focus_provider.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/properties_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/amenity_item.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/circle_icon.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/image_widget.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';
import 'package:zoneer_mobile/presentation/screens/user/auth/auth_required_screen.dart';
import 'package:zoneer_mobile/presentation/screens/user/user_public_profile_screen.dart';
import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';
import 'package:zoneer_mobile/data/models/wishlist/wishlist_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/wishlist/wishlist_viewmodel.dart';

class PropertyDetailPage extends ConsumerStatefulWidget {
  final String id;

  const PropertyDetailPage({super.key, required this.id});

  @override
  ConsumerState<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends ConsumerState<PropertyDetailPage> {
  bool _isTogglingWishlist = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  void _shareProperty(PropertyModel property) {
    final name =
        property.name?.isNotEmpty == true ? property.name! : property.address;
    final price = property.price.toStringAsFixed(0);
    final text = '📍 Check out this property on Zoneer!\n\n'
        '🏠 $name\n'
        '💰 \$$price/month\n'
        '📍 ${property.address}\n\n'
        'View it here: zoneer://property/${property.id}';
    Share.share(text, subject: 'Check out this property on Zoneer!');
  }

  void _viewInOurMap(PropertyModel property) {
    if (property.latitude == null || property.longitude == null) return;
    ref.read(mapFocusProvider.notifier).focus(
      LatLng(property.latitude!, property.longitude!),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
    ref.read(mapTabViewProvider.notifier).showMap();
    ref.read(navigationProvider.notifier).changeTab(NavigationTab.map);
  }

  Future<void> _getDirections(PropertyModel property) async {
    final lat = property.latitude;
    final lng = property.longitude;
    if (lat == null || lng == null) return;

    final String url;
    if (_userPosition != null) {
      url =
          'https://www.google.com/maps/dir/${_userPosition!.latitude},${_userPosition!.longitude}/$lat,$lng';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  Widget _buildStatusBadge(PropertyStatus? status) {
    final isAvailable = status != PropertyStatus.rented;
    final color = isAvailable ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Available' : 'Rented',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Urgent / Negotiable tag chip shown to all users.
  Widget _buildListingTag({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceChip(PropertyModel property) {
    final distanceMeters = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      property.latitude!,
      property.longitude!,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.near_me_outlined, size: 13, color: Colors.grey),
        const SizedBox(width: 2),
        Text(
          _formatDistance(distanceMeters),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _toggleWishlist(BuildContext context) async {
    if (_isTogglingWishlist) return;

    setState(() {
      _isTogglingWishlist = true;
    });

    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      setState(() => _isTogglingWishlist = false);
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
            onTap: () {
              final p = ref
                  .read(propertyViewModelProvider(widget.id))
                  .value;
              if (p != null) {
                _shareProperty(p);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Property is still loading, please try again.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),
          CircleIcon(
            icon: isInWishlist
                ? Icons.favorite
                : Icons.favorite_border_outlined,
            onTap: _isTogglingWishlist ? null : () => _toggleWishlist(context),
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
                      // Property name — full width, no overlap
                      Text(
                        property.name?.isNotEmpty == true
                            ? property.name!
                            : 'House in ${property.address}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Price + status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(property.propertyStatus),
                          // Price
                          Text(
                            '\$${property.price.toStringAsFixed(0)} / mo',
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Urgent / Negotiable tags (visible to all users)
                      if ((property.badgeOptions?['urgent'] == true) ||
                          (property.badgeOptions?['negotiable'] == true))
                        Wrap(
                          spacing: 8,
                          children: [
                            if (property.badgeOptions?['urgent'] == true)
                              _buildListingTag(
                                label: 'Urgent',
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFDC2626),
                              ),
                            if (property.badgeOptions?['negotiable'] == true)
                              _buildListingTag(
                                label: 'Negotiable',
                                icon: Icons.handshake_outlined,
                                color: const Color(0xFFD97706),
                              ),
                          ],
                        ),

                      // Distance chip
                      if (_userPosition != null &&
                          property.latitude != null &&
                          property.longitude != null)
                        _buildDistanceChip(property),

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

                      if (property.description != null &&
                          property.description!.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(property.description!),
                      ],

                      // Amenities
                      if (_hasAnyAmenities(property)) ...[
                        const SizedBox(height: 5),
                        _buildAmenitiesSection(property),
                      ],

                      // About the Host section
                      if (property.landlordId != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'About the Host',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildHostSection(property.landlordId!),
                      ],

                      const SizedBox(height: 16),

                      // Map section
                      if (property.latitude != null &&
                          property.longitude != null) ...[
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
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _viewInOurMap(property),
                                icon: const Icon(
                                  Icons.map_outlined,
                                  size: 16,
                                ),
                                label: const Text('View in Map'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _getDirections(property),
                                icon: const Icon(
                                  Icons.directions_outlined,
                                  size: 16,
                                ),
                                label: const Text('Get Directions'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
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
        data: (property) {
          final currentUserId =
              Supabase.instance.client.auth.currentUser?.id;
          final isOwner = currentUserId != null &&
              property.landlordId != null &&
              currentUserId == property.landlordId;

          return Container(
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
                    const Text(
                      ' /Month',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Your Property',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
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
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Host section
  // -------------------------------------------------------------------------

  Widget _buildHostSection(String landlordId) {
    final hostAsync = ref.watch(userByIdProvider(landlordId));
    return hostAsync.when(
      loading: () => const Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.black12),
          SizedBox(width: 12),
          SizedBox(
            width: 120,
            height: 14,
            child: ColoredBox(color: Colors.black12),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (host) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserPublicProfileScreen(userId: landlordId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (host.profileUrl?.isNotEmpty == true)
                    ? NetworkImage(host.profileUrl!)
                    : null,
                backgroundColor: const Color(0xFFE9E9E9),
                child: (host.profileUrl == null || host.profileUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 28, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          host.fullname,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (host.verifyStatus == VerifyStatus.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      host.verifyStatus == VerifyStatus.verified
                          ? 'Verified Host'
                          : 'Host',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
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
          _buildAmenityGroup('Highlights', p.badgeOptions!, _kBadgeOptions),
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

