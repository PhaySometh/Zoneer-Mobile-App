import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/inquiry/models/enums/inquiry_status.dart';
import 'package:zoneer_mobile/features/inquiry/models/inquiry_model.dart';
import 'package:zoneer_mobile/features/inquiry/viewmodels/inquiry_viewmodel.dart';
import 'package:zoneer_mobile/features/notification/models/enums/notification_type.dart';
import 'package:zoneer_mobile/features/notification/models/notification_model.dart';
import 'package:zoneer_mobile/features/notification/repositories/notification_repository.dart';
import 'package:zoneer_mobile/features/property/viewmodels/properties_viewmodel.dart';

class ScheduleVisitDetail extends ConsumerStatefulWidget {
  final InquiryModel inquiry;

  const ScheduleVisitDetail({super.key, required this.inquiry});

  @override
  ConsumerState<ScheduleVisitDetail> createState() =>
      _ScheduleVisitDetailState();
}

class _ScheduleVisitDetailState extends ConsumerState<ScheduleVisitDetail> {
  late InquiryStatus _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.inquiry.status;
  }

  Future<void> _updateStatus(InquiryStatus status) async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(inquiriesViewModelProvider.notifier)
        .updateStatus(widget.inquiry.id!, status);

    if (success) {
      // Invalidate related providers so lists reflect the new status immediately
      ref.invalidate(inquiriesViewModelProvider);
      ref.invalidate(scheduledVisitsProvider);
      // Send notification to the inquiry sender
      final title = status == InquiryStatus.replied
          ? 'Visit Confirmed!'
          : 'Visit Request Rejected';
      final message = status == InquiryStatus.replied
          ? 'Your visit request has been confirmed by the landlord.'
          : 'Your visit request has been rejected by the landlord.';

      await ref.read(notificationRepositoryProvider).createNotification(
            NotificationModel(
              userId: widget.inquiry.userId,
              title: title,
              message: message,
              type: NotificationType.inquiryResponse,
            ),
          );
      if (!mounted) return;
      setState(() => _currentStatus = status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == InquiryStatus.replied
                  ? 'Visit confirmed and tenant notified.'
                  : 'Visit rejected and tenant notified.',
            ),
            backgroundColor: status == InquiryStatus.replied
                ? AppColors.success
                : AppColors.error,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(
      propertyViewModelProvider(widget.inquiry.propertyId),
    );

    final isPending = _currentStatus == InquiryStatus.newStatus ||
        _currentStatus == InquiryStatus.read;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        title: const Text('Visit Request', style: TextStyle(color: Colors.black),), centerTitle: true
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image
            propertyAsync.when(
              loading: () => Container(
                height: 220,
                color: AppColors.greyLight,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Container(
                height: 220,
                color: AppColors.greyLight,
                child: const Icon(
                  Icons.home_outlined,
                  size: 56,
                  color: AppColors.grey,
                ),
              ),
              data: (property) => Stack(
                children: [
                  Image.network(
                    property.thumbnail,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: AppColors.greyLight,
                      child: const Icon(
                        Icons.home_outlined,
                        size: 56,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  // Address overlay at the bottom of the image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        property.address,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  _StatusBanner(status: _currentStatus),
                  const SizedBox(height: 20),

                  // Visitor details
                  _buildSection('Visitor Details', [
                    _buildRow(Icons.person_outline, 'Name',
                        widget.inquiry.fullname),
                    _buildRow(Icons.phone_outlined, 'Phone',
                        widget.inquiry.phoneNumber),
                    if (widget.inquiry.email != null)
                      _buildRow(Icons.email_outlined, 'Email',
                          widget.inquiry.email!),
                    if (widget.inquiry.occupation != null)
                      _buildRow(Icons.work_outline, 'Occupation',
                          widget.inquiry.occupation!),
                  ]),
                  const SizedBox(height: 20),

                  // Message
                  const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.inquiry.message,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action buttons
                  if (isPending) ...[
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _updateStatus(InquiryStatus.closed),
                                  icon: const Icon(Icons.close,
                                      color: AppColors.error),
                                  label: const Text(
                                    'Reject',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.error),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _updateStatus(InquiryStatus.replied),
                                  icon: const Icon(Icons.check,
                                      color: Colors.white),
                                  label: const Text(
                                    'Confirm',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 12),
                  ],

                  // Message button (placeholder)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _currentStatus == InquiryStatus.replied
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Messaging coming soon.'),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message Tenant'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.grey),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final InquiryStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      InquiryStatus.replied => ('Confirmed', AppColors.success,
          AppColors.success.withValues(alpha: 0.1)),
      InquiryStatus.closed => (
          'Rejected',
          AppColors.error,
          AppColors.error.withValues(alpha: 0.1)
        ),
      InquiryStatus.newStatus ||
      InquiryStatus.read =>
        ('Awaiting Response', AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      _ => ('Unknown', AppColors.grey, AppColors.greyLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(InquiryStatus status) {
    return switch (status) {
      InquiryStatus.replied => Icons.check_circle_outline,
      InquiryStatus.closed => Icons.cancel_outlined,
      InquiryStatus.newStatus || InquiryStatus.read => Icons.hourglass_empty,
      _ => Icons.info_outline,
    };
  }
}
