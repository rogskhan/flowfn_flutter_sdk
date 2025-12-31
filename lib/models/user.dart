class User {
  final String id;
  final String email;
  final String? name;
  final bool isActive;
  final bool isDeleted;
  final bool? isAdmin;
  final bool? isEmailVerified;
  final String? lastLoginAt;
  final String? createdAt;
  final String? updatedAt;
  final bool? processingRestricted;
  final String? processingRestrictedAt;
  final bool? processingObjected;
  final String? processingObjectedAt;
  final String? objectionReason;
  final String? objectionProcessingType;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.isActive,
    required this.isDeleted,
    this.isAdmin,
    this.isEmailVerified,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
    this.processingRestricted,
    this.processingRestrictedAt,
    this.processingObjected,
    this.processingObjectedAt,
    this.objectionReason,
    this.objectionProcessingType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool?,
      isEmailVerified: json['is_email_verified'] as bool?,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      processingRestricted: json['processing_restricted'] as bool?,
      processingRestrictedAt: json['processing_restricted_at'] as String?,
      processingObjected: json['processing_objected'] as bool?,
      processingObjectedAt: json['processing_objected_at'] as String?,
      objectionReason: json['objection_reason'] as String?,
      objectionProcessingType: json['objection_processing_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      if (name != null) 'name': name,
      'is_active': isActive,
      'is_deleted': isDeleted,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (isEmailVerified != null) 'is_email_verified': isEmailVerified,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (processingRestricted != null) 'processing_restricted': processingRestricted,
      if (processingRestrictedAt != null) 'processing_restricted_at': processingRestrictedAt,
      if (processingObjected != null) 'processing_objected': processingObjected,
      if (processingObjectedAt != null) 'processing_objected_at': processingObjectedAt,
      if (objectionReason != null) 'objection_reason': objectionReason,
      if (objectionProcessingType != null) 'objection_processing_type': objectionProcessingType,
    };
  }
}

