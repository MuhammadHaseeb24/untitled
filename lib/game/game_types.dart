enum Team { player, enemy }

extension TeamX on Team {
  Team get opponent => this == Team.player ? Team.enemy : Team.player;

  /// +1 when the team marches to the right, -1 to the left.
  double get direction => this == Team.player ? 1.0 : -1.0;
}

enum Command { garrison, defend, attack }

enum RecruitResult { ok, notActive, locked, noGold, populationFull }

enum AbilityResult { ok, notActive, locked, cooling, noTarget }
