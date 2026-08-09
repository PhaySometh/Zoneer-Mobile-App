import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zoneer_mobile/core/providers/service_provider.dart';
import 'package:zoneer_mobile/core/utils/app_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/property/enums/property_status.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/screens/property/providers/map_focus_provider.dart';
import 'package:zoneer_mobile/data/repositories/property/property_repository.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/upload_property_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/location_picker_screen.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';

// ---------------------------------------------------------------------------
// Amenity definitions
// ---------------------------------------------------------------------------

const _kPropertyFeatures = {
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

const _kSecurityFeatures = {
  'cctv': ('CCTV', Icons.videocam),
  'security_guard': ('Security Guard', Icons.security),
  'key_card': ('Key Card Access', Icons.credit_card),
  'gated': ('Gated Community', Icons.fence),
};

const _kBadgeOptions = {
  'pet_friendly': ('Pet Friendly', Icons.pets),
  'utilities_included': ('Utilities Included', Icons.electrical_services),
  'near_school': ('Near School', Icons.school),
  'near_market': ('Near Market', Icons.storefront),
};

const _kAllowedPropertyTypes = ['room', 'apartment', 'condo', 'house'];

const _kPropertyTypeIcons = {
  'room': Icons.door_front_door_outlined,
  'apartment': Icons.apartment_outlined,
  'condo': Icons.business_outlined,
  'house': Icons.home_outlined,
};

// ---------------------------------------------------------------------------
// Photo entry helper
// ---------------------------------------------------------------------------

class _PhotoEntry {
  Uint8List? bytes;
  String? ext;
  String? mimeType;
  String? existingUrl;

  _PhotoEntry({this.bytes, this.ext, this.mimeType, this.existingUrl});

  bool get hasImage => bytes != null || existingUrl != null;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class UploadPropertyScreen extends ConsumerStatefulWidget {
  /// If non-null, we are editing an existing property.
  final PropertyModel? existingProperty;

  const UploadPropertyScreen({super.key, this.existingProperty});

  @override
  ConsumerState<UploadPropertyScreen> createState() =>
      _UploadPropertyScreenState();
}

class _UploadPropertyScreenState extends ConsumerState<UploadPropertyScreen> {
  static const int _maxPhotos = 10;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  late final TextEditingController _bedroomController;
  late final TextEditingController _bathroomController;
  late final TextEditingController _areaController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _typeController;

  LatLng? _selectedLocation;

  // Photos: index 0 = thumbnail, 1–9 = additional
  final List<_PhotoEntry> _photos = [];
  // Existing storage URLs that the user removed — deleted from storage on submit
  final List<String> _removedExistingUrls = [];
  // True while existing media is being fetched asynchronously on edit open
  bool _mediaLoading = false;

  // Amenity selections
  final Set<String> _selectedPropertyFeatures = {};
  final Set<String> _selectedSecurityFeatures = {};
  final Set<String> _selectedBadgeOptions = {};

  // Listing status (edit mode only)
  late PropertyStatus _selectedStatus;

  bool get _isEditing => widget.existingProperty != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProperty;
    _selectedStatus = p?.propertyStatus ?? PropertyStatus.available;
    _nameController = TextEditingController(text: p?.name ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _bedroomController = TextEditingController(
      text: p != null ? p.bedroom.toString() : '',
    );
    _bathroomController = TextEditingController(
      text: p != null ? p.bathroom.toString() : '',
    );
    _areaController = TextEditingController(
      text: p != null ? p.squareArea.toString() : '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    final initialTypeRaw = (p?.type ?? '').trim();
    final normalizedType = initialTypeRaw.toLowerCase();
    final String typeControllerText;
    if (p == null) {
      // New property: keep existing default behavior of "room".
      typeControllerText = 'room';
    } else if (_kAllowedPropertyTypes.contains(normalizedType)) {
      // Existing property with a recognized type: use normalized value.
      typeControllerText = normalizedType;
    } else if (initialTypeRaw.isEmpty) {
      // Existing property with no type: leave unselected so user must choose.
      typeControllerText = '';
    } else {
      // Existing property with an unrecognized/legacy type: preserve and display it.
      typeControllerText = initialTypeRaw;
    }
    _typeController = TextEditingController(
      text: typeControllerText,
    );

    if (p?.latitude != null && p?.longitude != null) {
      _selectedLocation = LatLng(p!.latitude!, p.longitude!);
    }

    // Bootstrap thumbnail slot
    if (p?.thumbnail != null && p!.thumbnail.isNotEmpty) {
      _photos.add(_PhotoEntry(existingUrl: p.thumbnail));
    }

    // Pre-select amenities from existing property
    if (p?.propertyFeatures != null) {
      _selectedPropertyFeatures.addAll(
        p!.propertyFeatures!.keys.where((k) => p.propertyFeatures![k] == true),
      );
    }
    if (p?.securityFeatures != null) {
      _selectedSecurityFeatures.addAll(
        p!.securityFeatures!.keys.where((k) => p.securityFeatures![k] == true),
      );
    }
    if (p?.badgeOptions != null) {
      _selectedBadgeOptions.addAll(
        p!.badgeOptions!.keys.where((k) => p.badgeOptions![k] == true),
      );
    }

    // Load additional media for edit mode
    if (_isEditing) {
      _mediaLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingMedia());
    }
  }

  Future<void> _loadExistingMedia() async {
    final repo = ref.read(propertyRepositoryProvider);
    try {
      final medias = await repo.getPropertyMedias(widget.existingProperty!.id);
      if (!mounted) return;
      setState(() {
        for (final m in medias) {
          if (_photos.length < _maxPhotos) {
            _photos.add(_PhotoEntry(existingUrl: m.url));
          }
        }
        _mediaLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _mediaLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _bedroomController.dispose();
    _bathroomController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Photo helpers
  // -------------------------------------------------------------------------

  Future<void> _pickPhoto(int startIndex) async {
    final picker = ImagePicker();

    // Replacing an existing slot — single pick only
    if (startIndex < _photos.length) {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1200,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final mime = image.mimeType ?? 'image/jpeg';
      final ext = mime.split('/').last == 'jpeg' ? 'jpg' : mime.split('/').last;
      setState(() {
        final oldEntry = _photos[startIndex];
        if (oldEntry.existingUrl != null) {
          _removedExistingUrls.add(oldEntry.existingUrl!);
        }
        _photos[startIndex] = _PhotoEntry(bytes: bytes, ext: ext, mimeType: mime);
      });
      return;
    }

    // Adding new slots — multi-pick
    final images = await picker.pickMultiImage(
      maxHeight: 1200,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (images.isEmpty) return;

    final remaining = _maxPhotos - _photos.length;
    final toAdd = images.take(remaining).toList();

    if (images.length > remaining && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only $remaining photo${remaining == 1 ? '' : 's'} remaining. '
            'Added the first $remaining.',
          ),
        ),
      );
    }

    final entries = await Future.wait(
      toAdd.map((img) async {
        final bytes = await img.readAsBytes();
        final mime = img.mimeType ?? 'image/jpeg';
        final ext = mime.split('/').last == 'jpeg' ? 'jpg' : mime.split('/').last;
        return _PhotoEntry(bytes: bytes, ext: ext, mimeType: mime);
      }),
    );

    setState(() => _photos.addAll(entries));
  }

  void _setAsCover(int index) {
    if (index == 0) return;
    setState(() {
      final cover = _photos.removeAt(index);
      _photos.insert(0, cover);
    });
  }

  void _showPhotoOptions(int index) {
    final isCover = index == 0;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!isCover)
              ListTile(
                leading: const Icon(Icons.star_rounded, color: AppColors.primary),
                title: const Text('Set as Cover'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setAsCover(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Replace Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _removePhoto(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      final photo = _photos[index];
      if (photo.existingUrl != null) {
        _removedExistingUrls.add(photo.existingUrl!);
      }
      _photos.removeAt(index);
    });
  }

  // -------------------------------------------------------------------------
  // Location
  // -------------------------------------------------------------------------

  bool _geocoding = false;

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _geocoding = true;
      });
      // Auto-fill address via reverse geocoding
      try {
        final locationService = ref.read(locationServiceProvider);
        final address = await locationService.getCityFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (address != null && mounted) {
          _addressController.text = address;
        }
      } finally {
        if (mounted) setState(() => _geocoding = false);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_mediaLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading existing images, please wait…'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final hasThumbnail = _photos.isNotEmpty && _photos[0].hasImage;
    if (!hasThumbnail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least a thumbnail image.'),
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on the map.')),
      );
      return;
    }

    final thumbnail = _photos[0];
    final additional = _photos.length > 1
        ? _photos
              .sublist(1)
              .map(
                (p) => (bytes: p.bytes, ext: p.ext, mimeType: p.mimeType, existingUrl: p.existingUrl),
              )
              .toList()
        : <PhotoData>[];

    final propertyFeatures = _selectedPropertyFeatures.isEmpty
        ? null
        : {for (final k in _selectedPropertyFeatures) k: true};
    final securityFeatures = _selectedSecurityFeatures.isEmpty
        ? null
        : {for (final k in _selectedSecurityFeatures) k: true};
    final badgeOptions = _selectedBadgeOptions.isEmpty
        ? null
        : {for (final k in _selectedBadgeOptions) k: true};
    final type = _typeController.text.trim().toLowerCase();

    if (!_kAllowedPropertyTypes.contains(type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Property type must be room, apartment, condo, or house.',
          ),
        ),
      );
      return;
    }

    try {
      final propertyId = await ref
          .read(uploadPropertyViewModelProvider.notifier)
          .submit(
            thumbnailBytes: thumbnail.bytes,
            thumbnailExt: thumbnail.ext,
            thumbnailMimeType: thumbnail.mimeType,
            existingThumbnailUrl: thumbnail.existingUrl,
            additionalPhotos: additional,
            removedImageUrls: _removedExistingUrls,
            existingProperty: widget.existingProperty,
            price: double.parse(_priceController.text.trim()),
            bedroom: int.parse(_bedroomController.text.trim()),
            bathroom: int.parse(_bathroomController.text.trim()),
            squareArea: double.parse(_areaController.text.trim()),
            address: _addressController.text.trim(),
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            description: _descriptionController.text.trim(),
            propertyFeatures: propertyFeatures,
            securityFeatures: securityFeatures,
            badgeOptions: badgeOptions,
            type: type,
            name: _nameController.text.trim(),
            propertyStatus: _isEditing ? _selectedStatus : null,
          );

      if (_selectedLocation != null) {
        ref.read(mapFocusProvider.notifier).focus(_selectedLocation!);
      }

      if (mounted) {
        final viewDetail = await _showSuccessDialog(
          context,
          propertyId: propertyId,
          propertyName: _nameController.text.trim(),
          isEditing: _isEditing,
        );
        if (mounted) {
          if (viewDetail) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PropertyDetailPage(id: propertyId),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Success dialog
  // -------------------------------------------------------------------------

  Future<bool> _showSuccessDialog(
    BuildContext context, {
    required String propertyId,
    required String propertyName,
    required bool isEditing,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UploadSuccessDialog(
        propertyId: propertyId,
        propertyName: propertyName,
        isEditing: isEditing,
      ),
    );
    return result ?? false;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(uploadPropertyViewModelProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Property' : 'Upload Property',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photos ──────────────────────────────────────────────────
              _buildCard(
                title:
                    'Photos (${_photos.where((p) => p.hasImage).length}/$_maxPhotos)',
                children: [
                  const Text(
                    'First photo is the thumbnail. Up to 10 photos total.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoGrid(),
                ],
              ),

              const SizedBox(height: 14),

              // ── Name ─────────────────────────────────────────────────────
              _buildCard(
                title: 'Property Name',
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'e.g. Cozy Studio near BKK1',
                    icon: Icons.label_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Location ────────────────────────────────────────────────
              _buildCard(
                title: 'Location',
                children: [
                  Stack(
                    children: [
                      _buildField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'e.g. Chbar Ampov, Phnom Penh',
                        icon: Icons.location_on_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      if (_geocoding)
                        const Positioned(
                          right: 12,
                          top: 14,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_selectedLocation != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 150,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: _selectedLocation!,
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
                                  point: _selectedLocation!,
                                  width: 32,
                                  height: 32,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: AppColors.primary,
                                    size: 32,
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
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                            '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openLocationPicker,
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_location_alt_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap to pick location on map',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Details ─────────────────────────────────────────────────
              _buildCard(
                title: 'Details',
                children: [
                  _buildPropertyTypeSelector(),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _priceController,
                    label: 'Price per month (\$)',
                    hint: '300',
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}$'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _bedroomController,
                          label: 'Bedrooms',
                          hint: '2',
                          icon: Icons.bed_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _bathroomController,
                          label: 'Bathrooms',
                          hint: '1',
                          icon: Icons.bathtub_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _areaController,
                    label: 'Square Area (m²)',
                    hint: '50',
                    icon: Icons.square_foot_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Description ──────────────────────────────────────────────
              _buildCard(
                title: 'Description',
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe your property...',
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Amenities ────────────────────────────────────────────────
              _buildCard(
                title: 'Amenities',
                children: [
                  _buildAmenitySection(
                    label: 'Property Features',
                    definitions: _kPropertyFeatures,
                    selected: _selectedPropertyFeatures,
                  ),
                  const SizedBox(height: 16),
                  _buildAmenitySection(
                    label: 'Security',
                    definitions: _kSecurityFeatures,
                    selected: _selectedSecurityFeatures,
                  ),
                  const SizedBox(height: 16),
                  _buildAmenitySection(
                    label: 'Highlights',
                    definitions: _kBadgeOptions,
                    selected: _selectedBadgeOptions,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Listing Tags ──────────────────────────────────────────────
              _buildCard(
                title: 'Listing Tags',
                children: [
                  const Text(
                    'Help renters understand your listing status at a glance.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  _buildListingTagToggle(
                    key: 'urgent',
                    label: 'Urgent',
                    subtitle: 'Needs to be rented soon',
                    icon: Icons.warning_amber_rounded,
                    activeColor: const Color(0xFFDC2626),
                    selected: _selectedBadgeOptions,
                  ),
                  const SizedBox(height: 10),
                  _buildListingTagToggle(
                    key: 'negotiable',
                    label: 'Negotiable',
                    subtitle: 'Price is open to discussion',
                    icon: Icons.handshake_outlined,
                    activeColor: const Color(0xFFD97706),
                    selected: _selectedBadgeOptions,
                  ),
                ],
              ),

              // ── Listing Status (edit mode only) ──────────────────────────
              if (_isEditing) ...[
                const SizedBox(height: 14),
                _buildCard(
                  title: 'Listing Status',
                  children: [
                    const Text(
                      'This status is visible to all users.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusOption(
                            label: 'Available',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            isSelected:
                                _selectedStatus == PropertyStatus.available,
                            onTap: () => setState(() =>
                                _selectedStatus = PropertyStatus.available),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatusOption(
                            label: 'Rented',
                            icon: Icons.cancel_outlined,
                            color: Colors.red,
                            isSelected:
                                _selectedStatus == PropertyStatus.rented,
                            onTap: () => setState(() =>
                                _selectedStatus = PropertyStatus.rented),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Upload Property',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Photo grid
  // -------------------------------------------------------------------------

  Widget _buildPhotoGrid() {
    // Build slot list: filled photos + one "add" slot (if under limit)
    final filledCount = _photos.length;
    final showAdd = filledCount < _maxPhotos;
    final totalSlots = filledCount + (showAdd ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, i) {
        if (i < filledCount) {
          return _buildFilledSlot(i);
        }
        // "Add" slot
        return _buildAddSlot(filledCount);
      },
    );
  }

  Widget _buildFilledSlot(int index) {
    final photo = _photos[index];
    final isThumbnail = index == 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image — tappable to open options (set as cover / replace / remove)
        GestureDetector(
          onTap: () => _showPhotoOptions(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: photo.bytes != null
                ? Image.memory(photo.bytes!, fit: BoxFit.cover)
                : Image.network(photo.existingUrl!, fit: BoxFit.cover),
          ),
        ),
        // Cover badge (index 0) or "tap" hint for others
        Positioned(
          left: 4,
          bottom: 4,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isThumbnail
                    ? AppColors.primary.withValues(alpha: 0.85)
                    : Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isThumbnail ? 'Cover' : 'Tap to set',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddSlot(int nextIndex) {
    return GestureDetector(
      onTap: () => _pickPhoto(nextIndex),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              nextIndex == 0 ? 'Add Cover' : 'Add Photo',
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Property type selector
  // -------------------------------------------------------------------------

  Widget _buildPropertyTypeSelector() {
    final selected = _typeController.text;
    final icon = _kPropertyTypeIcons[selected] ?? Icons.home_work_outlined;
    final label = selected.isEmpty
        ? 'Select a property type'
        : selected[0].toUpperCase() + selected.substring(1);

    return FormField<String>(
      initialValue: selected,
      validator: (_) {
        final v = _typeController.text.trim();
        if (v.isEmpty) return 'Required';
        return _kAllowedPropertyTypes.contains(v) ? null : 'Invalid type';
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _showPropertyTypeSheet(field),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: field.hasError
                        ? Colors.red
                        : selected.isNotEmpty
                        ? AppColors.primary
                        : Colors.black12,
                    width: selected.isNotEmpty ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: selected.isNotEmpty
                          ? AppColors.primary
                          : Colors.black38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: selected.isNotEmpty
                              ? Colors.black87
                              : Colors.black38,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: selected.isNotEmpty
                          ? AppColors.primary
                          : Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showPropertyTypeSheet(FormFieldState<String> field) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final current = _typeController.text;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Select Property Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _kAllowedPropertyTypes.map((type) {
                      final isSelected = current == type;
                      final typeIcon =
                          _kPropertyTypeIcons[type] ?? Icons.home_outlined;
                      final typeLabel =
                          type[0].toUpperCase() + type.substring(1);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {});
                          setState(() => _typeController.text = type);
                          field.didChange(type);
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.black12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                typeIcon,
                                size: 22,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Amenity section
  // -------------------------------------------------------------------------

  Widget _buildAmenitySection({
    required String label,
    required Map<String, (String, IconData)> definitions,
    required Set<String> selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: definitions.entries.map((entry) {
            final key = entry.key;
            final (name, icon) = entry.value;
            final isSelected = selected.contains(key);
            return FilterChip(
              label: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              avatar: Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    selected.add(key);
                  } else {
                    selected.remove(key);
                  }
                });
              },
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade100,
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.black12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Listing tag toggle (urgent / negotiable) — visually distinct from amenities
  // -------------------------------------------------------------------------

  Widget _buildListingTagToggle({
    required String key,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required Set<String> selected,
  }) {
    final isSelected = selected.contains(key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selected.remove(key);
          } else {
            selected.add(key);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.07) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.black12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? activeColor : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.7)
                          : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeColor : Colors.black26,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Status option tile
  // -------------------------------------------------------------------------

  Widget _buildStatusOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.black12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? color : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Shared helpers
  // -------------------------------------------------------------------------

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

// =============================================================================
// Success dialog shown after upload / edit
// =============================================================================

class _UploadSuccessDialog extends StatelessWidget {
  final String propertyId; // kept for potential future use
  final String propertyName;
  final bool isEditing;

  const _UploadSuccessDialog({
    required this.propertyId,
    required this.propertyName,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isEditing ? 'Property Updated!' : 'Property Uploaded!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Property name
            if (propertyName.isNotEmpty)
              Text(
                '"$propertyName"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),

            // Message
            Text(
              isEditing
                  ? 'Your property has been updated successfully.'
                  : 'Your property is now under review. We\'ll notify you once it\'s verified.',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                // OK button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // View Detail button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Detail',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
}
