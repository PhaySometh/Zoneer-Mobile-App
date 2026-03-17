import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/features/inquiry/models/enums/inquiry_status.dart';
import 'package:zoneer_mobile/features/inquiry/models/inquiry_model.dart';
import 'package:zoneer_mobile/features/inquiry/repositories/inquiry_repository.dart';

class InquiryViewmodel extends AsyncNotifier<List<InquiryModel>> {
  @override
  Future<List<InquiryModel>> build() async => [];

  Future<void> loadUserInquiries(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return ref.read(inquiryRepositoryProvider).getInquiriesByUserId(userId);
    });
  }

  Future<void> loadPropertyInquiries(String propertyId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return ref
          .read(inquiryRepositoryProvider)
          .getInquiriesByPropertyId(propertyId);
    });
  }

  Future<bool> updateStatus(String inquiryId, InquiryStatus status) async {
    try {
      await ref
          .read(inquiryRepositoryProvider)
          .updateInquiryStatus(inquiryId, status);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitInquiry(InquiryModel inquiry) async {
    state = await AsyncValue.guard(() async {
      await ref.read(inquiryRepositoryProvider).createInquiry(inquiry);

      return state.value ?? <InquiryModel>[];
    });

    return state.hasValue && !state.hasError;
  }
}

final inquiriesViewModelProvider =
    AsyncNotifierProvider<InquiryViewmodel, List<InquiryModel>>(
      InquiryViewmodel.new,
    );

final scheduledVisitsProvider =
    FutureProvider.family<List<InquiryModel>, String>((ref, landlordId) async {
      return ref
          .read(inquiryRepositoryProvider)
          .getInquiriesForLandlord(landlordId);
    });
