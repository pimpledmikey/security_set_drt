import '../../home/models/active_visit_item.dart';

class VisitDetail {
  VisitDetail({
    required this.id,
    required this.fullName,
    required this.hostName,
    required this.purpose,
    required this.hasAppointment,
    required this.groupSize,
    required this.observations,
    required this.identifierLabel,
    required this.identifierValue,
    required this.birthDate,
    required this.issuer,
    required this.enteredAt,
    required this.documentImageBase64,
  });

  final int id;
  final String fullName;
  final String hostName;
  final String purpose;
  final bool hasAppointment;
  final int groupSize;
  final String observations;
  final String identifierLabel;
  final String identifierValue;
  final String birthDate;
  final String issuer;
  final DateTime? enteredAt;
  final String documentImageBase64;

  factory VisitDetail.fromJson(Map<String, dynamic> json) {
    return VisitDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
      hostName: json['host_name'] as String? ?? 'Sin anfitrion',
      purpose: json['purpose'] as String? ?? 'Visita general',
      hasAppointment: json['has_appointment'] as bool? ?? false,
      groupSize: (json['group_size'] as num?)?.toInt() ?? 1,
      observations: json['observations'] as String? ?? '',
      identifierLabel: json['identifier_label'] as String? ?? 'Documento',
      identifierValue: json['identifier_value'] as String? ?? '',
      birthDate: json['birth_date'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      enteredAt: DateTime.tryParse(json['entered_at'] as String? ?? ''),
      documentImageBase64: json['document_image_base64'] as String? ?? '',
    );
  }

  factory VisitDetail.fromActiveVisit(ActiveVisitItem item) {
    return VisitDetail(
      id: item.id,
      fullName: item.fullName,
      hostName: item.hostName,
      purpose: item.purpose,
      hasAppointment: item.hasAppointment,
      groupSize: item.groupSize,
      observations: item.observations,
      identifierLabel: item.identifierLabel,
      identifierValue: '',
      birthDate: '',
      issuer: '',
      enteredAt: item.enteredAt,
      documentImageBase64: '',
    );
  }
}
