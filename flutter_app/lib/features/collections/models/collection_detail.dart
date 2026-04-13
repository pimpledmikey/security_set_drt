class CollectionDetail {
  CollectionDetail({
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
    required this.registeredAt,
    required this.deliveredAt,
    required this.photos,
    required this.delivery,
    required this.notificationStatus,
    required this.notificationMessage,
    required this.notificationSentAt,
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
  final DateTime? registeredAt;
  final DateTime? deliveredAt;
  final List<CollectionPhotoEvidence> photos;
  final CollectionDeliveryDetail? delivery;
  final String notificationStatus;
  final String notificationMessage;
  final DateTime? notificationSentAt;

  bool get isDelivered => status == 'DELIVERED';

  factory CollectionDetail.fromJson(Map<String, dynamic> json) {
    return CollectionDetail(
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
      registeredAt: DateTime.tryParse(json['registered_at'] as String? ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CollectionPhotoEvidence.fromJson)
          .toList(),
      delivery: json['delivery'] is Map<String, dynamic>
          ? CollectionDeliveryDetail.fromJson(
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

class CollectionPhotoEvidence {
  CollectionPhotoEvidence({
    required this.id,
    required this.imageBase64,
    required this.isPrimary,
    required this.sortOrder,
  });

  final int id;
  final String imageBase64;
  final bool isPrimary;
  final int sortOrder;

  factory CollectionPhotoEvidence.fromJson(Map<String, dynamic> json) {
    return CollectionPhotoEvidence(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageBase64: json['image_base64'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class CollectionDeliveryDetail {
  CollectionDeliveryDetail({
    required this.deliveredToName,
    required this.signatureBase64,
    required this.mimeType,
    required this.deliveryNotes,
    required this.deliveredAt,
  });

  final String deliveredToName;
  final String signatureBase64;
  final String mimeType;
  final String deliveryNotes;
  final DateTime? deliveredAt;

  factory CollectionDeliveryDetail.fromJson(Map<String, dynamic> json) {
    return CollectionDeliveryDetail(
      deliveredToName: json['delivered_to_name'] as String? ?? '',
      signatureBase64: json['signature_base64'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? 'image/png',
      deliveryNotes: json['delivery_notes'] as String? ?? '',
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
    );
  }
}
