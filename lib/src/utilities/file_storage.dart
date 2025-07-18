import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorage {
  static const String appGroupIdentifier = 'group.syferlab.wBlock';

  static Future<Directory> getSharedContainerDirectory() async {
    if (Platform.isMacOS) {
      // On macOS, use the app group container
      final home = Platform.environment['HOME'];
      if (home != null) {
        final containerPath = '$home/Library/Group Containers/$appGroupIdentifier';
        final dir = Directory(containerPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    }

    // Fallback to documents directory
    return await getApplicationDocumentsDirectory();
  }

  static Future<File> getFilterFile(String filterName, {String extension = 'txt'}) async {
    final dir = await getSharedContainerDirectory();
    return File('${dir.path}/$filterName.$extension');
  }

  static Future<File> getLogFile() async {
    final dir = await getSharedContainerDirectory();
    return File('${dir.path}/wblock_logs.txt');
  }

  static Future<File> getBlockerListFile(int index) async {
    final dir = await getSharedContainerDirectory();
    return File('${dir.path}/blockerList$index.json');
  }

  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<String> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  static Future<List<String>> listFiles(String directory, {String? pattern}) async {
    final dir = Directory(directory);
    if (!await dir.exists()) {
      return [];
    }

    final files = await dir.list().toList();
    final paths = files.where((entity) => entity is File).map((entity) => entity.path).toList();

    if (pattern != null) {
      return paths.where((path) => path.contains(pattern)).toList();
    }

    return paths;
  }
}
