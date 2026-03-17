import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/inquiry/models/inquiry_model.dart';
import 'package:zoneer_mobile/features/inquiry/views/inquiry_detail.dart';
import 'package:zoneer_mobile/features/property/viewmodels/properties_viewmodel.dart';

class InquiryCard extends ConsumerWidget {
  final InquiryModel inquiry;

  const InquiryCard({super.key, required this.inquiry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(
      propertyViewModelProvider(inquiry.propertyId),
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InquiryDetail(inquiry: inquiry),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: propertyAsync.when(
                  loading: () => Container(
                    width: 95,
                    height: 95,
                    color: AppColors.greyLight,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => Container(
                    width: 95,
                    height: 95,
                    color: AppColors.greyLight,
                    child: Icon(
                      Icons.home_outlined,
                      color: AppColors.grey,
                      size: 40,
                    ),
                  ),
                  data: (property) => Image.network(
                    property.thumbnail,
                    width: 95,
                    height: 95,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 95,
                      height: 95,
                      color: AppColors.greyLight,
                      child: Icon(
                        Icons.home_outlined,
                        color: AppColors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.fullname,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (propertyAsync.asData?.value != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        propertyAsync.asData!.value.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      inquiry.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InquiryDetail(inquiry: inquiry),
                          ),
                        ),
                        label: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
