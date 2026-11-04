import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/unit_model.dart';
import '../game_config.dart';
import '../game_types.dart';
import '../kingdoms_game.dart';
import '../painters/unit_painter.dart';
import '../systems/movement_system.dart';
import 'damageable.dart';
import 'mine_component.dart';

enum UnitState { spawning, idle, moving, attacking, dying }

enum _MinerPhase { toMine, digging, toBase }

/// A soldier. Uses an explicit state machine:
/// spawning -> idle <-> moving <-> attacking -> dying -> removed.
class UnitComponent extends PositionComponent implements Damageable {
  UnitComponent({
    required this.game,
    required this.model,
    required this.team,
    required int lane,
    required this.slotIndex,
    required double healthMultiplier,
    required this.damageMultiplier,
    required Vector2 spawnPosition,
  }) : _lane = lane,
       maxHealth = model.health * healthMultiplier,
       health = model.health * healthMultiplier,
       laneY = GameConfig.laneOffsets[lane],
       facing = team.direction,
       super(position: spawnPosition, priority: 100 + lane * 10);

  final KingdomsGame game;
  final UnitModel model;
  @override
  final Team team;
  final int slotIndex;
  final double damageMultiplier;
  final double maxHealth;
  double health;

  UnitState state = UnitState.spawning;
  double facing;
  double laneY;
  int _lane;
  int get lane => _lane;

  Damageable? target;
  Damageable? _attackTarget;
  double _retargetTimer = 0;
  double cooldownLeft = 0;
  double _attackElapsed = 0;
  bool _impactDone = false;
  double _blockedTime = 0;
  double _spawnTimer = 0;
  double _deathTimer = 0;
  double _hurtTimer = 0;
  double _walk = 0;
  double _time = 0;
  bool _removed = false;
  bool hidden = false;

  // Miner state.
  _MinerPhase _phase = _MinerPhase.toMine;
  MineComponent? _mine;
  double _digTimer = 0;
  int _carried = 0;

  final UnitVisual _visual = UnitVisual();

  static final Paint _barBack = Paint()..color = const Color(0xCC000000);
  static final Paint _barFill = Paint();

  // --- Damageable -----------------------------------------------------------

  @override
  bool get isAlive => state != UnitState.dying && health > 0;

  @override
  bool get targetable => isAlive && !hidden;

  @override
  double get damageReduction {
    var r = model.armor;
    if (game.commandFor(team) == Command.defend) r += model.defendReduction;
    return r > 0.6 ? 0.6 : r;
  }

  @override
  double get centerY => y - 36 * model.scale;

  @override
  double get bodyRadius => model.bodyRadius;

  @override
  double get posX => x;

  @override
  double gapFrom(double fromX) {
    final g = (fromX - x).abs() - model.bodyRadius;
    return g < 0 ? 0 : g;
  }

  @override
  void applyDamage(double amount) {
    if (!isAlive) return;
    health = max(0.0, health - amount);
    _hurtTimer = 0.16;
    if (health <= 0) _die();
  }

  void _die() {
    _releaseMine();
    _carried = 0;
    state = UnitState.dying;
    _deathTimer = 0;
    target = null;
    _attackTarget = null;
    game.onUnitDied(this);
  }

  void _removeSelf() {
    if (_removed) return;
    _removed = true;
    game.unregisterUnit(this);
    removeFromParent();
  }

  // --- Helpers --------------------------------------------------------------

  Command get _command => game.commandFor(team);

  double get _anchorX => team == Team.player
      ? game.playerFortress.frontX + GameConfig.defendAnchorDistance
      : game.enemyFortress.frontX - GameConfig.defendAnchorDistance;

  double get _slotX {
    final spread = ((slotIndex % 7) - 3) * 16.0;
    final back = model.kind == UnitKind.melee ? 0.0 : 70.0;
    return _anchorX + spread - team.direction * back;
  }

  bool _inDefendZone(double px) =>
      (px - _anchorX).abs() <= GameConfig.defendRadius;

  double get attackPhase {
    if (model.kind == UnitKind.miner) {
      return (_phase == _MinerPhase.digging && state != UnitState.dying)
          ? ((_digTimer % 0.8) / 0.8) * 0.9
          : -1;
    }
    if (state != UnitState.attacking) return -1;
    final w = model.windup <= 0 ? 0.01 : model.windup;
    if (_attackElapsed < w) return (_attackElapsed / w) * 0.55;
    return 0.55 +
        ((_attackElapsed - w) / GameConfig.recoverTime).clamp(0.0, 1.0) * 0.45;
  }

  // --- Update ---------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0) return;
    _time += dt;
    if (state == UnitState.dying) {
      _deathTimer += dt;
      if (_deathTimer >= GameConfig.deathDuration) _removeSelf();
      return;
    }
    if (_hurtTimer > 0) _hurtTimer = max(0.0, _hurtTimer - dt);
    _smoothLane(dt);
    if (state == UnitState.spawning) {
      _spawnTimer += dt;
      if (_spawnTimer >= GameConfig.spawnDuration) state = UnitState.idle;
      return;
    }
    if (!game.combatActive) {
      if (state != UnitState.idle) state = UnitState.idle;
      return;
    }
    if (_command == Command.garrison) {
      _garrison(dt);
      return;
    }
    if (hidden) hidden = false; // come back out of the statue
    if (model.kind == UnitKind.miner) {
      _updateMiner(dt);
      return;
    }
    cooldownLeft = max(0.0, cooldownLeft - dt * game.attackSpeedFor(team));
    if (state == UnitState.attacking) {
      _updateAttack(dt);
    } else {
      _updateMobile(dt);
    }
  }

  // --- Garrison -------------------------------------------------------------

  void _garrison(double dt) {
    if (hidden) {
      state = UnitState.idle;
      return;
    }
    target = null;
    if (state == UnitState.attacking) state = UnitState.idle;
    final goal = game.fortressOf(team).frontX - team.direction * 6;
    final diff = goal - x;
    if (diff.abs() < 8) {
      hidden = true;
      state = UnitState.idle;
      _releaseMine();
      return;
    }
    facing = diff >= 0 ? 1.0 : -1.0;
    _stepX(diff.sign, dt, maxDistance: diff.abs(), ignoreBlocking: true);
  }

  // --- Mining ---------------------------------------------------------------

  void _releaseMine() {
    final m = _mine;
    if (m != null && _phase == _MinerPhase.digging && m.occupants > 0) {
      m.occupants--;
    }
    _mine = null;
    if (_phase == _MinerPhase.digging) _phase = _MinerPhase.toMine;
  }

  void _updateMiner(double dt) {
    final base = game.fortressOf(team);
    switch (_phase) {
      case _MinerPhase.toMine:
        var m = _mine;
        if (m == null || m.depleted) {
          m = game.pickMine(x, team);
          _mine = m;
        }
        if (m == null) {
          // No gold left (or no mine on this side): wait near the statue.
          _walkTo(base.frontX + team.direction * 40, dt);
          return;
        }
        final goal = m.x - team.direction * 22;
        if ((goal - x).abs() < 5) {
          if (!m.hasRoom) {
            state = UnitState.idle;
            return;
          }
          m.occupants++;
          _phase = _MinerPhase.digging;
          _digTimer = 0;
          state = UnitState.idle;
          facing = team.direction;
        } else {
          _walkTo(goal, dt);
        }
        break;
      case _MinerPhase.digging:
        state = UnitState.idle;
        final before = (_digTimer % 0.8) / 0.8;
        _digTimer += dt;
        final after = (_digTimer % 0.8) / 0.8;
        final mineHere = _mine;
        if (mineHere != null && before < 0.55 && after >= 0.55) {
          game.onPickaxeHit(this, mineHere);
        }
        if (_digTimer >= GameConfig.digSeconds) {
          final m = _mine;
          if (m != null) {
            _carried = m.take(game.carryCapacity);
            if (m.occupants > 0) m.occupants--;
          }
          _phase = _MinerPhase.toBase;
        }
        break;
      case _MinerPhase.toBase:
        final goal = base.frontX + team.direction * 14;
        if ((goal - x).abs() < 6) {
          if (_carried > 0) {
            game.depositGold(this, _carried);
            _carried = 0;
          }
          _phase = _MinerPhase.toMine;
          state = UnitState.idle;
        } else {
          _walkTo(goal, dt);
        }
        break;
    }
  }

  void _walkTo(double goalX, double dt) {
    final diff = goalX - x;
    if (diff.abs() < 3) {
      state = UnitState.idle;
      return;
    }
    facing = diff >= 0 ? 1.0 : -1.0;
    _stepX(diff.sign, dt, maxDistance: diff.abs(), ignoreBlocking: true);
  }

  void _smoothLane(double dt) {
    final goal = GameConfig.laneOffsets[_lane];
    final diff = goal - laneY;
    if (diff.abs() > 0.1) {
      laneY += diff.sign * min(diff.abs(), 40 * dt);
    }
    y = GameConfig.groundY + laneY;
  }

  void _updateMobile(double dt) {
    _retargetTimer -= dt;
    final current = target;
    final currentValid = current != null && _isTargetValid(current);
    if (!currentValid || _retargetTimer <= 0) {
      final keep =
          current != null &&
          currentValid &&
          current.gapFrom(x) <= model.attackRange;
      if (!keep) target = _pickTarget();
      _retargetTimer = GameConfig.retargetInterval;
    }
    final t = target;
    if (t == null) {
      _goToSlotOrIdle(dt);
      return;
    }
    final gap = t.gapFrom(x);
    final dx = t.posX - x;
    if (dx.abs() > 0.5) facing = dx >= 0 ? 1.0 : -1.0;

    if (gap <= model.attackRange) {
      if (model.kiteDistance > 0 &&
          t is UnitComponent &&
          gap < model.kiteDistance &&
          _canRetreat()) {
        _stepX(-team.direction, dt, speedMult: 0.8);
        return;
      }
      if (cooldownLeft <= 0) {
        _beginAttack();
      } else {
        state = UnitState.idle;
      }
      return;
    }
    final chase = _command == Command.attack || model.kind == UnitKind.melee;
    if (chase) {
      _stepX(dx.sign, dt, maxDistance: gap - model.attackRange + 1);
    } else {
      state = UnitState.idle;
    }
  }

  bool _canRetreat() {
    final limit = team == Team.player
        ? game.playerFortress.frontX + 40
        : game.enemyFortress.frontX - 40;
    return team == Team.player ? x > limit : x < limit;
  }

  bool _isTargetValid(Damageable t) {
    if (!t.targetable) return false;
    if (_command == Command.attack) return true;
    if (t.gapFrom(x) <= model.attackRange) return true;
    return model.kind == UnitKind.melee &&
        t is UnitComponent &&
        _inDefendZone(t.x);
  }

  Damageable? _pickTarget() {
    final attacking = _command == Command.attack;
    UnitComponent? best;
    var bestDist = double.infinity;
    for (final e in game.unitsOf(team.opponent)) {
      if (!e.targetable) continue;
      final inRange = e.gapFrom(x) <= model.attackRange;
      if (!attacking && !inRange) {
        if (model.kind != UnitKind.melee || !_inDefendZone(e.x)) continue;
      }
      final d = (e.x - x).abs();
      if (d < bestDist) {
        best = e;
        bestDist = d;
      }
    }
    if (best != null) return best;
    final fortress = game.fortressOf(team.opponent);
    if (fortress.isAlive &&
        (attacking || fortress.gapFrom(x) <= model.attackRange)) {
      return fortress;
    }
    return null;
  }

  void _goToSlotOrIdle(double dt) {
    if (_command == Command.attack) {
      state = UnitState.idle;
      return;
    }
    final diff = _slotX - x;
    if (diff.abs() < 6) {
      state = UnitState.idle;
      facing = team.direction;
      return;
    }
    facing = diff >= 0 ? 1.0 : -1.0;
    _stepX(diff.sign, dt, maxDistance: diff.abs());
  }

  bool _stepX(
    double dir,
    double dt, {
    double speedMult = 1.0,
    double? maxDistance,
    bool ignoreBlocking = false,
  }) {
    if (dir == 0) {
      state = UnitState.idle;
      return false;
    }
    if (!ignoreBlocking &&
        MovementSystem.isBlocked(this, dir, game.unitsOf(team))) {
      _blockedTime += dt;
      if (_blockedTime > 0.5) {
        _trySwitchLane();
        _blockedTime = 0;
      }
      state = UnitState.idle;
      return false;
    }
    _blockedTime = 0;
    var dist = model.moveSpeed * speedMult * dt;
    if (maxDistance != null && maxDistance >= 0) dist = min(dist, maxDistance);
    x = MovementSystem.clampX(x + dir * dist, game);
    _walk += dt * model.moveSpeed / 9;
    state = UnitState.moving;
    return true;
  }

  void _trySwitchLane() {
    final order = slotIndex.isEven ? const [-1, 1] : const [1, -1];
    for (final d in order) {
      final c = _lane + d;
      if (c < 0 || c >= GameConfig.laneOffsets.length) continue;
      var free = true;
      for (final a in game.unitsOf(team)) {
        if (identical(a, this) || !a.isAlive) continue;
        if (a.lane == c && (a.x - x).abs() < GameConfig.unitSpacing) {
          free = false;
          break;
        }
      }
      if (free) {
        _lane = c;
        priority = 100 + c * 10;
        return;
      }
    }
  }

  // --- Attack ---------------------------------------------------------------

  void _beginAttack() {
    state = UnitState.attacking;
    _attackElapsed = 0;
    _impactDone = false;
    cooldownLeft = model.attackCooldown;
    _attackTarget = target;
  }

  void _updateAttack(double dt) {
    _attackElapsed += dt * game.attackSpeedFor(team);
    final t = _attackTarget;
    if (!_impactDone && (t == null || !t.isAlive)) {
      // Target died before the hit landed: cancel and pick a new one.
      state = UnitState.idle;
      target = null;
      cooldownLeft = 0.1;
      return;
    }
    if (!_impactDone && _attackElapsed >= model.windup) {
      _impactDone = true;
      _resolveImpact(t!);
    }
    if (_attackElapsed >= model.windup + GameConfig.recoverTime) {
      state = UnitState.idle;
    }
  }

  void _resolveImpact(Damageable t) {
    final dmg = model.damage * damageMultiplier * game.damageBuffFor(team);
    game.playAttackSfx(model.attackSfx);
    switch (model.kind) {
      case UnitKind.melee:
        if (t.gapFrom(x) <= model.attackRange * 1.4 + 6) {
          game.combat.dealDamage(t, dmg, heavy: model.scale >= 1.5);
        }
        break;
      case UnitKind.miner:
        break;
      case UnitKind.ranged:
      case UnitKind.mage:
        game.spawnProjectile(
          source: this,
          from: Vector2(x + facing * 20 * model.scale, y - 46 * model.scale),
          to: Vector2(t.posX, t.centerY),
          damage: dmg,
        );
        break;
    }
  }

  // --- Render ---------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    if (hidden) return;
    final v = _visual;
    v.unitId = model.id;
    v.team = team;
    v.scale = model.scale * (1 + laneY * 0.0025);
    v.facing = facing;
    v.walk = _walk;
    v.moving = state == UnitState.moving;
    v.attackT = attackPhase;
    v.hurt = _hurtTimer > 0 ? _hurtTimer / 0.16 : 0;
    v.dying = state == UnitState.dying
        ? (_deathTimer / GameConfig.deathDuration).clamp(0.0, 1.0)
        : -1;
    v.spawn = state == UnitState.spawning
        ? (_spawnTimer / GameConfig.spawnDuration).clamp(0.0, 1.0)
        : 1;
    v.buffed = team == Team.player && game.rallyActive;
    v.time = _time;
    v.carrying = _carried > 0;
    UnitPainter.paint(canvas, v);

    if (state == UnitState.dying) return;
    if (model.kind == UnitKind.miner && _phase == _MinerPhase.digging) {
      final c = Offset(0, -(112.0 * model.scale));
      canvas.drawCircle(c, 9, Paint()..color = const Color(0x99000000));
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 7),
        -pi / 2,
        2 * pi * (_digTimer / GameConfig.digSeconds).clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFD84D),
      );
    }
    final w = 38.0 * model.scale;
    final top = -(98.0 * model.scale);
    final rect = Rect.fromLTWH(-w / 2, top, w, 5);
    canvas.drawRect(rect.inflate(1), _barBack);
    final frac = (health / maxHealth).clamp(0.0, 1.0).toDouble();
    _barFill.color = team == Team.player
        ? const Color(0xFF58D26B)
        : const Color(0xFFE5483D);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, w * frac, rect.height),
      _barFill,
    );
  }
}
