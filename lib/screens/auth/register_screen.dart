import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../home/home_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nickname = TextEditingController();
  final _handle = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _nickname.dispose();
    _handle.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AppState>().register(
          nickname: _nickname.text,
          handle: _handle.text,
          password: _password.text,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('办理通行证')),
      body: StarryBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('给自己取一个会发光的名字。', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            MochiCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nickname,
                    decoration: const InputDecoration(hintText: '昵称，例如 星野铃'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _handle,
                    decoration: const InputDecoration(hintText: 'handle，例如 suzu'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: '口令'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: AppColors.sakura)),
                  ],
                  const SizedBox(height: 18),
                  GradientButton(
                    label: _loading ? '办理中...' : '成为新住民',
                    onPressed: _loading ? () {} : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
