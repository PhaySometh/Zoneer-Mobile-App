import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/user/user_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _occupationController;
  UserModel? _user;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  int _imageVersion = 0; // incremented once after save to bust NetworkImage cache

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _occupationController = TextEditingController();

    // Await the future after first frame so provider has time to resolve
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return;
      try {
        final user = await ref.read(userByIdProvider(authUser.id).future);
        if (!mounted) return;
        setState(() {
          _user = user;
          _nameController.text = user.fullname;
          _phoneController.text = user.phoneNumber ?? '';
          _occupationController.text = user.occupation ?? '';
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedImage = picked;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? imageUrl;

      // Try image upload independently — error shown but doesn't block text save
      if (_selectedImage != null) {
        try {
          await _deleteOldProfileImages(userId);
          imageUrl = await _uploadProfileImage(userId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: $e')),
            );
          }
        }
      }

      await Supabase.instance.client
          .from('users')
          .update({
            'fullname': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'occupation': _occupationController.text.trim(),
            if (imageUrl != null) 'image_profile_url': imageUrl,
          })
          .eq('id', userId);

      // Clear Flutter's image cache so new image shows everywhere
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Invalidate both providers so TenantProfileSetting also re-renders
      ref.invalidate(userByIdProvider(userId));
      ref.invalidate(userProfileOrCreateProvider(userId));

      // Wait for fresh data before popping
      final updatedUser = await ref.read(userByIdProvider(userId).future);

      if (mounted) {
        setState(() {
          _user = updatedUser;
          _selectedImage = null;
          _selectedImageBytes = null;
          _imageVersion++; // bump once so ?v= param changes and forces reload
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteOldProfileImages(String userId) async {
    final files = await Supabase.instance.client.storage
        .from('profiles')
        .list(path: userId);
    if (files.isNotEmpty) {
      final paths = files.map((f) => '$userId/${f.name}').toList();
      await Supabase.instance.client.storage.from('profiles').remove(paths);
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedImage == null || _selectedImageBytes == null) return null;

    final ext = _selectedImage!.name.split('.').last;
    final path =
        '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await Supabase.instance.client.storage
        .from('profiles')
        .uploadBinary(path, _selectedImageBytes!);

    return Supabase.instance.client.storage.from('profiles').getPublicUrl(path);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete My Account',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('users').delete().eq('id', userId);
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser!;

    // Show loading until data arrives from the provider
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'View Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFFF6F6F6),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final imageUrl = _user?.profileUrl;
    final avatar = _selectedImageBytes != null
        ? MemoryImage(_selectedImageBytes!) as ImageProvider
        : (imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage('$imageUrl?v=$_imageVersion') as ImageProvider
            : null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Profile' : 'View Profile',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: avatar,
                      backgroundColor: const Color(0xFFE9E9E9),
                      child: avatar == null
                          ? const Icon(
                              Icons.person,
                              size: 52,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fields card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    label: 'Full Name',
                    controller: _nameController,
                    enabled: _isEditing,
                    validator: _isEditing
                        ? (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Email — always read-only
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          authUser.email ?? '',
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Email cannot be changed',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Occupation',
                    controller: _occupationController,
                    enabled: _isEditing,
                    hint: 'e.g. Student, Engineer',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Edit Information / Save Changes button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSaving || _isDeleting)
                    ? null
                    : () {
                        if (_isEditing) {
                          _saveProfile();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Edit Information',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Delete Account
            Center(
              child: TextButton(
                onPressed: (_isDeleting || _isSaving) ? null : _confirmDeleteAccount,
                child: _isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                      )
                    : const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(
            color: enabled ? Colors.black87 : Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
