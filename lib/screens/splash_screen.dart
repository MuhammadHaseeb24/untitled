import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_theme.dart';
import '../widgets/ember_backdrop.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (!mounted) return;
    setState(() => _error = null);
    final app = AppScope.read(context);
    final bundle = DefaultAssetBundle.of(context);
    try {
      await Future.wait<void>([
        app.load(bundle),
        Future<void>.delayed(const Duration(milliseconds: 1800)),
      ]).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const MainMenuScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on TimeoutException {
      if (mounted)
        setState(() => _error = 'Loading took too long. Please try again.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load game data:\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmberBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.gold, AppColors.ember],
                    ).createShader(r),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 96,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'KINGDOMS OF EMBER',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Command the flame. Break the crown.',
                    style: TextStyle(
                      color: AppColors.textDim,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 26),
                  if (_error == null)
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.ember,
                      ),
                    )
                  else ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.bad),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 52),
                      ),
                      onPressed: _boot,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
