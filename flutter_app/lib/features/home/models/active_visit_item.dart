class ActiveVisitItem {
  ActiveVisitItem({
    required this.id,
    required this.fullName,
    required this.hostName,
    required this.purpose,
    required this.hasAppointment,
    required this.groupSize,
    required this.observations,
    required this.enteredAt,
    required this.identifierLabel,
  });

  final int id;
  final String fullName;
  final String hostName;
  final String purpose;
  final bool hasAppointment;
  final int groupSize;
  final String observations;
  final DateTime? enteredAt;
  final String identifierLabel;

  factory ActiveVisitItem.fromJson(Map<String, dynamic> json) {
    return ActiveVisitItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
      hostName: json['host_name'] as String? ?? 'Sin anfitrion',
      purpose: json['purpose'] as String? ?? 'Sin motivo',
      hasAppointment: json['has_appointment'] as bool? ?? false,
      groupSize: (json['group_size'] as num?)?.toInt() ?? 1,
      observations: json['observations'] as String? ?? '',
      enteredAt: DateTime.tryParse(json['entered_at'] as String? ?? ''),
      identifierLabel: json['identifier_label'] as String? ?? 'Documento',
    );
  }
}
