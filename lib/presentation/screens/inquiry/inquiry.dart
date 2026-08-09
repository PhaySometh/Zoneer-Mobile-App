import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/inquiry/inquiry_model.dart';
import 'package:zoneer_mobile/presentation/screens/inquiry/review_inquiry.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/amenity_item.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';
import 'package:zoneer_mobile/presentation/screens/user/auth/auth_required_screen.dart';

class Inquiry extends ConsumerStatefulWidget {
  final PropertyModel property;

  const Inquiry({super.key, required this.property});

  @override
  ConsumerState<Inquiry> createState() => _InquiryState();
}

class _InquiryState extends ConsumerState<Inquiry> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _moveInDateController = TextEditingController();
  final _messageController = TextEditingController();

  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;
    try {
      final user = await ref.read(userByIdProvider(authUser.id).future);
      if (!mounted) return;
      _fullNameController.text = user.fullname;
      _emailController.text = user.email;
      if (user.phoneNumber?.isNotEmpty == true) {
        _phoneController.text = user.phoneNumber!;
      }
      if (user.occupation?.isNotEmpty == true) {
        _occupationController.text = user.occupation!;
      }
    } catch (_) {
      // silently fail — form remains manually fillable
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _moveInDateController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthRequiredScreen()),
      );
      return;
    }

    if (_fullNameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fullname and Phone number must be filled!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final InquiryModel inquiry = InquiryModel(
      propertyId: widget.property.id,
      userId: authUser.id,
      fullname: _fullNameController.text,
      phoneNumber: _phoneController.text,
      message: _messageController.text,
      email: _emailController.text,
      occupation: _occupationController.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReviewInquiry(property: widget.property, inquiry: inquiry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rental Inquiry',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Property Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.property.thumbnail,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.property.name?.isNotEmpty == true
                        ? widget.property.name!
                        : 'House in ${widget.property.address}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${widget.property.price.toStringAsFixed(0)} / mo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.property.address,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AmenityItem(
                        label: 'Bedroom',
                        value: widget.property.bedroom.toString(),
                        icon: Icons.bed,
                      ),
                      AmenityItem(
                        label: 'Bathroom',
                        value: widget.property.bathroom.toString(),
                        icon: Icons.bathroom,
                      ),
                      AmenityItem(
                        label: 'Area',
                        value: widget.property.squareArea.toString(),
                        icon: Icons.square_foot,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Your Information Form Section
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your informations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),

                  // Full Name and Email Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Full Name',
                          hint: 'Chhunhour',
                          controller: _fullNameController,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Email Address',
                          hint: 'chhunhour@gmail.com',
                          controller: _emailController,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Phone and Occupation Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Phone Number',
                          hint: '+855 12292870',
                          controller: _phoneController,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Occupation',
                          hint: 'Student',
                          controller: _occupationController,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Move-in Date
                  _buildTextField(
                    label: 'Preferred Move-in Date',
                    hint: 'Select a date',
                    controller: _moveInDateController,
                    readOnly: true,
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        _moveInDateController.text =
                            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                      }
                    },
                  ),
                  SizedBox(height: 12),

                  // Message
                  _buildTextField(
                    label: 'Message',
                    hint: 'Messages',
                    controller: _messageController,
                    maxLines: 4,
                  ),
                  SizedBox(height: 16),

                  // Agreement Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (value) {
                          setState(() {
                            _agreed = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'I agree to share my contact informations with the landlord. I understand that this platform connects tenants with landlord.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _agreed ? _onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit Inquiry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
