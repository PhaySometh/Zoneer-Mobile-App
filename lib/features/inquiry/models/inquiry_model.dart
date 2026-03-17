import 'package:zoneer_mobile/features/inquiry/models/enums/inquiry_status.dart';

class InquiryModel {
  final String? id;
  final String propertyId;
  final String userId;
  final String fullname;
  final String? email;
  final String phoneNumber;
  final String? occupation;
  final String message;
  final InquiryStatus status;
  final String? createdAt;

  const InquiryModel({
    this.id,
    required this.propertyId,
    required this.userId,
    required this.fullname,
    this.email,
    required this.phoneNumber,
    this.occupation,
    required this.message,
    this.status = InquiryStatus.newStatus,
    this.createdAt,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    return InquiryModel(
      id: json['id'] as String?,
      propertyId: json['property_id'] as String,
      userId: json['user_id'] as String,
      fullname: json['fullname'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String,
      occupation: json['occupation'] as String?,
      message: json['message'] as String,
      status: InquiryStatus.fromValue(json['status']),
      createdAt: json['created_at'] as String?
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'property_id': propertyId,
      'user_id': userId,
      'fullname': fullname,
      'email': email,
      'phone_number': phoneNumber,
      'occupation': occupation,
      'message': message,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  copyWith({required InquiryStatus status}) {}
}
