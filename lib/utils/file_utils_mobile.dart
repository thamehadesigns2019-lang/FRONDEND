import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> clearAppCache() async {
  try {
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  } catch (e) {
    print("Error clearing temp dir: $e");
  }
}
