class HostItem {
  HostItem({
    required this.id,
    required this.fullName,
    required this.areaName,
    required this.email,
    required this.phoneNumber,
    this.isManual = false,
  });

  final int id;
  final String fullName;
  final String areaName;
  final String email;
  final String phoneNumber;
  final bool isManual;

  factory HostItem.manual({
    String fullName = '',
    String email = '',
    String phoneNumber = '',
  }) {
    return HostItem(
      id: 0,
      fullName: fullName,
      areaName: '',
      email: email,
      phoneNumber: phoneNumber,
      isManual: true,
    );
  }

  factory HostItem.fromJson(Map<String, dynamic> json) {
    return HostItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
      areaName: json['area_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
    );
  }
}
