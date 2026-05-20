class FavoriteStore {
  const FavoriteStore({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.storeDescription,
    required this.storeAddress,
    required this.createdAt,
  });

  final String id;
  final String storeId;
  final String storeName;
  final String storeDescription;
  final String storeAddress;
  final DateTime createdAt;

  factory FavoriteStore.fromMap(Map<String, dynamic> map) {
    final store = Map<String, dynamic>.from(map['stores'] as Map? ?? const {});
    return FavoriteStore(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      storeName: store['name'] as String? ?? 'Untitled Store',
      storeDescription: store['description'] as String? ?? '',
      storeAddress: store['address'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
