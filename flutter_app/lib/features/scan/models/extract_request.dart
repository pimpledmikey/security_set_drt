class ExtractRequest {
  ExtractRequest({
    required this.deviceId,
    required this.capturedAt,
    required this.ocrText,
    required this.imageBase64,
    required this.mimeType,
  });

  final String deviceId;
  final DateTime capturedAt;
  final String ocrText;
  final String imageBase64;
  final String mimeType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_id': deviceId,
      'captured_at': capturedAt.toIso8601String(),
      'ocr_text': ocrText,
      'image_base64': imageBase64,
      'mime_type': mimeType,
    };
  }
}
