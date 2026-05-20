class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final int sortOrder;

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Uncategorized',
      slug: map['slug'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
