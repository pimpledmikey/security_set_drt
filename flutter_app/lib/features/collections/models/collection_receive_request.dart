class CollectionReceiveRequest {
  CollectionReceiveRequest({
    required this.hostId,
    required this.requesterNameManual,
    required this.guardHandoverId,
    required this.requesterEmailOverride,
    required this.requesterPhoneOverride,
    required this.trackingNumber,
    required this.carrierCompany,
    required this.carrierNameManual,
    required this.notes,
    required this.photos,
  });

  final int? hostId;
  final String requesterNameManual;
  final int guardHandoverId;
  final String requesterEmailOverride;
  final String requesterPhoneOverride;
  final String trackingNumber;
  final String carrierCompany;
  final String carrierNameManual;
  final String notes;
  final List<String> photos;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'host_id': hostId,
      'requester_name_manual': requesterNameManual,
      'guard_handover_id': guardHandoverId,
      'requester_email_override': requesterEmailOverride,
      'requester_phone_override': requesterPhoneOverride,
      'tracking_number': trackingNumber,
      'carrier_company': carrierCompany,
      'carrier_name_manual': carrierNameManual,
      'notes': notes,
      'photos': photos,
    };
  }
}
