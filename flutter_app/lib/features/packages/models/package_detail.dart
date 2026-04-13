class PackageDetail {
  PackageDetail({
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
    required this.receivedAt,
    required this.notifiedAt,
    required this.deliveredAt,
    required this.photos,
    required this.delivery,
    required this.notificationStatus,
    required this.notificationMessage,
    required this.notificationSentAt,
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
  final DateTime? receivedAt;
  final DateTime? notifiedAt;
  final DateTime? deliveredAt;
  final List<PackagePhotoEvidence> photos;
  final PackageDeliveryDetail? delivery;
  final String notificationStatus;
  final String notificationMessage;
  final DateTime? notificationSentAt;

  bool get isDelivered => status == 'DELIVERED';
  bool get isNotified => status == 'NOTIFIED' || notifiedAt != null;

  factory PackageDetail.fromJson(Map<String, dynamic> json) {
    return PackageDetail(
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
      receivedAt: DateTime.tryParse(json['received_at'] as String? ?? ''),
      notifiedAt: DateTime.tryParse(json['notified_at'] as String? ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PackagePhotoEvidence.fromJson)
          .toList(),
      delivery: json['delivery'] is Map<String, dynamic>
          ? PackageDeliveryDetail.fromJson(
              json['delivery'] as Map<String, dynamic>,
            )
          : null,
      notificationStatus: json['notification_status'] as String? ?? '',
      notificationMessage: json['notification_message'] as String? ?? '',
      notificationSentAt: DateTime.tryParse(
        json['notification_sent_at'] as String? ?? '',
      ),
    );
  }
}

class PackagePhotoEvidence {
  PackagePhotoEvidence({
    required this.id,
    required this.imageBase64,
    required this.isPrimary,
    required this.sortOrder,
  });

  final int id;
  final String imageBase64;
  final bool isPrimary;
  final int sortOrder;

  factory PackagePhotoEvidence.fromJson(Map<String, dynamic> json) {
    return PackagePhotoEvidence(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageBase64: json['image_base64'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class PackageDeliveryDetail {
  PackageDeliveryDetail({
    required this.receivedByName,
    required this.signatureBase64,
    required this.mimeType,
    required this.deliveryNotes,
    required this.deliveredAt,
  });

  final String receivedByName;
  final String signatureBase64;
  final String mimeType;
  final String deliveryNotes;
  final DateTime? deliveredAt;

  factory PackageDeliveryDetail.fromJson(Map<String, dynamic> json) {
    return PackageDeliveryDetail(
      receivedByName: json['received_by_name'] as String? ?? '',
      signatureBase64: json['signature_base64'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? 'image/png',
      deliveryNotes: json['delivery_notes'] as String? ?? '',
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
    );
  }
}
