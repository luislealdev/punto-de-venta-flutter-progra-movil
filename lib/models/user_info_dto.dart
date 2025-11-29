class UserInfoDTO {
  final String? userId;
  final String? displayName;
  final String? phone;
  final String? roleId;
  final String? storeId;
  final String? address;
  final String? companyId;
  final String? photoURL;
  final String? authProvider;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserInfoDTO({
    this.userId,
    this.displayName,
    this.phone,
    required this.roleId,
    this.storeId,
    this.address,
    required this.companyId,
    this.photoURL,
    this.authProvider = 'email',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserInfoDTO.fromJson(Map<String, dynamic> json) {
    return UserInfoDTO(
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String?,
      phone: json['phone'] as String?,
      roleId: json['roleId'] as String?,
      storeId: json['storeId'] as String?,
      address: json['address'] as String?,
      companyId: json['companyId'] as String?,
      photoURL: json['photoURL'] as String?,
      authProvider: json['authProvider'] as String? ?? 'email',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'phone': phone,
      'roleId': roleId,
      'storeId': storeId,
      'address': address,
      'companyId': companyId,
      'photoURL': photoURL,
      'authProvider': authProvider,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
