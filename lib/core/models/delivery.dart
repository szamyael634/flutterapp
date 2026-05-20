enum DeliveryStatus {
  unassigned,
  assigned,
  pickedUp,
  nearDropoff,
  completed,
  failed,
}

class DeliveryRecord {
  const DeliveryRecord({
    required this.id,
    required this.orderId,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.riderId,
  });

  final String id;
  final String orderId;
  final DeliveryStatus status;
  final String pickupAddress;
  final String dropoffAddress;
  final String? riderId;

  factory DeliveryRecord.fromMap(Map<String, dynamic> map) {
    return DeliveryRecord(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      status: _statusFromValue(map['status'] as String? ?? 'unassigned'),
      pickupAddress: map['pickup_address'] as String? ?? '',
      dropoffAddress: map['dropoff_address'] as String? ?? '',
      riderId: map['rider_id'] as String?,
    );
  }

  static DeliveryStatus _statusFromValue(String value) {
    switch (value) {
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'near_dropoff':
        return DeliveryStatus.nearDropoff;
      default:
        return DeliveryStatus.values.byName(value);
    }
  }
}
