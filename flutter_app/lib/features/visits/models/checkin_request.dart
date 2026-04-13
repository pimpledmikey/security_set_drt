class CheckInRequest {
  CheckInRequest({
    required this.fullName,
    required this.identifierType,
    required this.identifierValue,
    required this.documentLabel,
    required this.birthDate,
    required this.hostId,
    required this.hostNameManual,
    required this.hostEmailManual,
    required this.hostPhoneManual,
    required this.purpose,
    required this.hasAppointment,
    required this.groupSize,
    required this.observations,
    required this.documentImageBase64,
    required this.documentImageMimeType,
  });

  final String fullName;
  final String identifierType;
  final String identifierValue;
  final String documentLabel;
  final String birthDate;
  final int? hostId;
  final String hostNameManual;
  final String hostEmailManual;
  final String hostPhoneManual;
  final String purpose;
  final bool? hasAppointment;
  final int groupSize;
  final String observations;
  final String documentImageBase64;
  final String documentImageMimeType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'visitor': <String, dynamic>{
        'full_name': fullName,
        'identifier_type': identifierType,
        'identifier_value': identifierValue,
        'birth_date': birthDate,
        'document_label': documentLabel,
      },
      'host_id': hostId,
      'host_name_manual': hostNameManual,
      'host_email_manual': hostEmailManual,
      'host_phone_manual': hostPhoneManual,
      'purpose': purpose,
      'has_appointment': hasAppointment,
      'group_size': groupSize,
      'observations': observations,
      'document_image_ref': documentImageBase64,
      'document_image_mime_type': documentImageMimeType,
    };
  }
}
