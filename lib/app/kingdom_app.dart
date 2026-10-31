import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../services/app_state.dart';
import 'app_scope.dart';
import 'app_theme.dart';

class KingdomsApp extends StatelessWidget {
  const KingdomsApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: appState,
      child: MaterialApp(
        title: 'Kingdoms of Ember',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const SplashScreen(),
      ),
    );
  }
}
