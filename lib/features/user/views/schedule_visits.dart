import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/inquiry/models/enums/inquiry_status.dart';
import 'package:zoneer_mobile/features/inquiry/models/inquiry_model.dart';
import 'package:zoneer_mobile/features/inquiry/viewmodels/inquiry_viewmodel.dart';
import 'package:zoneer_mobile/features/inquiry/views/schedule_visit_detail.dart';
import 'package:zoneer_mobile/features/property/viewmodels/properties_viewmodel.dart';

class ScheduleVisits extends ConsumerWidget {
  const ScheduleVisits({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final visitsAsync = ref.watch(scheduledVisitsProvider(authUser.id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Scheduled Visits', style: TextStyle(color: Colors.black),),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(scheduledVisitsProvider(authUser.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (inquiries) {
          if (inquiries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 64, color: AppColors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No visit requests yet.',
                    style: TextStyle(color: AppColors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // Pending first, then confirmed, then others
          final pending = inquiries
              .where((i) =>
                  i.status == InquiryStatus.newStatus ||
                  i.status == InquiryStatus.read)
              .toList();
          final confirmed = inquiries
              .where((i) => i.status == InquiryStatus.replied)
              .toList();
          final others = inquiries
              .where((i) =>
                  i.status != InquiryStatus.newStatus &&
                  i.status != InquiryStatus.read &&
                  i.status != InquiryStatus.replied)
              .toList();

          final sorted = [...pending, ...confirmed, ...others];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _VisitRequestCard(inquiry: sorted[index]),
          );
        },
      ),
    );
  }
}

class _VisitRequestCard extends ConsumerWidget {
  final InquiryModel inquiry;

  const _VisitRequestCard({required this.inquiry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(
      propertyViewModelProvider(inquiry.propertyId),
    );

    final (statusLabel, statusColor) = _statusStyle(inquiry.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScheduleVisitDetail(inquiry: inquiry),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored status accent bar on the left
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar with visitor initial
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Text(
                  inquiry.fullname.isNotEmpty
                      ? inquiry.fullname[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name, address, message
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inquiry.fullname,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (propertyAsync.asData?.value != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: AppColors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                propertyAsync.asData!.value.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        inquiry.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusStyle(InquiryStatus status) {
    return switch (status) {
      InquiryStatus.replied => ('Confirmed', AppColors.success),
      InquiryStatus.closed => ('Rejected', AppColors.error),
      InquiryStatus.newStatus => ('New', AppColors.info),
      InquiryStatus.read => ('Pending', AppColors.warning),
      _ => ('Unknown', AppColors.grey),
    };
  }
}
