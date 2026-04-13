class ActiveCollectionItem {
  ActiveCollectionItem({
    required this.id,
    required this.requesterName,
    required this.requesterEmail,
    required this.requesterPhone,
    required this.hostName,
    required this.guardHandoverName,
    required this.trackingNumber,
    required this.carrierCompany,
    required this.notes,
    required this.status,
    required this.photoCount,
    required this.registeredAt,
    required this.deliveredAt,
  });

  final int id;
  final String requesterName;
  final String requesterEmail;
  final String requesterPhone;
  final String hostName;
  final String guardHandoverName;
  final String trackingNumber;
  final String carrierCompany;
  final String notes;
  final String status;
  final int photoCount;
  final DateTime? registeredAt;
  final DateTime? deliveredAt;

  bool get isDelivered => status == 'DELIVERED';

  factory ActiveCollectionItem.fromJson(Map<String, dynamic> json) {
    return ActiveCollectionItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      requesterName: json['requester_name'] as String? ?? '',
      requesterEmail: json['requester_email'] as String? ?? '',
      requesterPhone: json['requester_phone'] as String? ?? '',
      hostName: json['host_name'] as String? ?? '',
      guardHandoverName: json['guard_handover_name'] as String? ?? '',
      trackingNumber: json['tracking_number'] as String? ?? '',
      carrierCompany: json['carrier_company'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'REGISTERED',
      photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
      registeredAt: DateTime.tryParse(json['registered_at'] as String? ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
    );
  }
}
