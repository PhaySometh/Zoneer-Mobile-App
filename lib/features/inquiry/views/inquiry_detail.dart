import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/inquiry/models/inquiry_model.dart';
import 'package:zoneer_mobile/features/property/viewmodels/properties_viewmodel.dart';

class InquiryDetail extends ConsumerWidget {
  final InquiryModel inquiry;

  const InquiryDetail({super.key, required this.inquiry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(
      propertyViewModelProvider(inquiry.propertyId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inquiry Detail"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: propertyAsync.when(
                loading: () => Container(
                  height: 200,
                  color: AppColors.greyLight,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Container(
                  height: 200,
                  color: AppColors.greyLight,
                  child: Icon(
                    Icons.home_outlined,
                    color: AppColors.grey,
                    size: 48,
                  ),
                ),
                data: (property) => Image.network(
                  property.thumbnail,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.greyLight,
                    child: Icon(
                      Icons.home_outlined,
                      color: AppColors.grey,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            if (propertyAsync.asData?.value != null) ...[
              const SizedBox(height: 10),
              Text(
                propertyAsync.asData!.value.address,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 20),

            _buildDetail("Full Name", inquiry.fullname),
            const SizedBox(height: 16),

            if (inquiry.email != null) ...[
              _buildDetail("Email", inquiry.email!),
              const SizedBox(height: 16),
            ],

            _buildDetail("Phone", inquiry.phoneNumber),
            const SizedBox(height: 16),
            _buildDetail("Occupation", inquiry.occupation ?? ""),
            const SizedBox(height: 16),

            const Text(
              "Message",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(inquiry.message),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
