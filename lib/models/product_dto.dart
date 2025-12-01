class ProductDTO {
  final String? id;
  final String? name;
  final String? description;
  final String? categoryId;
  final String? companyId;
  final String? barcode;
  final String? sku;
  final double? basePrice;
  final String? imageUrl;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductDTO({
    this.id,
    required this.name,
    this.description,
    this.categoryId,
    required this.companyId,
    this.barcode,
    this.sku,
    required this.basePrice,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductDTO.fromJson(Map<String, dynamic> json) {
    return ProductDTO(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String?,
      companyId: json['companyId'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
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
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'companyId': companyId,
      'barcode': barcode,
      'sku': sku,
      'basePrice': basePrice,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
