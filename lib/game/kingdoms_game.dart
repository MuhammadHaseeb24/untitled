import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../models/ability_model.dart';
import '../models/battle_result.dart';
import '../models/level_model.dart';
import '../models/unit_model.dart';
import '../models/upgrade_model.dart';
import '../services/audio_service.dart';
import '../services/game_data.dart';
import 'battle_hud.dart';
import 'components/damageable.dart';
import 'components/effect_component.dart';
import 'components/fortress_component.dart';
import 'components/mine_component.dart';
import 'components/projectile_component.dart';
import 'components/spear_component.dart';
import 'components/unit_component.dart';
import 'game_config.dart';
import 'game_types.dart';
import 'systems/combat_system.dart';
import 'systems/economy_system.dart';
import 'systems/enemy_ai_system.dart';
import 'systems/level_system.dart';
import 'world/battlefield.dart';

enum _Phase { running, ending, finished }

/// Flame game that owns the whole battle simulation. One instance per battle.
///
/// All gameplay advances from [update] using a single clock (no timers):
/// economy, recruit queues, cooldowns, enemy AI and the win/lose check run in
/// fixed-size sub-steps, so pause, 2x speed and frame-rate independence work
/// the same way for everything.
class KingdomsGame extends FlameGame {
  KingdomsGame({
    required this.level,
    required this.data,
    required this.bonuses,
    required this.audio,
    required this.lowQuality,
    required this.battleId,
    required this.tutorialEnabled,
    this.onResult,
    this.onTutorialDone,
  });

  final LevelModel level;
  final GameData data;
  final UpgradeBonuses bonuses;
  final AudioService audio;
  final bool lowQuality;
  final int battleId;
  final bool tutorialEnabled;
  final void Function(BattleResult result)? onResult;
  final void Function()? onTutorialDone;

  final BattleHud hud = BattleHud();
  final Random rng = Random(17);

  late final CombatSystem combat = CombatSystem(this);
  late final EconomySystem economy = EconomySystem(
    startingGold: level.startingGold + bonuses.startingGold,
    passiveIncome: level.passiveIncome,
    intervalSeconds: level.incomeIntervalSeconds,
  );
  late final EconomySystem enemyEconomy = EconomySystem(
    startingGold: level.enemy.startingGold,
    passiveIncome: level.enemy.passiveIncome,
    intervalSeconds: level.enemy.incomeIntervalSeconds,
  );
  final RecruitQueue playerQueue = RecruitQueue();
  final RecruitQueue enemyQueue = RecruitQueue();
  late final EnemyAiSystem ai = EnemyAiSystem(
    config: level.enemy,
    catalog: data.units,
  );

  late final FortressComponent playerFortress = FortressComponent(
    game: this,
    team: Team.player,
    maxHealth: level.playerFortressHealth * bonuses.fortressHealthMultiplier,
  );
  late final FortressComponent enemyFortress = FortressComponent(
    game: this,
    team: Team.enemy,
    maxHealth: level.enemyFortressHealth * level.enemy.healthMultiplier,
  );

  final List<MineComponent> mines = [];
  final List<UnitComponent> playerUnits = [];
  final List<UnitComponent> enemyUnits = [];
  final Map<String, Cooldown> cooldowns = {};
  late final Cooldown enemyVolleyCd = Cooldown(
    level.enemy.volleyCooldown > 0 ? level.enemy.volleyCooldown : 1,
  );

  Command playerCommand = Command.defend;
  _Phase _phase = _Phase.running;
  BattleOutcome? _outcome;
  double _endTimer = 0;
  double elapsed = 0;
  bool _paused = false;
  bool tutorialHold = false;
  double _speed = 1;
  double _hudAccum = 0;
  double _toastLeft = 0;
  int _unitsLost = 0;
  int _unitsKilled = 0;
  int _spawnCountPlayer = 0;
  int _spawnCountEnemy = 0;

  double _rallyRemaining = 0;
  AbilityModel? _rallyModel;

  List<TutorialStep> _tutorialSteps = const [];
  int _tutorialIndex = 0;

  double _viewScale = 1;
  Offset _viewOffset = Offset.zero;

  // --- Public state used by components --------------------------------------

  bool get combatActive => _phase == _Phase.running;
  bool get isPaused => _paused;
  double get speed => _speed;
  bool get rallyActive => _rallyRemaining > 0;
  int get populationLimit => level.populationLimit + bonuses.populationBonus;

  bool get acceptingInput =>
      _phase == _Phase.running && !_paused && !tutorialHold;

  List<UnitComponent> unitsOf(Team t) =>
      t == Team.player ? playerUnits : enemyUnits;
  FortressComponent fortressOf(Team t) =>
      t == Team.player ? playerFortress : enemyFortress;
  Command commandFor(Team t) => t == Team.player ? playerCommand : ai.command;

  double attackSpeedFor(Team t) => (t == Team.player && rallyActive)
      ? (_rallyModel?.attackSpeedMultiplier ?? 1.0)
      : 1.0;

  double damageBuffFor(Team t) => (t == Team.player && rallyActive)
      ? (_rallyModel?.damageMultiplier ?? 1.0)
      : 1.0;

  int get reservedPopulation {
    var total = playerQueue.reservedPopulation;
    for (final u in playerUnits) {
      total += u.model.population;
    }
    return total;
  }

  int get _enemyPopulation {
    var total = enemyQueue.reservedPopulation;
    for (final u in enemyUnits) {
      total += u.model.population;
    }
    return total;
  }

  // --- Lifecycle ------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final id in level.availableAbilities) {
      final model = data.abilities[id];
      if (model != null) cooldowns[id] = Cooldown(model.cooldown);
    }
    add(BattlefieldBackground(theme: level.theme, lowQuality: lowQuality));
    playerFortress.hasSpearRack = level.availableAbilities.contains(
      'spear_volley',
    );
    enemyFortress.hasSpearRack = level.enemy.volleyCooldown > 0;
    if (level.enemy.volleyCooldown > 0) {
      enemyVolleyCd.remaining = level.enemy.volleyFirstAt;
    }
    add(playerFortress);
    add(enemyFortress);
    for (final spec in level.mines) {
      final mine = MineComponent(x: spec.x, totalGold: spec.gold);
      mines.add(mine);
      add(mine);
    }
    add(
      ForegroundLayer(
        lowQuality: lowQuality,
        seed: level.id,
        theme: level.theme,
      ),
    );
    final miner = data.units['miner'];
    if (miner != null) {
      for (var i = 0; i < level.startingMiners; i++) {
        _spawnUnit(Team.player, miner, silent: true);
      }
    }
    for (final id in level.startingArmy) {
      final m = data.units[id];
      if (m != null) _spawnUnit(Team.player, m, silent: true);
    }
    _initTutorial();
    _syncHud();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _viewScale = min(
      size.x / GameConfig.worldWidth,
      size.y / GameConfig.worldHeight,
    );
    _viewOffset = Offset(
      (size.x - GameConfig.worldWidth * _viewScale) / 2,
      (size.y - GameConfig.worldHeight * _viewScale) / 2,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(_viewOffset.dx, _viewOffset.dy);
    canvas.scale(_viewScale);
    super.render(canvas);
    canvas.restore();
  }

  // --- Main loop ------------------------------------------------------------

  @override
  void update(double dt) {
    final real = dt.clamp(0.0, GameConfig.maxFrameDt).toDouble();
    _toastLeft = max(0.0, _toastLeft - real);
    if (_toastLeft <= 0 && hud.toast != null) {
      hud.toast = null;
      _hudAccum = GameConfig.hudInterval;
    }

    if (_phase == _Phase.finished || _paused || tutorialHold) {
      // dt = 0 still lets Flame mount newly added components.
      super.update(0);
    } else {
      var remaining = real * _speed;
      while (remaining > 1e-6 && _phase != _Phase.finished) {
        final step = min(remaining, GameConfig.maxStep);
        remaining -= step;
        super.update(step);
        _simulateSystems(step);
      }
    }
    _hudAccum += real;
    if (_hudAccum >= GameConfig.hudInterval) _syncHud();
  }

  void _simulateSystems(double dt) {
    elapsed += dt;
    if (_phase == _Phase.running) {
      economy.tick(dt);
      enemyEconomy.tick(dt);
      for (final m in playerQueue.tick(dt)) {
        _spawnUnit(Team.player, m);
      }
      for (final m in enemyQueue.tick(dt)) {
        _spawnUnit(Team.enemy, m);
      }
      for (final c in cooldowns.values) {
        c.tick(dt);
      }
      if (level.enemy.volleyCooldown > 0) enemyVolleyCd.tick(dt);
      if (_rallyRemaining > 0) _rallyRemaining = max(0.0, _rallyRemaining - dt);
      _runEnemyAi(dt);
      _checkOutcome();
    } else if (_phase == _Phase.ending) {
      _endTimer -= dt;
      if (_endTimer <= 0) _deliverResult();
    }
  }

  void _runEnemyAi(double dt) {
    var alive = 0;
    var threatened = false;
    for (final u in enemyUnits) {
      if (u.isAlive) alive++;
    }
    final threatX = enemyFortress.frontX - GameConfig.fortressThreatRadius;
    for (final u in playerUnits) {
      if (u.isAlive && u.x >= threatX) {
        threatened = true;
        break;
      }
    }
    final out = ai.think(
      dt,
      AiView(
        armyCount: alive,
        population: _enemyPopulation,
        fortressThreatened: threatened,
        elapsed: elapsed,
      ),
      enemyEconomy,
    );
    for (final m in out.paid) {
      enemyQueue.enqueue(m);
    }
    for (final m in out.free) {
      _spawnUnit(Team.enemy, m);
    }
    _enemyVolley();
  }

  /// The enemy's own Spear Volley (neza-bazi). It only fires at a real cluster
  /// of your visible units, so garrisoning inside the statue avoids it.
  void _enemyVolley() {
    final cfg = level.enemy;
    if (cfg.volleyCooldown <= 0 || !enemyVolleyCd.ready) return;
    const spread = 220.0;
    final cluster = _bestClusterOf(Team.player, spread * 0.5);
    if (cluster == null || cluster.count < 2) return;
    final minX = playerFortress.frontX + 30;
    final maxX = enemyFortress.frontX - 40;
    for (var i = 0; i < cfg.volleyCount; i++) {
      final tx = (cluster.x + (rng.nextDouble() * 2 - 1) * spread / 2)
          .clamp(minX, maxX)
          .toDouble();
      final lane =
          GameConfig.laneOffsets[rng.nextInt(GameConfig.laneOffsets.length)];
      add(
        SpearComponent(
          game: this,
          team: Team.enemy,
          startX: enemyFortress.x + 60,
          targetX: tx,
          landLane: lane,
          damage: cfg.volleyDamage * cfg.damageMultiplier,
          radius: 46,
          delay: i * 0.08,
          playSound: i == 0,
        ),
      );
    }
    enemyVolleyCd.start();
    showToast('Enemy spears incoming! Garrison to hide');
  }

  // --- Units ----------------------------------------------------------------

  // --- Mining ---------------------------------------------------------------

  /// Gold a miner carries per trip (base 10, raised by the Heavy Sacks upgrade).
  int get carryCapacity => GameConfig.baseCarry + bonuses.miningBonus;

  /// Nearest mine on the miner's side of the field that still has gold and
  /// room, or any non-empty mine if all are busy. Null when everything is empty.
  MineComponent? pickMine(double fromX, Team team) {
    if (team != Team.player) return null;
    MineComponent? best;
    var bestD = double.infinity;
    MineComponent? busy;
    var busyD = double.infinity;
    for (final m in mines) {
      if (m.depleted) continue;
      final d = (m.x - fromX).abs();
      if (m.hasRoom) {
        if (d < bestD) {
          best = m;
          bestD = d;
        }
      } else if (d < busyD) {
        busy = m;
        busyD = d;
      }
    }
    return best ?? busy;
  }

  /// Called on the moment a miner's pickaxe strikes: sparks, sound, wobble.
  void onPickaxeHit(UnitComponent miner, MineComponent mine) {
    mine.pulse();
    audio.playSfx(Sfx.mine);
    addEffect(
      EffectComponent.burst(
        at: Vector2(mine.x - miner.facing * 8, mine.y - 26),
        color: const Color(0xFFFFD84D),
        count: lowQuality ? 2 : 6,
        rng: rng,
        speed: 130,
        duration: 0.35,
      ),
    );
  }

  void depositGold(UnitComponent miner, int amount) {
    if (amount <= 0 || !combatActive) return;
    economy.add(amount);
    addEffect(
      EffectComponent.floatText(
        at: Vector2(miner.x, miner.y - 70),
        text: '+$amount',
        color: const Color(0xFFFFD84D),
      ),
    );
    audio.playSfx(Sfx.tap);
  }

  void _spawnUnit(Team team, UnitModel model, {bool silent = false}) {
    final count = team == Team.player
        ? _spawnCountPlayer++
        : _spawnCountEnemy++;
    final lane = count % GameConfig.laneOffsets.length;
    final fortress = fortressOf(team);
    final unit = UnitComponent(
      game: this,
      model: model,
      team: team,
      lane: lane,
      slotIndex: count,
      healthMultiplier: team == Team.player
          ? bonuses.healthMultiplier
          : level.enemy.healthMultiplier,
      damageMultiplier: team == Team.player
          ? bonuses.damageMultiplier
          : level.enemy.damageMultiplier,
      spawnPosition: Vector2(
        fortress.frontX + team.direction * 28,
        GameConfig.groundY + GameConfig.laneOffsets[lane],
      ),
    );
    unitsOf(team).add(unit);
    add(unit);
    if (team == Team.player && !silent) audio.playSfx(Sfx.recruit);
  }

  void onUnitDied(UnitComponent unit) {
    if (unit.team == Team.player) {
      _unitsLost++;
    } else {
      _unitsKilled++;
    }
    addEffect(
      EffectComponent.burst(
        at: Vector2(unit.x, unit.centerY),
        color: unit.team == Team.player
            ? const Color(0xFF6FA4FF)
            : const Color(0xFFFF6A5A),
        count: lowQuality ? 5 : 10,
        rng: rng,
        speed: 110,
      ),
    );
  }

  /// Called once a dead unit has fully left the battlefield (frees population).
  void unregisterUnit(UnitComponent unit) {
    unitsOf(unit.team).remove(unit);
  }

  void onDamageDealt(Damageable target, double amount, {bool heavy = false}) {
    if (target is FortressComponent) {
      audio.playSfx(Sfx.fortressHit);
      addEffect(
        EffectComponent.burst(
          at: Vector2(
            target.frontX,
            GameConfig.groundY - 40 - rng.nextDouble() * 120,
          ),
          color: const Color(0xFFB0A89A),
          count: lowQuality ? 3 : 6,
          rng: rng,
          speed: 90,
        ),
      );
    }
    if (heavy) {
      addEffect(
        EffectComponent.ring(
          at: Vector2(target.posX, GameConfig.groundY + 8),
          color: const Color(0xFFFFB347),
          radius: 70,
          duration: 0.35,
        ),
      );
    }
    if (!lowQuality) {
      addEffect(
        EffectComponent.floatText(
          at: Vector2(target.posX, target.centerY - 34),
          text: amount.round().toString(),
          color: target.team == Team.enemy
              ? const Color(0xFFFFE08A)
              : const Color(0xFFFF7B6B),
        ),
      );
    }
  }

  void spawnProjectile({
    required UnitComponent source,
    required Vector2 from,
    required Vector2 to,
    required double damage,
  }) {
    final m = source.model;
    add(
      ProjectileComponent(
        game: this,
        team: source.team,
        from: from,
        to: to,
        speed: m.projectileSpeed,
        damage: damage,
        areaRadius: m.areaRadius,
        isMagic: m.kind == UnitKind.mage,
      ),
    );
  }

  void addEffect(EffectComponent effect) {
    final cap = lowQuality ? 25 : 70;
    if (children.query<EffectComponent>().length >= cap) return;
    add(effect);
  }

  void playAttackSfx(String key) {
    switch (key) {
      case 'shield':
        audio.playSfx(Sfx.shield);
        break;
      case 'bow':
        audio.playSfx(Sfx.bow);
        break;
      case 'magic':
        audio.playSfx(Sfx.magicCast);
        break;
      default:
        audio.playSfx(Sfx.sword);
    }
  }

  // --- Player actions -------------------------------------------------------

  RecruitResult recruit(String unitId) {
    if (!acceptingInput) return RecruitResult.notActive;
    final model = data.units[unitId];
    if (model == null || !level.unlockedUnits.contains(unitId))
      return RecruitResult.locked;
    if (!economy.canAfford(model.cost)) {
      showToast('Not enough gold');
      audio.playSfx(Sfx.error);
      return RecruitResult.noGold;
    }
    if (reservedPopulation + model.population > populationLimit) {
      showToast('Army is at its population limit');
      audio.playSfx(Sfx.error);
      return RecruitResult.populationFull;
    }
    if (!economy.trySpend(model.cost)) return RecruitResult.noGold;
    playerQueue.enqueue(model);
    audio.playSfx(Sfx.tap);
    _tutorialEvent('recruit');
    _syncHud();
    return RecruitResult.ok;
  }

  void setCommand(Command command) {
    if (!acceptingInput) return;
    final changed = playerCommand != command;
    playerCommand = command;
    if (changed) audio.playSfx(Sfx.tap);
    _tutorialEvent(command.name);
    _syncHud();
  }

  AbilityResult useAbility(String id) {
    if (!acceptingInput) return AbilityResult.notActive;
    final model = data.abilities[id];
    final cd = cooldowns[id];
    if (model == null || cd == null) return AbilityResult.locked;
    if (!cd.ready) return AbilityResult.cooling;

    switch (model.type) {
      case AbilityType.areaDamage:
        final cx = _bestEnemyCluster(model.radius);
        if (cx == null) {
          showToast('No enemies in range');
          audio.playSfx(Sfx.error);
          return AbilityResult.noTarget;
        }
        combat.areaDamage(
          cx: cx,
          cy: GameConfig.groundY,
          radius: model.radius,
          victimTeam: Team.enemy,
          raw: model.damage * bonuses.damageMultiplier,
        );
        addEffect(
          EffectComponent.ring(
            at: Vector2(cx, GameConfig.groundY),
            color: const Color(0xFFFF8A2B),
            radius: model.radius,
            duration: 0.6,
          ),
        );
        addEffect(
          EffectComponent.burst(
            at: Vector2(cx, GameConfig.groundY - 20),
            color: const Color(0xFFFFB347),
            count: lowQuality ? 10 : 26,
            rng: rng,
            speed: 220,
            duration: 0.8,
          ),
        );
        break;
      case AbilityType.armyBuff:
        _rallyModel = model;
        _rallyRemaining = model.duration;
        break;
      case AbilityType.spearVolley:
        final center = _bestEnemyCluster(model.spread * 0.5);
        if (center == null) {
          showToast('No enemies to hit');
          audio.playSfx(Sfx.error);
          return AbilityResult.noTarget;
        }
        final minX = playerFortress.frontX + 40;
        final maxX = enemyFortress.frontX - 30;
        for (var i = 0; i < model.count; i++) {
          final tx = (center + (rng.nextDouble() * 2 - 1) * model.spread / 2)
              .clamp(minX, maxX)
              .toDouble();
          final lane = GameConfig
              .laneOffsets[rng.nextInt(GameConfig.laneOffsets.length)];
          add(
            SpearComponent(
              game: this,
              team: Team.player,
              startX: playerFortress.x - 60,
              targetX: tx,
              landLane: lane,
              damage: model.damage * bonuses.damageMultiplier,
              radius: model.radius,
              delay: i * 0.07,
              playSound: i == 0,
            ),
          );
        }
        break;
      case AbilityType.fortressShield:
        playerFortress.shieldTime = model.duration;
        playerFortress.shieldReduction = model.reduction;
        break;
    }
    cd.start();
    audio.playSfx(Sfx.ability);
    _tutorialEvent('ability');
    _syncHud();
    return AbilityResult.ok;
  }

  /// World x of the largest cluster of living enemies, or null if none.
  double? _bestEnemyCluster(double radius) =>
      _bestClusterOf(Team.enemy, radius)?.x;

  /// Largest cluster of visible units of [victim]: its world x and unit count.
  ({double x, int count})? _bestClusterOf(Team victim, double radius) {
    final units = unitsOf(victim);
    final base = victim == Team.enemy ? playerFortress : enemyFortress;
    double? bestX;
    var bestCount = 0;
    var bestDist = double.infinity;
    for (final c in units) {
      if (!c.targetable) continue;
      var count = 0;
      for (final o in units) {
        if (o.targetable && (o.x - c.x).abs() <= radius * 0.8) count++;
      }
      final dist = (c.x - base.frontX).abs();
      if (count > bestCount || (count == bestCount && dist < bestDist)) {
        bestCount = count;
        bestX = c.x;
        bestDist = dist;
      }
    }
    if (bestX == null) return null;
    return (x: bestX, count: bestCount);
  }

  void pauseBattle() {
    if (_phase == _Phase.finished) return;
    _paused = true;
    _syncHud();
  }

  void resumeBattle() {
    _paused = false;
    _syncHud();
  }

  void setSpeed(double value) {
    _speed = value >= 2 ? 2.0 : 1.0;
    _syncHud();
  }

  void showToast(String message) {
    hud.toast = message;
    _toastLeft = 1.4;
    _hudAccum = GameConfig.hudInterval;
  }

  // --- Tutorial -------------------------------------------------------------

  void _initTutorial() {
    if (!tutorialEnabled || level.tutorial.isEmpty) return;
    _tutorialSteps = List.of(level.tutorial);
    _tutorialIndex = 0;
    _showTutorialStep();
  }

  void _showTutorialStep() {
    while (_tutorialIndex < _tutorialSteps.length &&
        _tutorialSteps[_tutorialIndex].advance == 'ability' &&
        level.availableAbilities.isEmpty) {
      _tutorialIndex++;
    }
    if (_tutorialIndex >= _tutorialSteps.length) {
      _finishTutorial();
      return;
    }
    final step = _tutorialSteps[_tutorialIndex];
    hud.tutorial = step;
    tutorialHold = step.advance == 'tap';
    _syncHud();
  }

  void _tutorialEvent(String name) {
    final step = hud.tutorial;
    if (step == null || step.advance != name) return;
    _tutorialIndex++;
    _showTutorialStep();
  }

  /// Called by the "Next" button on tap-to-continue steps.
  void advanceTutorial() {
    final step = hud.tutorial;
    if (step == null || step.advance != 'tap') return;
    _tutorialIndex++;
    _showTutorialStep();
  }

  void skipTutorial() => _finishTutorial();

  void _finishTutorial() {
    final had = hud.tutorial != null || _tutorialSteps.isNotEmpty;
    hud.tutorial = null;
    tutorialHold = false;
    _tutorialSteps = const [];
    _syncHud();
    if (had) onTutorialDone?.call();
  }

  // --- Outcome --------------------------------------------------------------

  void _checkOutcome() {
    final p = playerFortress.isAlive;
    final e = enemyFortress.isAlive;
    final survived = level.isSurvival && elapsed >= level.surviveSeconds && p;
    if (p && e && !survived) return;
    final outcome = (survived && e)
        ? BattleOutcome.victory
        : ResultCalculator.outcomeFor(playerAlive: p, enemyAlive: e);
    _outcome = outcome;
    _phase = _Phase.ending;
    _endTimer = GameConfig.endDelaySeconds;
    hud.battleOver = true;
    hud.tutorial = null;
    tutorialHold = false;
    audio.playSfx(outcome == BattleOutcome.victory ? Sfx.victory : Sfx.defeat);
    _syncHud();
  }

  void _deliverResult() {
    if (_phase == _Phase.finished) return;
    _phase = _Phase.finished;
    final outcome = _outcome ?? BattleOutcome.defeat;
    final fraction = playerFortress.fraction;
    final result = BattleResult(
      battleId: battleId,
      levelId: level.id,
      outcome: outcome,
      timeSeconds: elapsed,
      playerFortressFraction: fraction,
      unitsLost: _unitsLost,
      unitsKilled: _unitsKilled,
      stars: outcome == BattleOutcome.victory
          ? ResultCalculator.starsFor(level, fraction, elapsed)
          : 0,
    );
    _syncHud();
    onResult?.call(result);
  }

  // --- HUD sync -------------------------------------------------------------

  void _syncHud() {
    _hudAccum = 0;
    hud.gold = economy.gold;
    hud.population = reservedPopulation;
    hud.populationMax = populationLimit;
    hud.queued = playerQueue.length;
    hud.queuedByUnit
      ..clear()
      ..addAll(playerQueue.countsByUnit());
    hud.queueProgress = playerQueue.headProgress;
    hud.playerHp = playerFortress.health;
    hud.playerMaxHp = playerFortress.maxHealth;
    hud.enemyHp = enemyFortress.health;
    hud.enemyMaxHp = enemyFortress.maxHealth;
    hud.command = playerCommand;
    hud.speed = _speed;
    hud.paused = _paused;
    hud.elapsed = elapsed;
    hud.surviveTotal = level.surviveSeconds;
    hud.rallyRemaining = _rallyRemaining;
    hud.wardRemaining = playerFortress.shieldTime;
    for (final e in cooldowns.entries) {
      hud.abilityCooldown[e.key] = e.value.fraction;
      hud.abilityRemainingSeconds[e.key] = e.value.remaining;
    }
    hud.notifyHud();
  }
}
