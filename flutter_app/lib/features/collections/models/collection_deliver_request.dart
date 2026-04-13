class CollectionDeliverRequest {
  CollectionDeliverRequest({
    required this.collectionId,
    required this.deliveredToName,
    required this.signatureBase64,
    required this.deliveryNotes,
  });

  final int collectionId;
  final String deliveredToName;
  final String signatureBase64;
  final String deliveryNotes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'collection_id': collectionId,
      'delivered_to_name': deliveredToName,
      'signature_base64': signatureBase64,
      'delivery_notes': deliveryNotes,
    };
  }
}
