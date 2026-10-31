import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/kingdom_app.dart';
import 'services/app_state.dart';
import 'services/audio_service.dart';
import 'services/save_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final appState = AppState(saveService: SaveService(), audio: AudioService());
  runApp(KingdomsApp(appState: appState));
}
