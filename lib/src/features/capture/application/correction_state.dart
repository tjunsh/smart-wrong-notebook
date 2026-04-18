import 'dart:ui';

class CorrectionState {
  const CorrectionState({
    required this.imagePath,
    required this.quarterTurns,
    required this.cropRect,
  });

  final String imagePath;
  final int quarterTurns;
  final Rect cropRect;

  CorrectionState copyWith({int? quarterTurns, Rect? cropRect}) {
    return CorrectionState(
      imagePath: imagePath,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      cropRect: cropRect ?? this.cropRect,
    );
  }
}
