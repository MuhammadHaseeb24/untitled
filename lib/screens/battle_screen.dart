import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_theme.dart';
import '../game/kingdoms_game.dart';
import '../models/battle_result.dart';
import '../models/level_model.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/ability_button.dart';
import '../widgets/battle_result_dialog.dart';
import '../widgets/battle_top_bar.dart';
import '../widgets/command_controls.dart';
import '../widgets/pause_menu.dart';
import '../widgets/pulse_highlight.dart';
import '../widgets/tutorial_banner.dart';
import '../widgets/unit_recruit_button.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.levelId});

  final int levelId;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with WidgetsBindingObserver {
  static int _nextBattleId = 1;

  late AppState _app;
  late LevelModel _level;
  late KingdomsGame _game;
  bool _started = false;
  bool _showPause = false;
  BattleResult? _result;
  RewardSummary? _reward;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _app = AppScope.read(context);
      _level = _app.data.levelById(widget.levelId)!;
      _createGame();
      _app.audio.playMusic(MusicTrack.battle);
    }
  }

  void _createGame() {
    final app = _app;
    final level = _level;
    _game = KingdomsGame(
      level: level,
      data: app.data,
      bonuses: app.bonuses,
      audio: app.audio,
      lowQuality: app.settings.lowQuality,
      battleId: _nextBattleId++,
      tutorialEnabled: !app.tutorialDone(level),
      onResult: _onResult,
      onTutorialDone: () => app.markTutorialDone(level),
    );
    _result = null;
    _reward = null;
    _showPause = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _app.audio.playMusic(MusicTrack.menu);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _result == null && mounted) {
      _game.pauseBattle();
      setState(() => _showPause = true);
    }
  }

  void _onResult(BattleResult result) {
    if (!mounted) return;
    setState(() => _result = result);
    _app.completeLevel(_level, result).then((summary) {
      if (mounted && identical(_result, result))
        setState(() => _reward = summary);
    });
  }

  void _pause() {
    _game.pauseBattle();
    setState(() => _showPause = true);
  }

  void _resume() {
    _game.resumeBattle();
    setState(() => _showPause = false);
  }

  void _restart() => setState(_createGame);

  void _toMenu() => Navigator.of(context).popUntil((r) => r.isFirst);

  void _next() {
    final nextId = _level.id + 1;
    if (_app.data.levelById(nextId) == null) return _toMenu();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => BattleScreen(levelId: nextId)),
    );
  }

  void _onBack() {
    if (_result != null) {
      _toMenu();
    } else if (_showPause) {
      _resume();
    } else {
      _pause();
    }
  }

  Widget _hl(String key, Widget child, {double radius = 14}) {
    return ListenableBuilder(
      listenable: _game.hud,
      builder: (context, _) => PulseHighlight(
        active: _game.hud.tutorial?.highlight == key,
        radius: radius,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(key: ValueKey(_game.battleId), game: _game),
            SafeArea(child: _buildHud()),
            if (_showPause && result == null)
              PauseMenu(
                onResume: _resume,
                onRestart: _restart,
                onMenu: _toMenu,
              ),
            if (result != null)
              BattleResultDialog(
                level: _level,
                result: result,
                reward: _reward,
                hasNextLevel: _app.data.levelById(_level.id + 1) != null,
                onNext: _next,
                onRetry: _restart,
                onMenu: _toMenu,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    final hud = _game.hud;
    return LayoutBuilder(
      builder: (context, c) {
        final btn = (c.maxHeight * 0.2).clamp(56.0, 84.0).toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              BattleTopBar(
                hud: hud,
                levelName: _level.name,
                onPause: _pause,
                onToggleSpeed: () => _game.setSpeed(_game.speed >= 2 ? 1 : 2),
                goldWrap: (child) => _hl('gold', child, radius: 20),
              ),
              ListenableBuilder(
                listenable: hud,
                builder: (context, _) {
                  final step = hud.tutorial;
                  if (step == null || _result != null)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TutorialBanner(
                      step: step,
                      onNext: _game.advanceTutorial,
                      onSkip: _game.skipTutorial,
                    ),
                  );
                },
              ),
              Expanded(
                child: IgnorePointer(
                  child: Center(
                    child: ListenableBuilder(
                      listenable: hud,
                      builder: (context, _) {
                        final t = hud.toast;
                        if (t == null) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xDD000000),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _buildBottomBar(btn),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(double btn) {
    final hud = _game.hud;
    final unitModels = [
      for (final id in _level.unlockedUnits)
        if (_app.data.units[id] != null) _app.data.units[id]!,
    ];
    final abilityModels = [
      for (final id in _level.availableAbilities)
        if (id != 'spear_volley' && _app.data.abilities[id] != null)
          _app.data.abilities[id]!,
    ];
    final spearModel = _level.availableAbilities.contains('spear_volley')
        ? _app.data.abilities['spear_volley']
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ListenableBuilder(
          listenable: hud,
          builder: (context, _) => CommandControls(
            current: hud.command,
            size: btn,
            onSelect: _game.setCommand,
            garrisonWrap: (child) => _hl('garrison', child, radius: 40),
            attackWrap: (child) => _hl('attack', child, radius: 40),
            defendWrap: (child) => _hl('defend', child, radius: 40),
          ),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ListenableBuilder(
                listenable: hud,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hud.queued > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SizedBox(
                          width: 160,
                          child: Row(
                            children: [
                              Text(
                                'Training ${hud.queued}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDim,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: hud.queueProgress,
                                    minHeight: 6,
                                    color: AppColors.ember,
                                    backgroundColor: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final m in unitModels)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _hl(
                              'recruit',
                              radius: 40,
                              UnitRecruitButton(
                                model: m,
                                gold: hud.gold,
                                size: btn * 0.92,
                                queued: hud.queuedByUnit[m.id] ?? 0,
                                onTap: () => _game.recruit(m.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (abilityModels.isNotEmpty)
          ListenableBuilder(
            listenable: hud,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final a in abilityModels)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _hl(
                      'ability',
                      AbilityButton(
                        model: a,
                        cooldownFraction: hud.abilityCooldown[a.id] ?? 0,
                        remainingSeconds:
                            hud.abilityRemainingSeconds[a.id] ?? 0,
                        size: btn * 0.82,
                        enabled: !hud.battleOver,
                        onTap: () => _game.useAbility(a.id),
                      ),
                      radius: 40,
                    ),
                  ),
              ],
            ),
          ),
        if (spearModel != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ListenableBuilder(
              listenable: hud,
              builder: (context, _) => _hl(
                'spear',
                radius: 60,
                AbilityButton(
                  model: spearModel,
                  big: true,
                  cooldownFraction: hud.abilityCooldown[spearModel.id] ?? 0,
                  remainingSeconds:
                      hud.abilityRemainingSeconds[spearModel.id] ?? 0,
                  size: btn * 1.05,
                  enabled: !hud.battleOver,
                  onTap: () => _game.useAbility(spearModel.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
