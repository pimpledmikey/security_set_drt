enum ScanDocumentPreset { credential, passport, other }

enum ScanFrameOrientation { auto, horizontal, vertical }

class ScanFrameConfig {
  const ScanFrameConfig({
    required this.preset,
    required this.orientation,
  });

  final ScanDocumentPreset preset;
  final ScanFrameOrientation orientation;

  ScanFrameOrientation get effectiveOrientation {
    if (orientation != ScanFrameOrientation.auto) {
      return orientation;
    }
    return preset == ScanDocumentPreset.passport
        ? ScanFrameOrientation.vertical
        : ScanFrameOrientation.horizontal;
  }

  bool get isVertical => effectiveOrientation == ScanFrameOrientation.vertical;

  double get aspectRatio {
    if (isVertical) {
      switch (preset) {
        case ScanDocumentPreset.credential:
          return 0.72;
        case ScanDocumentPreset.passport:
          return 0.72;
        case ScanDocumentPreset.other:
          return 0.78;
      }
    }

    switch (preset) {
      case ScanDocumentPreset.credential:
        return 1.58;
      case ScanDocumentPreset.passport:
        return 1.42;
      case ScanDocumentPreset.other:
        return 1.48;
    }
  }

  String get presetLabel {
    switch (preset) {
      case ScanDocumentPreset.credential:
        return 'Licencia / Credencial';
      case ScanDocumentPreset.passport:
        return 'Pasaporte';
      case ScanDocumentPreset.other:
        return 'Otro';
    }
  }
}
