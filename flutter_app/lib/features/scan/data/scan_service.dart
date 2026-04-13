import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../../core/config/api_endpoints.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/validators.dart';
import '../models/extract_request.dart';
import '../models/extract_result.dart';
import '../models/scan_frame_config.dart';
import 'ocr_service.dart';

class ScanService {
  ScanService({required ApiClient apiClient, required OcrService ocrService})
      : _apiClient = apiClient,
        _ocrService = ocrService;

  final ApiClient _apiClient;
  final OcrService _ocrService;

  Future<ApiResult<ExtractResult>> processImage(
    String imagePath, {
    required ScanFrameConfig frameConfig,
  }) async {
    final preparedImage = await _prepareImage(imagePath, frameConfig);

    try {
      final ocrText = await _ocrService.extractTextFromImagePath(
        preparedImage.ocrPath,
      );
      final imageBase64 = base64Encode(preparedImage.imageBytes);
      final localFallback = _fallbackFromOcrText(
        ocrText: ocrText,
        imageBase64: imageBase64,
        mimeType: preparedImage.mimeType,
      );
      final shouldStartWithImage =
          ocrText.trim().isEmpty || !_hasMinimumIdentity(localFallback);

      final primaryResult = await _requestExtraction(
        ocrText: ocrText,
        imageBase64: shouldStartWithImage ? imageBase64 : '',
        mimeType: preparedImage.mimeType,
      );

      final normalizedPrimary = _extractServerResult(
        primaryResult,
        ocrText: ocrText,
        imageBase64: imageBase64,
      );
      if (normalizedPrimary != null) {
        final needsImageRetry =
            !shouldStartWithImage && _needsImageRetry(normalizedPrimary);
        if (!needsImageRetry) {
          return ApiResult.success(normalizedPrimary);
        }

        final imageRetry = await _requestExtraction(
          ocrText: ocrText,
          imageBase64: imageBase64,
          mimeType: preparedImage.mimeType,
        );
        final normalizedRetry = _extractServerResult(
          imageRetry,
          ocrText: ocrText,
          imageBase64: imageBase64,
        );
        if (normalizedRetry != null) {
          return ApiResult.success(normalizedRetry);
        }
      }

      return ApiResult.success(localFallback);
    } finally {
      await preparedImage.dispose();
    }
  }

  Future<_PreparedScanImage> _prepareImage(
    String imagePath,
    ScanFrameConfig frameConfig,
  ) async {
    final originalFile = File(imagePath);
    final originalBytes = await originalFile.readAsBytes();
    final croppedBytes = await _cropFocusedDocument(originalBytes, frameConfig);
    if (croppedBytes == null || croppedBytes.isEmpty) {
      return _PreparedScanImage(
        ocrPath: imagePath,
        imageBytes: originalBytes,
        tempFilePath: null,
        mimeType: 'image/jpeg',
      );
    }

    final tempFile = File(
      '${originalFile.parent.path}/ra_focus_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(croppedBytes);
    return _PreparedScanImage(
      ocrPath: tempFile.path,
      imageBytes: croppedBytes,
      tempFilePath: tempFile.path,
      mimeType: 'image/png',
    );
  }

  Future<Uint8List?> _cropFocusedDocument(
    Uint8List imageBytes,
    ScanFrameConfig frameConfig,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final cropRect = _buildCropRect(
        width: image.width.toDouble(),
        height: image.height.toDouble(),
        frameConfig: frameConfig,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final outputSize = ui.Size(cropRect.width, cropRect.height);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
      canvas.drawImageRect(image, cropRect, ui.Offset.zero & outputSize, paint);

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        outputSize.width.round(),
        outputSize.height.round(),
      );
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  ui.Rect _buildCropRect({
    required double width,
    required double height,
    required ScanFrameConfig frameConfig,
  }) {
    final targetAspect = frameConfig.aspectRatio;
    double horizontalPadding;
    double verticalPadding;

    if (frameConfig.isVertical) {
      horizontalPadding =
          frameConfig.preset == ScanDocumentPreset.passport ? 0.08 : 0.1;
      verticalPadding = 0.028;
    } else {
      horizontalPadding = 0.03;
      verticalPadding =
          frameConfig.preset == ScanDocumentPreset.credential ? 0.08 : 0.075;
    }

    var cropWidth = width * (1 - (horizontalPadding * 2));
    var cropHeight = cropWidth / targetAspect;
    final maxCropHeight = height * (1 - (verticalPadding * 2));

    if (cropHeight > maxCropHeight) {
      cropHeight = maxCropHeight;
      cropWidth = cropHeight * targetAspect;
    }

    if (cropWidth > width) {
      cropWidth = width;
      cropHeight = cropWidth / targetAspect;
    }
    if (cropHeight > height) {
      cropHeight = height;
      cropWidth = cropHeight * targetAspect;
    }

    final left = (width - cropWidth) / 2;
    final top = (height - cropHeight) / 2;

    return ui.Rect.fromLTWH(left, top, cropWidth, cropHeight);
  }

  Future<ApiResult<Map<String, dynamic>>> _requestExtraction({
    required String ocrText,
    required String imageBase64,
    required String mimeType,
  }) async {
    final request = ExtractRequest(
      deviceId: Env.deviceId,
      capturedAt: DateTime.now(),
      ocrText: ocrText,
      imageBase64: imageBase64,
      mimeType: mimeType,
    );

    final apiResult = await _apiClient.post(
      ApiEndpoints.extract,
      data: request.toJson(),
    );
    if (!apiResult.isSuccess) {
      return ApiResult.failure(apiResult.errorMessage);
    }

    final payload = apiResult.data?['data'] as Map<String, dynamic>? ??
        apiResult.data ??
        <String, dynamic>{};
    return ApiResult.success(payload);
  }

  ExtractResult? _extractServerResult(
    ApiResult<Map<String, dynamic>> apiResult, {
    required String ocrText,
    required String imageBase64,
  }) {
    if (!apiResult.isSuccess || apiResult.data == null) {
      return null;
    }

    final extracted = ExtractResult.fromJson(
      apiResult.data!,
    ).copyWith(
      rawOcrText: ocrText,
      documentImageBase64: imageBase64,
      documentImageMimeType:
          apiResult.data?['document_image_mime_type'] as String? ??
              resultMimeTypeFromImageBase64(imageBase64),
    );
    return _normalizeExtractResult(extracted, ocrText: ocrText);
  }

  bool _hasMinimumIdentity(ExtractResult result) {
    return Validators.hasDetectedName(fullName: result.fullName);
  }

  bool _needsImageRetry(ExtractResult result) {
    if (!Validators.hasDetectedName(fullName: result.fullName)) {
      return true;
    }

    return result.confidence > 0 && result.confidence < 0.5;
  }

  ExtractResult _fallbackFromOcrText({
    required String ocrText,
    required String imageBase64,
    required String mimeType,
  }) {
    final lines = _linesFromOcr(ocrText);
    final fullName = _bestNameCandidate(lines);
    final identifier = _findIdentifier(lines);

    return ExtractResult(
      fullName: fullName,
      documentLabel: _guessDocumentLabel(lines),
      identifierType: identifier.$1,
      identifierValue: identifier.$2,
      birthDate: '',
      issuer: '',
      confidence: fullName.isNotEmpty ? 0.88 : 0.42,
      requiresReview: fullName.isEmpty,
      missingFields: [
        if (fullName.isEmpty) 'full_name',
      ],
      hostCandidates: const [],
      rawOcrText: ocrText,
      documentImageBase64: imageBase64,
      documentImageMimeType: mimeType,
    );
  }

  String resultMimeTypeFromImageBase64(String imageBase64) {
    return imageBase64.isEmpty ? 'image/jpeg' : 'image/png';
  }

  ExtractResult _normalizeExtractResult(
    ExtractResult result, {
    required String ocrText,
  }) {
    final lines = _linesFromOcr(ocrText);
    final guessedName = _bestNameCandidate(lines);
    final guessedIdentifier = _findIdentifier(lines);
    final guessedDocumentLabel = _guessDocumentLabel(lines);

    final currentName = result.fullName.trim();
    final normalizedName =
        (!_looksLikeName(currentName) && guessedName.isNotEmpty)
            ? guessedName
            : currentName;

    final normalizedIdentifier = result.identifierValue.trim().isEmpty
        ? guessedIdentifier.$2
        : result.identifierValue.trim();
    final normalizedIdentifierType =
        result.identifierType.trim().isEmpty || result.identifierType == 'Otro'
            ? guessedIdentifier.$1
            : result.identifierType.trim();
    final normalizedDocumentLabel = () {
      final currentLabel = result.documentLabel.trim();
      if (currentLabel.isEmpty ||
          currentLabel == 'Documento' ||
          currentLabel == 'Documento capturado' ||
          currentLabel == 'Identificacion') {
        return guessedDocumentLabel;
      }
      return currentLabel;
    }();

    final missingFields = <String>[
      if (normalizedName.isEmpty) 'full_name',
    ];

    final shouldReview = normalizedName.isEmpty ||
        (result.confidence > 0 && result.confidence < 0.5);

    return result.copyWith(
      fullName: normalizedName,
      documentLabel: normalizedDocumentLabel,
      identifierType: normalizedIdentifierType,
      identifierValue: normalizedIdentifier,
      requiresReview: shouldReview,
      missingFields: missingFields,
    );
  }

  List<String> _linesFromOcr(String ocrText) {
    return ocrText
        .split('\n')
        .map(_cleanLine)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _cleanLine(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _looksLikeName(String value) {
    final upper = value.toUpperCase();
    final words = upper.split(RegExp(r'\s+')).where((word) => word.length > 1);
    return words.length >= 2 && !_looksInstitutional(upper);
  }

  bool _looksInstitutional(String value) {
    final upper = value.toUpperCase();
    return upper.contains('REPUBLICA') ||
        upper.contains('ESTADOS') ||
        upper.contains('UNIDOS') ||
        upper.contains('MEXICANOS') ||
        upper.contains('MEXICANA') ||
        upper.contains('GOBIERNO') ||
        upper.contains('ADDRESS') ||
        upper.contains('INSTITUTO') ||
        upper.contains('SECRETARIA') ||
        upper.contains('LICENCIA') ||
        upper.contains('PASAPORTE') ||
        upper.contains('PASSPORT') ||
        upper.contains('ELECTOR') ||
        upper.contains('NACIONAL') ||
        upper.contains('DOMICILIO') ||
        upper.contains('DRIVER') ||
        upper.contains('LICENSE') ||
        upper.contains('CREDENCIAL') ||
        upper.contains('CORPORATIVA') ||
        upper.contains('GAFETE') ||
        upper.contains('BADGE') ||
        upper.contains('EMPLEADO') ||
        upper.contains('EMPLOYEE');
  }

  String _bestNameCandidate(List<String> lines) {
    for (var index = 0; index < lines.length; index++) {
      final rawLine = lines[index];
      final labelMatch = RegExp(
        r'^(NOMBRE|NAME|APELLIDOS?|SURNAMES?)\s*:?\s*(.*)$',
        caseSensitive: false,
      ).firstMatch(rawLine);
      if (labelMatch != null) {
        var candidate = _normalizeNameCandidate(labelMatch.group(2) ?? '');
        if (candidate.isEmpty && index + 1 < lines.length) {
          candidate = _normalizeNameCandidate(lines[index + 1]);
        }
        if (candidate.isNotEmpty &&
            index + 1 < lines.length &&
            _looksLikeName('$candidate ${lines[index + 1]}')) {
          candidate = _normalizeNameCandidate('$candidate ${lines[index + 1]}');
        }
        if (_looksLikeName(candidate)) {
          return candidate;
        }
      }
    }

    final stackedCandidate = _bestStackedNameCandidate(lines);
    if (stackedCandidate.isNotEmpty) {
      return stackedCandidate;
    }

    var best = '';
    var bestScore = -1;

    for (final rawLine in lines) {
      final line = _normalizeNameCandidate(rawLine);
      if (!_looksLikeName(line)) {
        continue;
      }

      final words = line.split(' ').where((part) => part.isNotEmpty).toList();
      var score = 0;
      if (words.length >= 2 && words.length <= 4) {
        score += 3;
      }
      if (rawLine.contains(':')) {
        score += 2;
      }
      if (!RegExp(r'\d').hasMatch(line)) {
        score += 1;
      }
      if (line.length >= 10 && line.length <= 42) {
        score += 2;
      }
      if (RegExp(r'\b(DE|DEL|LA|LAS|LOS)\b', caseSensitive: false)
          .hasMatch(line)) {
        score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        best = line;
      }
    }

    return best;
  }

  String _bestStackedNameCandidate(List<String> lines) {
    var best = '';
    var bestScore = -1;

    for (var start = 0; start < lines.length; start++) {
      final pieces = <String>[];
      for (var index = start;
          index < lines.length && index < start + 4;
          index++) {
        final piece = _normalizeNameCandidate(lines[index]);
        if (!_looksLikeNamePiece(piece)) {
          break;
        }

        pieces.add(piece);
        if (pieces.length < 2) {
          continue;
        }

        final candidate = _composeNameFromPieces(pieces);
        if (!_looksLikeName(candidate)) {
          continue;
        }

        var score = 0;
        final words = candidate
            .split(' ')
            .where((part) => part.trim().isNotEmpty)
            .toList();
        if (words.length >= 3 && words.length <= 4) {
          score += 4;
        }
        if (pieces.length >= 2) {
          score += 2;
        }
        if (!RegExp(r'\d').hasMatch(candidate)) {
          score += 1;
        }

        if (score > bestScore) {
          bestScore = score;
          best = candidate;
        }
      }
    }

    return best;
  }

  bool _looksLikeNamePiece(String value) {
    final normalized = _normalizeNameCandidate(value);
    if (normalized.isEmpty || RegExp(r'\d').hasMatch(normalized)) {
      return false;
    }

    final words =
        normalized.split(' ').where((part) => part.trim().isNotEmpty).toList();
    if (words.isEmpty || words.length > 2) {
      return false;
    }

    return words.every((word) => word.length >= 2 && word.length <= 18) &&
        !_looksInstitutional(normalized);
  }

  String _composeNameFromPieces(List<String> pieces) {
    final normalizedPieces = pieces
        .map(_normalizeNameCandidate)
        .where((piece) => piece.isNotEmpty)
        .toList();
    if (normalizedPieces.length == 3) {
      final firstWords = normalizedPieces[0]
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .toList();
      final secondWords = normalizedPieces[1]
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .toList();
      final thirdWords = normalizedPieces[2]
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .toList();

      if (firstWords.length == 1 &&
          secondWords.length == 1 &&
          thirdWords.isNotEmpty) {
        return _normalizeNameCandidate(
          '${normalizedPieces[2]} ${normalizedPieces[0]} ${normalizedPieces[1]}',
        );
      }
    }

    return _normalizeNameCandidate(normalizedPieces.join(' '));
  }

  String _normalizeNameCandidate(String value) {
    return value
        .replaceAll(
          RegExp(
            r'^(NOMBRE|NAME|APELLIDOS?|SURNAMES?)\s*:?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  (String, String) _findIdentifier(List<String> lines) {
    final contextualPatterns = <(String, RegExp)>[
      (
        'Licencia',
        RegExp(
          r'(?:LICENCIA|LICENSE|DRIVER LICENSE|DL)[^A-Z0-9]{0,12}((?=[A-Z0-9-]*\d)[A-Z0-9-]{5,20})',
        ),
      ),
      (
        'Credencial',
        RegExp(
          r'(?:CREDENCIAL|CORPORATIVA|GAFETE|BADGE|EMPLEADO|EMPLOYEE)[^A-Z0-9]{0,12}((?=[A-Z0-9-]*\d)[A-Z0-9-]{4,20})',
        ),
      ),
      (
        'Folio',
        RegExp(
          r'(?:FOLIO|DOCUMENTO|DOC)[^A-Z0-9]{0,12}((?=[A-Z0-9-]*\d)[A-Z0-9-]{4,20})',
        ),
      ),
    ];
    final patterns = <(String, RegExp)>[
      ('CURP', RegExp(r'\b[A-Z][AEIOUX][A-Z]{2}\d{6}[HM][A-Z]{5}[A-Z0-9]\d\b')),
      ('RFC', RegExp(r'\b[A-Z&Ñ]{3,4}\d{6}[A-Z0-9]{3}\b')),
      ('Pasaporte', RegExp(r'\b(?=[A-Z0-9]*\d)[A-Z0-9]{6,12}\b')),
      ('Folio', RegExp(r'\b\d{6,18}\b')),
    ];

    for (final line in lines) {
      final normalizedLine = line.toUpperCase();
      for (final pattern in contextualPatterns) {
        final match = pattern.$2.firstMatch(normalizedLine);
        if (match != null) {
          return (pattern.$1, match.group(1) ?? '');
        }
      }
      for (final pattern in patterns) {
        final match = pattern.$2.firstMatch(normalizedLine);
        if (match != null) {
          return (pattern.$1, match.group(0) ?? '');
        }
      }
    }
    return ('Otro', '');
  }

  String _guessDocumentLabel(List<String> lines) {
    final combined = lines.join(' ').toUpperCase();
    if (combined.contains('LICENCIA') || combined.contains('DRIVER LICENSE')) {
      return 'Licencia';
    }
    if (combined.contains('PASAPORTE') || combined.contains('PASSPORT')) {
      return 'Pasaporte';
    }
    if (combined.contains('CREDENCIAL') ||
        combined.contains('CORPORATIVA') ||
        combined.contains('GAFETE') ||
        combined.contains('BADGE')) {
      return 'Credencial corporativa';
    }
    if (combined.contains('INE') ||
        combined.contains('ELECTOR') ||
        combined.contains('IDENTIFICACION')) {
      return 'Identificacion oficial';
    }
    return 'Identificacion capturada';
  }
}

class _PreparedScanImage {
  const _PreparedScanImage({
    required this.ocrPath,
    required this.imageBytes,
    required this.tempFilePath,
    required this.mimeType,
  });

  final String ocrPath;
  final Uint8List imageBytes;
  final String? tempFilePath;
  final String mimeType;

  Future<void> dispose() async {
    if (tempFilePath == null) {
      return;
    }
    final file = File(tempFilePath!);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
