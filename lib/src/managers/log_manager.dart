import 'dart:async';
import 'dart:io';
import '../utilities/file_storage.dart';

class LogManager {
  static final LogManager _instance = LogManager._internal();
  factory LogManager() => _instance;
  LogManager._internal();
  
  final StreamController<String> _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;
  
  static const int maxLogSize = 1024 * 1024; // 1MB
  String _cachedLogs = '';
  
  Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    
    // Update cached logs
    _cachedLogs += '$logEntry\n';
    
    // Notify listeners
    _logController.add(logEntry);
    
    // Write to file
    try {
      final logFile = await FileStorage.getLogFile();
      
      // Check if file exists and size
      if (await logFile.exists()) {
        final size = await logFile.length();
        if (size > maxLogSize) {
          await _rotateLog(logFile);
        }
      }
      
      // Append to file
      await logFile.writeAsString(
        '$logEntry\n',
        mode: FileMode.append,
      );
    } catch (e) {
      print('Failed to write log: $e');
    }
  }
  
  Future<String> getAllLogs() async {
    try {
      final logFile = await FileStorage.getLogFile();
      if (await logFile.exists()) {
        return await logFile.readAsString();
      }
    } catch (e) {
      print('Failed to read logs: $e');
    }
    return _cachedLogs;
  }
  
  Future<void> clearLogs() async {
    _cachedLogs = '';
    _logController.add(''); // Notify listeners
    
    try {
      final logFile = await FileStorage.getLogFile();
      if (await logFile.exists()) {
        await logFile.delete();
      }
    } catch (e) {
      print('Failed to clear logs: $e');
    }
  }
  
  Future<void> _rotateLog(File logFile) async {
    try {
      final backupPath = '${logFile.path}.old';
      final backupFile = File(backupPath);
      
      // Delete old backup if exists
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      
      // Move current log to backup
      await logFile.rename(backupPath);
      
      // Create new log file
      await logFile.create();
    } catch (e) {
      print('Failed to rotate log: $e');
    }
  }
  
  void dispose() {
    _logController.close();
  }
}
