import 'dart:math';

import '../../models/unit_model.dart';

/// Gold and passive income. One instance per team, driven by a single
/// simulation clock (no timers), so income can never be granted twice.
class EconomySystem {
  EconomySystem({
    required int startingGold,
    required this.passiveIncome,
    required double intervalSeconds,
  }) : gold = max(0, startingGold),
       interval = max(0.1, intervalSeconds);

  int gold;
  final int passiveIncome;
  final double interval;
  double _acc = 0;

  void tick(double dt) {
    if (dt <= 0 || passiveIncome <= 0) return;
    _acc += dt;
    while (_acc >= interval) {
      _acc -= interval;
      gold += passiveIncome;
    }
  }

  double get incomeProgress => _acc / interval;

  bool canAfford(int cost) => cost >= 0 && gold >= cost;

  /// Deducts [cost] exactly once. Returns false (and changes nothing) when the
  /// cost is negative or unaffordable, so gold can never go negative.
  bool trySpend(int cost) {
    if (!canAfford(cost)) return false;
    gold -= cost;
    return true;
  }

  void add(int amount) {
    if (amount > 0) gold += amount;
  }
}

class QueuedRecruit {
  QueuedRecruit(this.unit) : remaining = unit.recruitTime;
  final UnitModel unit;
  double remaining;
}

/// Sequential training queue. Queued units count toward reserved population.
class RecruitQueue {
  final List<QueuedRecruit> _items = [];

  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;

  int get reservedPopulation {
    var total = 0;
    for (final i in _items) {
      total += i.unit.population;
    }
    return total;
  }

  /// 0..1 progress of the unit currently in training.
  double get headProgress {
    if (_items.isEmpty) return 0;
    final h = _items.first;
    if (h.unit.recruitTime <= 0) return 1;
    return (1 - h.remaining / h.unit.recruitTime).clamp(0.0, 1.0).toDouble();
  }

  void enqueue(UnitModel unit) => _items.add(QueuedRecruit(unit));

  /// How many of each unit id are waiting in the queue.
  Map<String, int> countsByUnit() {
    final out = <String, int>{};
    for (final i in _items) {
      out[i.unit.id] = (out[i.unit.id] ?? 0) + 1;
    }
    return out;
  }

  /// Advances training and returns units that finished during this step.
  List<UnitModel> tick(double dt) {
    final ready = <UnitModel>[];
    var left = dt;
    while (_items.isNotEmpty && left > 0) {
      final head = _items.first;
      if (head.remaining <= left) {
        left -= head.remaining;
        ready.add(head.unit);
        _items.removeAt(0);
      } else {
        head.remaining -= left;
        left = 0;
      }
    }
    return ready;
  }

  void clear() => _items.clear();
}

class Cooldown {
  Cooldown(this.duration);

  final double duration;
  double remaining = 0;

  bool get ready => remaining <= 0;

  double get fraction =>
      duration <= 0 ? 0 : (remaining / duration).clamp(0.0, 1.0).toDouble();

  void start() => remaining = duration;

  void tick(double dt) {
    if (remaining > 0) remaining = max(0.0, remaining - dt);
  }
}
