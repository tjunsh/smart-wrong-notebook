import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/features/capture/application/correction_state.dart';
import 'package:smart_wrong_notebook/src/features/capture/application/image_correction_service.dart';

void main() {
  test('rotate90 updates quarter turns and preserves crop rect', () {
    final service = ImageCorrectionService();
    final state = service.rotate90(
      const CorrectionState(
        imagePath: '/tmp/a.jpg',
        quarterTurns: 0,
        cropRect: Rect.fromLTWH(10, 20, 100, 80),
      ),
    );

    expect(state.quarterTurns, 1);
    expect(state.cropRect.width, 100);
  });
}
