class ActivePackageItem {
  ActivePackageItem({
    required this.id,
    required this.recipientName,
    required this.recipientEmail,
    required this.recipientPhone,
    required this.hostName,
    required this.guardReceivedName,
    required this.trackingNumber,
    required this.carrierCompany,
    required this.packageCount,
    required this.notes,
    required this.status,
    required this.photoCount,
    required this.receivedAt,
    required this.notifiedAt,
    required this.deliveredAt,
  });

  final int id;
  final String recipientName;
  final String recipientEmail;
  final String recipientPhone;
  final String hostName;
  final String guardReceivedName;
  final String trackingNumber;
  final String carrierCompany;
  final int packageCount;
  final String notes;
  final String status;
  final int photoCount;
  final DateTime? receivedAt;
  final DateTime? notifiedAt;
  final DateTime? deliveredAt;

  bool get isDelivered => status == 'DELIVERED';
  bool get isNotified => status == 'NOTIFIED' || notifiedAt != null;

  factory ActivePackageItem.fromJson(Map<String, dynamic> json) {
    return ActivePackageItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      recipientName: json['recipient_name'] as String? ?? '',
      recipientEmail: json['recipient_email'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
      hostName: json['host_name'] as String? ?? '',
      guardReceivedName: json['guard_received_name'] as String? ?? '',
      trackingNumber: json['tracking_number'] as String? ?? '',
      carrierCompany: json['carrier_company'] as String? ?? '',
      packageCount: (json['package_count'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'RECEIVED',
      photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
      receivedAt: DateTime.tryParse(json['received_at'] as String? ?? ''),
      notifiedAt: DateTime.tryParse(json['notified_at'] as String? ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
    );
  }
}
