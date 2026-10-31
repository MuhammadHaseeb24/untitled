/// Virtual world constants. All gameplay coordinates use this 1600x720 space,
/// which is scaled to fit any screen.
class GameConfig {
  GameConfig._();

  static const double worldWidth = 1600;
  static const double worldHeight = 720;
  static const double groundY = 560;

  static const double playerFortressX = 150;
  static const double enemyFortressX = 1450;
  static const double fortressWidth = 190;
  static const double fortressHeight = 280;

  /// Depth lanes (visual y offsets). Units only block allies in the same lane.
  static const List<double> laneOffsets = [-26, -13, 0, 13, 26];

  static const double unitSpacing = 24;
  static const double defendAnchorDistance = 260;
  static const double defendRadius = 320;

  static const double retargetInterval = 0.2;
  static const double aiDecisionInterval = 0.5;
  static const double hudInterval = 0.08;
  static const double maxStep = 0.05;
  static const double maxFrameDt = 0.1;
  static const double spawnDuration = 0.45;
  static const double deathDuration = 0.7;
  static const double recoverTime = 0.25;
  static const double fortressThreatRadius = 420;
  static const double endDelaySeconds = 1.6;
  static const int waveBonusPopulation = 6;
}
