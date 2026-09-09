import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.presetCircleId});

  final String? presetCircleId;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _content = TextEditingController();
  final _title = TextEditingController();
  late String _circleId;
  MoodTag _mood = MoodTag.happy;

  @override
  void initState() {
    super.initState();
    final circles = context.read<AppState>().circles;
    _circleId = widget.presetCircleId ?? (circles.isEmpty ? 'c_art' : circles.first.id);
  }

  @override
  void dispose() {
    _content.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('写下今日心动')),
      body: StarryBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MochiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(hintText: '给配图起个名字'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _content,
                    maxLines: 6,
                    decoration: const InputDecoration(hintText: '发生了什么有趣的事？'),
                  ),
                  const SizedBox(height: 14),
                  const Text('心情签'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MoodTag.values
                        .map(
                          (m) => MoodPill(
                            mood: m,
                            selected: _mood == m,
                            onTap: () => setState(() => _mood = m),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('投递到圈子'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.circles.map((c) {
                      final selected = c.id == _circleId;
                      return ChoiceChip(
                        label: Text('${c.emoji} ${c.name}'),
                        selected: selected,
                        onSelected: (_) => setState(() => _circleId = c.id),
                        selectedColor: AppColors.sakura,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: '发布到广场',
                    onPressed: () async {
                      if (_content.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('先写点什么再发布吧')),
                        );
                        return;
                      }
                      final err = await context.read<AppState>().composePost(
                            content: _content.text,
                            circleId: _circleId,
                            mood: _mood,
                            imageTitle: _title.text,
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
