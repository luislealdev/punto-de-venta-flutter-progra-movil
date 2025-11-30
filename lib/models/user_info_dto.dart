class UserInfoDTO {
  final String? userId;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? photoURL;
  final String? authProvider; // 'email' o 'google'
  final String? roleId;
  final String? storeId;
  final String? address;
  final String? companyId;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserInfoDTO({
    this.userId,
    this.displayName,
    this.email,
    this.phone,
    this.photoURL,
    this.authProvider = 'email',
    required this.roleId,
    this.storeId,
    this.address,
    required this.companyId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserInfoDTO.fromJson(Map<String, dynamic> json) {
    return UserInfoDTO(
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoURL: json['photoURL'] as String?,
      authProvider: json['authProvider'] as String? ?? 'email',
      roleId: json['roleId'] as String?,
      storeId: json['storeId'] as String?,
      address: json['address'] as String?,
      companyId: json['companyId'] as String?,
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
      'email': email,
      'phone': phone,
      'photoURL': photoURL,
      'authProvider': authProvider,
      'roleId': roleId,
      'storeId': storeId,
      'address': address,
      'companyId': companyId,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
