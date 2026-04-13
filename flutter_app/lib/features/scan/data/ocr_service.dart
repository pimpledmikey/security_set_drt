import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<String> extractTextFromImagePath(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final text = await _recognizer.processImage(inputImage);
    return text.text.trim();
  }

  void dispose() {
    _recognizer.close();
  }
}
