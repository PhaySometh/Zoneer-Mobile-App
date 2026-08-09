import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/inquiry/inquiry_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/inquiry/inquiry_viewmodel.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';

class ReviewInquiry extends ConsumerWidget {
  final PropertyModel property;
  final InquiryModel inquiry;

  const ReviewInquiry({
    super.key,
    required this.property,
    required this.inquiry,
  });

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );

    bool success = false;
    try {
      // Submit the inquiry
      success = await ref
          .read(inquiriesViewModelProvider.notifier)
          .submitInquiry(inquiry);
    } catch (_) {
      success = false;
    }

    if (context.mounted) Navigator.of(context).pop();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inquiry submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit inquiry. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contact information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Summary Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Property Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            property.thumbnail,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 50),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${property.bedroom} Bedroom house in ${property.address}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.address,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.bookmark,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Your Inquiry Details Section
                  const Text(
                    'Your Inquiry Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailItem('Name', inquiry.fullname),
                  const SizedBox(height: 16),

                  if (inquiry.email != null && inquiry.email!.isNotEmpty) ...[
                    _buildDetailItem('Email', inquiry.email!),
                    const SizedBox(height: 16),
                  ],

                  _buildDetailItem('Phone', inquiry.phoneNumber),
                  const SizedBox(height: 16),

                  _buildDetailItem('Occupation', inquiry.occupation!),
                  const SizedBox(height: 16),

                  _buildDetailItem('Move-in Date', '12/2/2025'),
                  const SizedBox(height: 16),

                  _buildDetailItem('Message', inquiry.message),

                  const SizedBox(height: 32),

                  // Next Steps Section
                  const Text(
                    'Next Steps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildNextStepItem(
                    number: 1,
                    title: 'Contact the Landlord',
                    description:
                        'Use the contact information above to reach out and express your interest.',
                  ),
                  const SizedBox(height: 12),

                  _buildNextStepItem(
                    number: 2,
                    title: 'Schedule a Viewing',
                    description:
                        'Arrange a time to visit the property in person.',
                  ),
                  const SizedBox(height: 12),

                  _buildNextStepItem(
                    number: 3,
                    title: 'Discuss Terms',
                    description:
                        'Discuss rental terms and lease agreement directly with landlord.',
                  ),

                  const SizedBox(height: 24),

                  // Safety Tips Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFB84D),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Safety Tips',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSafetyTip(
                          'Always view property before any payment',
                        ),
                        const SizedBox(height: 6),
                        _buildSafetyTip(
                          'Verify landlord\'s identity and ownership',
                        ),
                        const SizedBox(height: 6),
                        _buildSafetyTip('Get everything in writing'),
                        const SizedBox(height: 6),
                        _buildSafetyTip(
                          'Never send money without meeting in person',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to property',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _onConfirm(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm',
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
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepItem({
    required int number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.orange[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange[900],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
