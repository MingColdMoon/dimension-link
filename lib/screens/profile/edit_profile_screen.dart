import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/cute_kit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nickname;
  late final TextEditingController _bio;
  late final TextEditingController _signature;

  @override
  void initState() {
    super.initState();
    final me = context.read<AppState>().me;
    _nickname = TextEditingController(text: me.nickname);
    _bio = TextEditingController(text: me.bio);
    _signature = TextEditingController(text: me.signature);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    _signature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑资料')),
      body: StarryBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MochiCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nickname,
                    decoration: const InputDecoration(hintText: '昵称'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bio,
                    decoration: const InputDecoration(hintText: '简介'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _signature,
                    decoration: const InputDecoration(hintText: '签名'),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: '保存',
                    onPressed: () async {
                      final err = await context.read<AppState>().updateProfile(
                            nickname: _nickname.text,
                            bio: _bio.text,
                            signature: _signature.text,
                          );
                      if (!context.mounted) {
                        return;
                      }
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        return;
                      }
                      Navigator.of(context).pop();
                    },
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
