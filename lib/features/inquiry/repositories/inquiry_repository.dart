import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/services/supabase_service.dart';
import 'package:zoneer_mobile/features/inquiry/models/enums/inquiry_status.dart';
import 'package:zoneer_mobile/features/inquiry/models/inquiry_model.dart';

class InquiryRepository {
  final SupabaseService _supabase;

  InquiryRepository(this._supabase);

  Future<List<InquiryModel>> getInquiriesByUserId(String userId) async {
    final response = await _supabase
        .from('inquiries')
        .select()
        .eq('user_id', userId);
    return (response as List).map((e) => InquiryModel.fromJson(e)).toList();
  }

  Future<InquiryModel> createInquiry(InquiryModel inquiry) async {
    final response = await _supabase
        .from('inquiries')
        .insert(inquiry.toJson())
        .select()
        .single();
    return InquiryModel.fromJson(response);
  }

  Future<InquiryModel> updateInquiry(InquiryModel inquiry) async {
    final response = await _supabase
        .from('inquiries')
        .update(inquiry.toJson())
        .eq('id', inquiry.id!)
        .select()
        .single();

    return InquiryModel.fromJson(response);
  }

  Future<List<InquiryModel>> getInquiriesByPropertyId(String propertyId) async {
    final response = await _supabase
        .from('inquiries')
        .select()
        .eq('property_id', propertyId);
    return (response as List).map((e) => InquiryModel.fromJson(e)).toList();
  }

  Future<List<InquiryModel>> getInquiriesForLandlord(String landlordId) async {
    final propertyResponse = await _supabase
        .from('properties')
        .select('id')
        .eq('landlord_id', landlordId);

    final propertyIds = (propertyResponse as List)
        .map((e) => e['id'] as String)
        .toList();

    if (propertyIds.isEmpty) return [];

    final response = await _supabase
        .from('inquiries')
        .select()
        .inFilter('property_id', propertyIds);

    return (response as List).map((e) => InquiryModel.fromJson(e)).toList();
  }

  Future<InquiryModel> updateInquiryStatus(
    String inquiryId,
    InquiryStatus status,
  ) async {
    final response = await _supabase
        .from('inquiries')
        .update({'status': status.value})
        .eq('id', inquiryId)
        .select()
        .single();
    return InquiryModel.fromJson(response);
  }

  Future<InquiryModel> deleteInquiry(String inquiryId) async {
    final response = await _supabase
        .from('inquiries')
        .delete()
        .eq('id', inquiryId)
        .select()
        .single();

    return InquiryModel.fromJson(response);
  }
}

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return InquiryRepository(supabase);
});
