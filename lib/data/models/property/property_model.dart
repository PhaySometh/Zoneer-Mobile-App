import 'package:zoneer_mobile/data/models/property/enums/property_status.dart';
import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';

class PropertyModel {
  final String id;
  final double price;
  final int bedroom;
  final int bathroom;
  final double squareArea;
  final String address;
  final String? locationUrl;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String thumbnail;
  final String? type;

  final Map<String, dynamic>? securityFeatures;
  final Map<String, dynamic>? propertyFeatures;
  final Map<String, dynamic>? badgeOptions;

  final VerifyStatus? verifyStatus;
  final PropertyStatus? propertyStatus;

  final String? landlordId;
  final String? verifiedByAdmin;
  final String? name;

  PropertyModel({
    required this.id,
    required this.price,
    required this.bedroom,
    required this.bathroom,
    required this.squareArea,
    required this.address,
    this.locationUrl,
    required this.thumbnail,
    this.type,
    this.description,
    this.latitude,
    this.longitude,
    this.securityFeatures,
    this.propertyFeatures,
    this.badgeOptions,
    this.verifyStatus,
    this.propertyStatus,
    this.landlordId,
    this.verifiedByAdmin,
    this.name,
  });

  // Create object from API/Database JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      price: (json['price'] as num).toDouble(),
      bedroom: json['bedroom'] as int,
      bathroom: json['bathroom'] as int,
      squareArea: (json['square_area'] as num).toDouble(),
      address: json['address'] as String,
      locationUrl: json['location_url'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      thumbnail: json['thumbnail_url'] as String,
      type: json['type'] as String?,
      securityFeatures: json['security_features'] is Map
          ? json['security_features'] as Map<String, dynamic>?
          : null,
      propertyFeatures: json['property_features'] is Map
          ? json['property_features'] as Map<String, dynamic>?
          : null,
      badgeOptions: json['badge_options'] is Map
          ? json['badge_options'] as Map<String, dynamic>?
          : null,
      verifyStatus: json['verify_status'] != null
          ? VerifyStatus.fromValue(json['verify_status'] as String?)
          : null,
      propertyStatus: json['property_status'] != null
          ? PropertyStatus.fromValue(json['property_status'] as String?)
          : null,
      landlordId: json['landlord_id'] as String?,
      verifiedByAdmin: json['verified_by_admin'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'price': price,
      'bedroom': bedroom,
      'bathroom': bathroom,
      'square_area': squareArea,
      'address': address,
      'location_url': locationUrl,
      'latitude': latitude,
      'longitude': longitude,
      'thumbnail_url': thumbnail,
      'type': type,
      'description': description,
      'security_features': securityFeatures,
      'property_features': propertyFeatures,
      'badge_options': badgeOptions,
      'verify_status': verifyStatus?.value,
      'property_status': propertyStatus?.value,
      'landlord_id': landlordId,
      'verified_by_admin': verifiedByAdmin,
      'name': name,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  PropertyModel copyWith({
    String? id,
    double? price,
    int? bedroom,
    int? bathroom,
    double? squareArea,
    String? address,
    String? locationUrl,
    double? latitude,
    double? longitude,
    String? description,
    String? thumbnail,
    String? type,
    Map<String, dynamic>? securityFeatures,
    Map<String, dynamic>? propertyFeatures,
    Map<String, dynamic>? badgeOptions,
    VerifyStatus? verifyStatus,
    PropertyStatus? propertyStatus,
    String? landlordId,
    String? verifiedByAdmin,
    String? name,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      price: price ?? this.price,
      bedroom: bedroom ?? this.bedroom,
      bathroom: bathroom ?? this.bathroom,
      squareArea: squareArea ?? this.squareArea,
      address: address ?? this.address,
      locationUrl: locationUrl ?? this.locationUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      type: type ?? this.type,
      securityFeatures: securityFeatures ?? this.securityFeatures,
      propertyFeatures: propertyFeatures ?? this.propertyFeatures,
      badgeOptions: badgeOptions ?? this.badgeOptions,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      landlordId: landlordId ?? this.landlordId,
      verifiedByAdmin: verifiedByAdmin ?? this.verifiedByAdmin,
      name: name ?? this.name,
    );
  }
}
