import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';

class UserModel {
  final String id;
  final String fullname;
  final String? phoneNumber;
  final String email;
  final String? password;
  final String role;

  final String? profileUrl;
  final String? previousVisitorId;
  final String? idCardUrl;
  final VerifyStatus verifyStatus;
  final String? selfieUrl;

  final String? createdAt;
  final String? occupation;

  UserModel({
    required this.id,
    required this.fullname,
    this.phoneNumber,
    required this.email,
    this.password,
    required this.role,

    this.profileUrl,
    this.previousVisitorId,
    this.idCardUrl,
    required this.verifyStatus,
    this.selfieUrl,
    this.createdAt,
    this.occupation,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullname: json['fullname'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String,
      password: json['password'] as String?,
      role: json['role'] as String,
      profileUrl: json['image_profile_url'] as String?,
      previousVisitorId: json['previous_visitor_id'] as String?,
      idCardUrl: json['id_card_url'] as String?,
      verifyStatus: VerifyStatus.fromValue(json['verify_status']),
      selfieUrl: json['selfie_url'] as String?,
      createdAt: json['created_at'] as String?,
      occupation: json['occupation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'fullname': fullname,
      'phone_number': phoneNumber,
      'email': email,
      if (password != null && password!.isNotEmpty) 'password': password,
      'role': role,
      'image_profile_url': profileUrl,
      'previous_visitor_id': previousVisitorId,
      'id_card_url': idCardUrl,
      'verify_status': verifyStatus.value,
      'selfie_url': selfieUrl,
      'created_at': createdAt,
      'occupation': occupation,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }
}
