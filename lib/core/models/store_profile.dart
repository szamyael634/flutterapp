class StoreProfile {
  const StoreProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.isOpen,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final bool isOpen;

  factory StoreProfile.fromMap(Map<String, dynamic> map) {
    return StoreProfile(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String? ?? 'Untitled Store',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      isOpen: map['is_open'] as bool? ?? true,
    );
  }
}
