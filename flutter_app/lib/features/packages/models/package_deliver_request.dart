class PackageDeliverRequest {
  PackageDeliverRequest({
    required this.packageId,
    required this.receivedByName,
    required this.signatureBase64,
    required this.deliveryNotes,
  });

  final int packageId;
  final String receivedByName;
  final String signatureBase64;
  final String deliveryNotes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'package_id': packageId,
      'received_by_name': receivedByName,
      'signature_base64': signatureBase64,
      'delivery_notes': deliveryNotes,
    };
  }
}
