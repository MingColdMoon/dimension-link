import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../home/home_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController(text: '星野铃');
  final _password = TextEditingController(text: '123456');
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AppState>().login(_name.text, _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StarryBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            children: [
              const Text('欢迎回来', style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
              const SizedBox(height: 6),
              const Text('次元链接', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 6),
              const Text('用一枚通行证，接通所有二次元社交。'),
              const SizedBox(height: 28),
              MochiCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.auto_awesome, color: AppColors.sakura),
                        hintText: '昵称或 @handle',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.starPurple),
                        hintText: '通行证口令',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: AppColors.sakura)),
                    ],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: _loading ? '传送中...' : '进入次元',
                      onPressed: _loading ? () {} : _submit,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '演示账号：星野铃 / 123456',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('还没有通行证？注册新住民'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
