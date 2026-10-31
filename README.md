# Kingdoms of Ember

Original fantasy lane-based army strategy game for Android, built with **Flutter + Flame**.
Landscape, offline, single-player campaign with 10 levels, 5 unit types, 3 abilities, upgrades, tutorial and saved progress.

> **Status honesty:** this source was written and statically checked without a Flutter SDK or Android device
> available. The pure game logic (economy, recruit queue, cooldowns, stars/rewards, save parsing, enemy AI, data files)
> was executed and passes its tests. The Flame/Flutter code (rendering, components, screens) has **not** been compiled
> or run yet. Expect to fix a few compile errors on first `flutter analyze` and tune the balance after playtesting.
> See "First run checklist" below.

## 1. Setup (Windows PowerShell)

```powershell
cd C:\Users\hasee\StudioProjects
flutter create --org com.haseeb.kingdomsofember kingdoms_of_ember
```

Unzip this project **over** the created folder (overwrite `lib/`, `pubspec.yaml`, `analysis_options.yaml`, `test/`; add `assets/` and `tools/`). Then:

```powershell
cd kingdoms_of_ember
flutter pub get
dart run tools/patch_android.dart        # app name + landscape lock in AndroidManifest.xml
dart run flutter_launcher_icons          # optional: generates the launcher icon
flutter doctor
flutter analyze
flutter test
flutter devices
flutter run
```

If `flutter pub get` complains about a package version, run `flutter pub upgrade --major-versions` or loosen the version in `pubspec.yaml`.

## 2. How to play

* Recruit troops with gold (passive income + level reward). Troops fight automatically.
* **DEFEND** (default): the army holds near your fortress and fights what comes close. **ATTACK**: everyone advances on the enemy. The selected command is highlighted.
* Abilities (unlock from level 5): **Ember Burst** hits the biggest enemy cluster, **Royal Rally** buffs your army, **Stone Ward** shields your fortress.
* Win by destroying the enemy fortress while yours survives. Both falling in the same step is a **draw** (retry).
* Stars: 1 = win, 2 = fortress above the level threshold (60% by default), 3 = win within the par time. Shown on the level card and result screen.
* Ember Coins (persistent) come from first-time level rewards and new stars only, so replays never duplicate rewards. Spend them in **Army Upgrades**. Battle gold resets every battle.

## 3. Architecture

| Folder | Responsibility |
| --- | --- |
| `assets/data/*.json` | Units, levels, abilities, upgrades. All balance lives here, validated at load with readable errors. |
| `lib/models` | Plain data classes + save format (versioned JSON, tolerant parsing). |
| `lib/game` | Flame game: `KingdomsGame` owns one clock; components (units, fortress, projectile, effects); systems (economy, combat, AI, movement, rewards); procedural painters. |
| `lib/services` | `AppState` (progress/settings), `SaveService` (shared_preferences), `AudioService`, `GameData` loader. |
| `lib/screens`, `lib/widgets` | Flutter menus and the battle HUD (overlaid on the Flame `GameWidget`). |

Design rules implemented: one simulation clock and **no gameplay timers**; fixed sub-steps so pause and 2x speed are exact; central `CombatSystem` for all damage; explicit unit state machine (`spawning/idle/moving/attacking/dying`); dead units are untargetable and removed after a death animation; population includes the recruit queue; rewards are applied once per battle id; the result is delivered once; saves are one atomic JSON string.

The world is a virtual 1600x720 space scaled to any aspect ratio (letterboxing is filled by the background).

## 4. Tests

`flutter test` runs `test/game_logic_test.dart` (economy, queue, cooldown, stars/rewards, save round-trip and corrupt data, data-file validation, enemy AI). There are **no** widget or integration tests yet.

## 5. First run checklist

1. `flutter analyze` and fix anything it reports (the Flame/Flutter files were never compiled).
2. Start Level 1: tutorial appears, recruit, attack, defend, win.
3. Test pause, restart, 2x speed, backgrounding the app, force-close then reopen (progress must persist).
4. Play levels 5 and 8-10 for abilities and the big fortress. Adjust `assets/data/*.json` (costs, HP, enemy `buildOrder`, `recruitIntervalSeconds`) until the difficulty curve feels right.
5. Test on the Infinix X6528. If frames drop, enable "Low graphics quality" in Settings and profile with `flutter run --profile`.

## 6. Known limitations / not done

* Balance is untested. Numbers in the JSON files are starting values only.
* Audio is simple generated placeholder sound (`tools/generate_audio.py`); art is procedural. Replace with produced assets for a store release.
* Not implemented: language selection, privacy-policy link, daily reward, battle resume after app kill (the pause menu appears when you return), individual unit selection, widget/integration tests.
* Ember Burst auto-targets the largest enemy cluster (no manual aiming).
* Fortresses do not shoot back.

## 7. Release build

```powershell
# create a keystore once, then reference it from android/key.properties and android/app/build.gradle(.kts)
flutter build apk --release        # test APK
flutter build appbundle --release  # Play Store
```

Before publishing: unique package id (already `com.haseeb.kingdomsofember`), app icon, screenshots, Play Console data-safety form (the game collects no data and needs no network), and a privacy policy URL if you add ads or analytics later.
