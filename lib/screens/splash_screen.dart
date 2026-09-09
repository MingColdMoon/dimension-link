import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/cute_kit.dart';
import 'auth/login_screen.dart';
import 'home/home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _boot();
  }

  Future<void> _boot() async {
    final state = context.read<AppState>();
    await Future.wait([
      state.restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 1600)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            state.isLoggedIn ? const HomeShell() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StarryBackdrop(
      night: true,
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 108,
                height: 108,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.buttonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sakura.withValues(alpha: 0.45),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Text('✦', style: TextStyle(fontSize: 48, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              const Text(
                '次元链接',
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '把今天的心动，寄到平行世界',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
