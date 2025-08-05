import 'package:flutter/foundation.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'package:flutter_wblock_plugin_example/models/user_script.dart';

class UserScriptManager extends ChangeNotifier {
  List<UserScript> _userScripts = [];
  bool _isLoading = false;
  String _statusDescription = '';

  // Getters
  List<UserScript> get userScripts => _userScripts;
  bool get isLoading => _isLoading;
  String get statusDescription => _statusDescription;

  UserScriptManager() {
    _loadUserScripts();
  }

  Future<void> _loadUserScripts() async {
    try {
      _isLoading = true;
      _statusDescription = 'Loading user scripts...';
      notifyListeners();

      final scripts = await FlutterWblockPlugin.getUserScripts();
      _userScripts = scripts.map((map) => UserScript.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading user scripts: $e');
    } finally {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
    }
  }

  Future<void> addUserScript({String? name, String? content, Uri? url}) async {
    try {
      _isLoading = true;
      _statusDescription = 'Adding user script...';
      notifyListeners();

      if (url != null) {
        // Add from URL - the native implementation will handle downloading
        await FlutterWblockPlugin.addUserScript(
          name: name ?? 'User Script',
          content: url.toString(),
        );
      } else if (content != null) {
        // Add from content
        await FlutterWblockPlugin.addUserScript(
          name: name ?? 'User Script',
          content: content,
        );
      }

      // Reload scripts
      await _loadUserScripts();
    } catch (e) {
      debugPrint('Error adding user script: $e');
    } finally {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
    }
  }

  Future<void> addUserScriptFromUrl(Uri url) async {
    await addUserScript(url: url);
  }

  Future<void> toggleUserScript(UserScript script) async {
    try {
      await FlutterWblockPlugin.toggleUserScript(script.id);
      
      // Update local state
      final index = _userScripts.indexWhere((s) => s.id == script.id);
      if (index != -1) {
        _userScripts[index] = _userScripts[index].copyWith(
          isEnabled: !_userScripts[index].isEnabled,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling user script: $e');
    }
  }

  Future<void> removeUserScript(UserScript script) async {
    try {
      await FlutterWblockPlugin.removeUserScript(script.id);
      
      // Remove from local state
      _userScripts.removeWhere((s) => s.id == script.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing user script: $e');
    }
  }

  Future<void> updateUserScript(UserScript script) async {
    try {
      _isLoading = true;
      _statusDescription = 'Updating ${script.name}...';
      notifyListeners();

      // The native implementation handles the actual update
      // For now, we'll just reload all scripts
      await _loadUserScripts();
    } catch (e) {
      debugPrint('Error updating user script: $e');
    } finally {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
    }
  }

  Future<void> refreshAllUserScripts() async {
    try {
      _isLoading = true;
      _statusDescription = 'Refreshing all user scripts...';
      notifyListeners();

      // Update all downloaded scripts
      final downloadedScripts = _userScripts.where((s) => s.isDownloaded).toList();
      
      for (final script in downloadedScripts) {
        await updateUserScript(script);
      }
    } catch (e) {
      debugPrint('Error refreshing user scripts: $e');
    } finally {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
    }
  }
}
