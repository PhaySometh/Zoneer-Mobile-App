import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zoneer_mobile/core/utils/app_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/providers/map_focus_provider.dart';
import 'package:zoneer_mobile/features/property/repositories/property_repository.dart';
import 'package:zoneer_mobile/features/property/viewmodels/upload_property_viewmodel.dart';
import 'package:zoneer_mobile/features/property/views/location_picker_screen.dart';

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

// ---------------------------------------------------------------------------
// Photo entry helper
// ---------------------------------------------------------------------------

class _PhotoEntry {
  Uint8List? bytes;
  String? ext;
  String? existingUrl;

  _PhotoEntry({this.bytes, this.ext, this.existingUrl});

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

  // Property type
  String? _selectedPropertyType;

  // Amenity selections
  final Set<String> _selectedPropertyFeatures = {};
  final Set<String> _selectedSecurityFeatures = {};
  final Set<String> _selectedBadgeOptions = {};

  bool get _isEditing => widget.existingProperty != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProperty;
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
    _typeController = TextEditingController(text: p?.type ?? '');

    _selectedPropertyType = p?.propertyType;

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingMedia());
    }
  }

  Future<void> _loadExistingMedia() async {
    final repo = ref.read(propertyRepositoryProvider);
    final medias = await repo.getPropertyMedias(widget.existingProperty!.id);
    if (!mounted) return;
    setState(() {
      for (final m in medias) {
        if (_photos.length < _maxPhotos) {
          _photos.add(_PhotoEntry(existingUrl: m.url));
        }
      }
    });
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
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Photo helpers
  // -------------------------------------------------------------------------

  Future<void> _pickPhoto(int index) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 1200,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final ext = image.path.split('.').last;
    setState(() {
      if (index < _photos.length) {
        _photos[index] = _PhotoEntry(bytes: bytes, ext: ext);
      } else {
        // Adding a new slot
        _photos.add(_PhotoEntry(bytes: bytes, ext: ext));
      }
    });
  }

  Future<void> _pickMultiplePhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxHeight: 1200,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (images.isEmpty) return;
    for (final image in images) {
      if (_photos.length >= _maxPhotos) break;
      final bytes = await image.readAsBytes();
      final ext = image.path.split('.').last;
      if (mounted) {
        setState(() {
          _photos.add(_PhotoEntry(bytes: bytes, ext: ext));
        });
      }
    }
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

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result.latlng);
      // Auto-fill address from reverse geocode; fall back to coordinates
      final addr = result.address?.isNotEmpty == true
          ? result.address!
          : '${result.latlng.latitude.toStringAsFixed(5)}, '
              '${result.latlng.longitude.toStringAsFixed(5)}';
      _addressController.text = addr;
    }
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
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

    // Ensure address always has a value (auto-fill with coordinates as last resort)
    if (_addressController.text.trim().isEmpty) {
      _addressController.text =
          '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
          '${_selectedLocation!.longitude.toStringAsFixed(5)}';
    }

    final thumbnail = _photos[0];
    final additional = _photos.length > 1
        ? _photos
              .sublist(1)
              .map(
                (p) => (bytes: p.bytes, ext: p.ext, existingUrl: p.existingUrl),
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

    try {
      await ref
          .read(uploadPropertyViewModelProvider.notifier)
          .submit(
            thumbnailBytes: thumbnail.bytes,
            thumbnailExt: thumbnail.ext,
            existingThumbnailUrl: thumbnail.existingUrl,
            additionalPhotos: additional,
            removedImageUrls: _removedExistingUrls,
            existingProperty: widget.existingProperty,
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
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
            propertyType: _selectedPropertyType,
          );

      if (_selectedLocation != null) {
        ref.read(mapFocusProvider.notifier).focus(_selectedLocation!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Property updated successfully.'
                  : 'Property uploaded! Pending admin verification — '
                    'you can see it in My Properties now.',
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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
              // ── 1. Photos ────────────────────────────────────────────────
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

              // ── 2. Property Info (name + type) ───────────────────────────
              _buildCard(
                title: 'Property Info',
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'Property Name',
                    hint: 'e.g. Sunset Apartment, City View Room',
                    icon: Icons.label_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedPropertyType,
                    decoration: InputDecoration(
                      labelText: 'Property Type',
                      prefixIcon: Icon(
                        Icons.home_work_outlined,
                        size: 20,
                        color: AppColors.primary,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'house', child: Text('House')),
                      DropdownMenuItem(
                        value: 'apartment',
                        child: Text('Apartment'),
                      ),
                      DropdownMenuItem(
                        value: 'resident',
                        child: Text('Resident'),
                      ),
                      DropdownMenuItem(
                        value: 'traditional',
                        child: Text('Traditional'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedPropertyType = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── 3. Location ──────────────────────────────────────────────
              _buildCard(
                title: 'Location',
                children: [
                  _buildField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Auto-filled when you pick a location',
                    icon: Icons.location_on_outlined,
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

              // ── 4. Details ───────────────────────────────────────────────
              _buildCard(
                title: 'Details',
                children: [
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
        // Image — tappable to replace, but sits below the delete button
        GestureDetector(
          onTap: () => _pickPhoto(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: photo.bytes != null
                ? Image.memory(photo.bytes!, fit: BoxFit.cover)
                : Image.network(photo.existingUrl!, fit: BoxFit.cover),
          ),
        ),
        // Thumbnail badge
        if (isThumbnail)
          Positioned(
            left: 4,
            bottom: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        // Delete button — rendered last so it sits on top
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddSlot(int nextIndex) {
    return GestureDetector(
      onTap: nextIndex == 0 ? () => _pickPhoto(nextIndex) : _pickMultiplePhotos,
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
