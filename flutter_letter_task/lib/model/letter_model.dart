import 'dart:ui';

class LetterModel {
  final String letterPath;
  final String tracingAssets;
  final String pointsJsonFile;
  final Color strokeColor;
  final Color pointColor;
  final bool needInstruction;
  final String dottedPath;
  final String indexPath;
  final String dottedImage;

  LetterModel({
    required this.dottedImage,
    required this.dottedPath,
    required this.indexPath,
    required this.letterPath,
    required this.tracingAssets,
    required this.pointsJsonFile,
    required this.strokeColor,
    required this.pointColor,
    required this.needInstruction,
  });
}
