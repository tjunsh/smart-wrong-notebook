import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  ImageStorageService();

  Future<String> saveImage(File source) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Directory.current,
      );
      final String imagesDir = '${appDir.path}/wrong_question_images';
      await Directory(imagesDir).create(recursive: true).timeout(const Duration(seconds: 5));
      final String id = const Uuid().v4();
      // 保留原文件扩展名
      final String ext = _getExtension(source.path);
      final String newPath = '$imagesDir/$id$ext';
      await source.copy(newPath);
      return newPath;
    } catch (e) {
      // Fallback: save to temp directory
      final tempDir = Directory.systemTemp;
      final imagesDir = '${tempDir.path}/wrong_question_images';
      await Directory(imagesDir).create(recursive: true);
      final String id = const Uuid().v4();
      final String ext = _getExtension(source.path);
      final String newPath = '$imagesDir/$id$ext';
      await source.copy(newPath);
      return newPath;
    }
  }

  String _getExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot < 0) return '.jpg';
    return path.substring(lastDot);
  }

  Future<void> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }
}
