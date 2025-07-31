import 'package:flutter/foundation.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import '../models/user_script.dart';

class UserScriptManager extends ChangeNotifier {
  List<UserScript> _userScripts = [];
  
  List<UserScript> get userScripts => _userScripts;

  UserScriptManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadUserScripts();
  }

  Future<void> loadUserScripts() async {
    try {
      final scripts = await FlutterWblockPlugin.getUserScripts();
      _userScripts = scripts.map((data) => UserScript.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user scripts: $e');
    }
  }

  Future<void> toggleScript(String id) async {
    try {
      await FlutterWblockPlugin.toggleUserScript(id);
      await loadUserScripts();
    } catch (e) {
      debugPrint('Error toggling user script: $e');
    }
  }

  Future<void> removeScript(String id) async {
    try {
      await FlutterWblockPlugin.removeUserScript(id);
      await loadUserScripts();
    } catch (e) {
      debugPrint('Error removing user script: $e');
    }
  }

  Future<void> addScript({required String name, required String content}) async {
    try {
      await FlutterWblockPlugin.addUserScript(name: name, content: content);
      await loadUserScripts();
    } catch (e) {
      debugPrint('Error adding user script: $e');
    }
  }
}
