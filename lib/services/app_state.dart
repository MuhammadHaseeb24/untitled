import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../game/systems/level_system.dart';
import '../models/battle_result.dart';
import '../models/level_model.dart';
import '../models/save_data.dart';
import '../models/upgrade_model.dart';
import 'audio_service.dart';
import 'game_data.dart';
import 'save_service.dart';

enum PurchaseResult { ok, maxed, notEnoughCoins, unknown }

/// App-wide state: static data, campaign progress and settings.
class AppState extends ChangeNotifier {
  AppState({required this.saveService, required this.audio});

  final SaveService saveService;
  final AudioService audio;

  GameData? _data;
  SaveData save = SaveData.fresh();
  UpgradeBonuses bonuses = UpgradeBonuses.none;
  bool recoveredFromCorruption = false;
  bool _loaded = false;

  int? _lastRewardedBattle;
  RewardSummary _lastSummary = RewardSummary.none;

  GameData get data => _data!;
  bool get isLoaded => _loaded;
  GameSettings get settings => save.settings;

  Future<void> load(AssetBundle bundle) async {
    _data ??= await GameData.load(bundle);
    final loaded = await saveService.load(_data!.levels.length);
    save = loaded.data;
    recoveredFromCorruption = loaded.recoveredFromCorruption;
    _recomputeBonuses();
    await audio.init(save.settings);
    _loaded = true;
    notifyListeners();
  }

  void _recomputeBonuses() {
    bonuses = UpgradeBonuses.fromLevels(data.upgrades, save.upgrades);
  }

  Future<void> _persist() async {
    if (!_loaded) return; // never overwrite a save with unloaded state
    await saveService.save(save);
  }

  // --- Campaign -------------------------------------------------------------

  bool isUnlocked(int levelId) => levelId <= save.highestUnlocked;

  LevelRecord? recordFor(int levelId) => save.completed[levelId];

  bool get hasAnyProgress => save.completed.isNotEmpty;

  int get continueLevelId =>
      save.highestUnlocked.clamp(1, data.levels.length).toInt();

  int get totalStars {
    var total = 0;
    for (final r in save.completed.values) {
      total += r.stars;
    }
    return total;
  }

  /// Applies a finished battle to the save exactly once per battle id.
  Future<RewardSummary> completeLevel(
    LevelModel level,
    BattleResult result,
  ) async {
    if (_lastRewardedBattle == result.battleId) return _lastSummary;
    _lastRewardedBattle = result.battleId;
    if (result.outcome != BattleOutcome.victory) {
      _lastSummary = RewardSummary.none;
      return _lastSummary;
    }
    final previous = save.completed[level.id];
    final hasNext = level.id < data.levels.length;
    final summary = ResultCalculator.rewardFor(
      level: level,
      previous: previous,
      stars: result.stars,
      hasNextLevel: hasNext,
      highestUnlocked: save.highestUnlocked,
    );
    final bestStars = previous != null && previous.stars > result.stars
        ? previous.stars
        : result.stars;
    final prevTime = previous?.bestTime;
    final bestTime = prevTime == null || result.timeSeconds < prevTime
        ? result.timeSeconds
        : prevTime;
    save.completed[level.id] = LevelRecord(
      stars: bestStars,
      bestTime: bestTime,
    );
    save.coins += summary.coinsAwarded;
    if (hasNext && save.highestUnlocked < level.id + 1)
      save.highestUnlocked = level.id + 1;
    _lastSummary = summary;
    notifyListeners();
    await _persist();
    return summary;
  }

  // --- Upgrades -------------------------------------------------------------

  int upgradeLevel(String id) => save.upgrades[id] ?? 0;

  /// Mutates state synchronously, so rapid taps cannot buy twice.
  PurchaseResult buyUpgrade(String id) {
    UpgradeModel? model;
    for (final u in data.upgrades) {
      if (u.id == id) model = u;
    }
    if (model == null) return PurchaseResult.unknown;
    final current = upgradeLevel(id);
    if (current >= model.maxLevel) return PurchaseResult.maxed;
    final cost = model.costFor(current);
    if (save.coins < cost) return PurchaseResult.notEnoughCoins;
    save.coins -= cost;
    save.upgrades[id] = current + 1;
    _recomputeBonuses();
    notifyListeners();
    _persist();
    return PurchaseResult.ok;
  }

  // --- Tutorial & settings --------------------------------------------------

  bool tutorialDone(LevelModel level) =>
      save.tutorialsDone.contains(level.tutorialKey);

  void markTutorialDone(LevelModel level) {
    if (save.tutorialsDone.add(level.tutorialKey)) {
      notifyListeners();
      _persist();
    }
  }

  void resetTutorials() {
    save.tutorialsDone.clear();
    notifyListeners();
    _persist();
  }

  void updateSettings(GameSettings settings) {
    save.settings = settings;
    audio.apply(settings);
    notifyListeners();
    _persist();
  }

  /// Resets campaign progress (settings are kept). Callers must confirm first.
  Future<void> resetProgress() async {
    save = SaveData.fresh(settings: save.settings);
    _lastRewardedBattle = null;
    _lastSummary = RewardSummary.none;
    _recomputeBonuses();
    notifyListeners();
    await _persist();
  }
}
