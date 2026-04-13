class PackageCarrierItem {
  PackageCarrierItem({
    required this.id,
    required this.carrierName,
  });

  final int id;
  final String carrierName;

  factory PackageCarrierItem.fromJson(Map<String, dynamic> json) {
    return PackageCarrierItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      carrierName: json['carrier_name'] as String? ?? '',
    );
  }
}
