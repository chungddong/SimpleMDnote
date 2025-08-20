import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _notesPathKey = 'notes_path';
  static const String _isFirstRunKey = 'is_first_run';

  static Future<String?> getNotesPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notesPathKey);
  }

  static Future<void> setNotesPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesPathKey, path);
    await prefs.setBool(_isFirstRunKey, false);
  }

  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstRunKey) ?? true;
  }

  static Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}