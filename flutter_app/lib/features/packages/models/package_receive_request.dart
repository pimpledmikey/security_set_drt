class PackageReceiveRequest {
  PackageReceiveRequest({
    required this.hostId,
    required this.recipientNameManual,
    required this.guardReceivedId,
    required this.recipientEmailOverride,
    required this.recipientPhoneOverride,
    required this.trackingNumber,
    required this.carrierCompany,
    required this.carrierNameManual,
    required this.packageCount,
    required this.notes,
    required this.photos,
  });

  final int? hostId;
  final String recipientNameManual;
  final int guardReceivedId;
  final String recipientEmailOverride;
  final String recipientPhoneOverride;
  final String trackingNumber;
  final String carrierCompany;
  final String carrierNameManual;
  final int packageCount;
  final String notes;
  final List<String> photos;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'host_id': hostId,
      'recipient_name_manual': recipientNameManual,
      'guard_received_id': guardReceivedId,
      'recipient_email_override': recipientEmailOverride,
      'recipient_phone_override': recipientPhoneOverride,
      'tracking_number': trackingNumber,
      'carrier_company': carrierCompany,
      'carrier_name_manual': carrierNameManual,
      'package_count': packageCount,
      'notes': notes,
      'photos': photos,
    };
  }
}
