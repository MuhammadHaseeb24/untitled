import 'package:shared_preferences/shared_preferences.dart';

import '../models/save_data.dart';

class LoadedSave {
  const LoadedSave(this.data, {this.recoveredFromCorruption = false});
  final SaveData data;
  final bool recoveredFromCorruption;
}

/// Stores the whole save as one versioned JSON string, so progress is always
/// written atomically (never half-updated across several keys).
class SaveService {
  static const _key = 'kingdoms_of_ember_save_v1';
  static const _backupKey = 'kingdoms_of_ember_save_corrupt_backup';

  Future<LoadedSave> load(int levelCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.get(_key);
      if (raw == null) return LoadedSave(SaveData.fresh());
      if (raw is String) {
        final parsed = SaveData.tryParse(raw, levelCount: levelCount);
        if (parsed != null) return LoadedSave(parsed);
        await prefs.setString(_backupKey, raw);
      }
      return LoadedSave(SaveData.fresh(), recoveredFromCorruption: true);
    } catch (_) {
      return LoadedSave(SaveData.fresh(), recoveredFromCorruption: true);
    }
  }

  Future<bool> save(SaveData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_key, data.encode());
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
