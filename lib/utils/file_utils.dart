import 'file_utils_mobile.dart' if (dart.library.html) 'file_utils_web.dart';

Future<void> clearCache() => clearAppCache();
