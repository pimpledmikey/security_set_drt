class ExtractResult {
  ExtractResult({
    required this.fullName,
    required this.documentLabel,
    required this.identifierType,
    required this.identifierValue,
    required this.birthDate,
    required this.issuer,
    required this.confidence,
    required this.requiresReview,
    required this.missingFields,
    required this.hostCandidates,
    this.rawOcrText = '',
    this.documentImageBase64 = '',
    this.documentImageMimeType = 'image/jpeg',
  });

  final String fullName;
  final String documentLabel;
  final String identifierType;
  final String identifierValue;
  final String birthDate;
  final String issuer;
  final double confidence;
  final bool requiresReview;
  final List<String> missingFields;
  final List<int> hostCandidates;
  final String rawOcrText;
  final String documentImageBase64;
  final String documentImageMimeType;

  factory ExtractResult.empty() {
    return ExtractResult(
      fullName: '',
      documentLabel: 'Identificacion',
      identifierType: 'Otro',
      identifierValue: '',
      birthDate: '',
      issuer: '',
      confidence: 0,
      requiresReview: true,
      missingFields: const ['full_name'],
      hostCandidates: const [],
      documentImageMimeType: 'image/jpeg',
    );
  }

  factory ExtractResult.fromJson(Map<String, dynamic> json) {
    return ExtractResult(
      fullName: json['full_name'] as String? ?? '',
      documentLabel: json['document_label'] as String? ?? 'Identificacion',
      identifierType: json['identifier_type'] as String? ?? 'Otro',
      identifierValue: json['identifier_value'] as String? ?? '',
      birthDate: json['birth_date'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      requiresReview: json['requires_review'] as bool? ?? true,
      missingFields: (json['missing_fields'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      hostCandidates: (json['host_candidates'] as List<dynamic>? ?? const [])
          .map((value) => int.tryParse(value.toString()) ?? 0)
          .where((value) => value > 0)
          .toList(),
      rawOcrText: json['raw_ocr_text'] as String? ?? '',
      documentImageBase64: json['document_image_base64'] as String? ?? '',
      documentImageMimeType:
          json['document_image_mime_type'] as String? ?? 'image/jpeg',
    );
  }

  ExtractResult copyWith({
    String? fullName,
    String? documentLabel,
    String? identifierType,
    String? identifierValue,
    String? birthDate,
    String? issuer,
    double? confidence,
    bool? requiresReview,
    List<String>? missingFields,
    List<int>? hostCandidates,
    String? rawOcrText,
    String? documentImageBase64,
    String? documentImageMimeType,
  }) {
    return ExtractResult(
      fullName: fullName ?? this.fullName,
      documentLabel: documentLabel ?? this.documentLabel,
      identifierType: identifierType ?? this.identifierType,
      identifierValue: identifierValue ?? this.identifierValue,
      birthDate: birthDate ?? this.birthDate,
      issuer: issuer ?? this.issuer,
      confidence: confidence ?? this.confidence,
      requiresReview: requiresReview ?? this.requiresReview,
      missingFields: missingFields ?? this.missingFields,
      hostCandidates: hostCandidates ?? this.hostCandidates,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      documentImageBase64: documentImageBase64 ?? this.documentImageBase64,
      documentImageMimeType:
          documentImageMimeType ?? this.documentImageMimeType,
    );
  }
}
