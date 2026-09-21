import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../chat/chat_media.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import 'group_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadConversationMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _afterSend(String? err) async {
    if (!mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _text.clear();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openGroupSettings() async {
    final left = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupSettingsScreen(conversationId: widget.conversationId),
      ),
    );
    if (left == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openImageSheet(Conversation cv) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('发一张图', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              const Text('插画卡随时能发，相册图会上传到次元', style: TextStyle(color: AppColors.inkMuted, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: chatIllustrations.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final card = chatIllustrations[index];
                    return GestureDetector(
                      key: Key('chat-illustration-${card.hue}'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final err = await context.read<AppState>().sendChatImage(
                          cv.id,
                          imageUrl: card.url,
                          caption: card.title,
                        );
                        await _afterSend(err);
                      },
                      child: SizedBox(
                        width: 148,
                        child: IllustratedBanner(hue: card.hue, title: card.title, height: 108),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('chat-pick-gallery'),
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.starPurple),
                title: const Text('从相册选择'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickGallery(cv);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickGallery(Conversation cv) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('图片请控制在 2MB 以内')));
        return;
      }
      final mime = file.mimeType ?? 'image/jpeg';
      final err = await context.read<AppState>().sendChatImage(
        cv.id,
        imageBase64: base64Encode(bytes),
        mimeType: mime,
      );
      await _afterSend(err);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('当前设备请改用插画卡发图')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cv = state.findConversation(widget.conversationId);
    if (cv == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('私信')),
        body: const StarryBackdrop(
          child: Center(child: EmptyHint(text: '正在打开这条私信…')),
        ),
      );
    }
    final meId = state.currentUserId;
    final canSpeak = cv.canSpeak(meId);
    final hint = !canSpeak
        ? (cv.isMemberMuted(meId) ? '你已被禁言' : '全员禁言中')
        : '说点软乎乎的话...';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cv.displayName),
            if (cv.isGroup)
              Text(
                cv.members.map((user) => user.nickname).join('、'),
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
          ],
        ),
        actions: [
          if (cv.isGroup)
            IconButton(
              key: const Key('group-settings'),
              tooltip: '群资料',
              onPressed: _openGroupSettings,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
        ],
      ),
      body: StarryBackdrop(
        child: Column(
          children: [
            if (cv.isGroup && (cv.groupMuted || !canSpeak))
              Container(
                width: double.infinity,
                color: AppColors.sakuraSoft.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  cv.isMemberMuted(meId) ? '你已被管理员禁言' : '全员禁言中，群主和管理员仍可发言',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: cv.messages.length,
                itemBuilder: (context, index) {
                  final msg = cv.messages[index];
                  if (msg.isSystem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          msg.text,
                          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                        ),
                      ),
                    );
                  }
                  final mine = msg.senderId == meId;
                  final sender = state.findUser(msg.senderId);
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        gradient: mine && !msg.isImage ? AppColors.buttonGradient : null,
                        color: mine ? (msg.isImage ? Colors.transparent : null) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cv.isGroup && !mine)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                sender?.nickname ?? '住民',
                                style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                              ),
                            ),
                          if (msg.isImage)
                            _ChatImage(imageUrl: msg.imageUrl, caption: msg.text, mine: mine)
                          else
                            Text(
                              msg.text,
                              style: TextStyle(color: mine ? Colors.white : AppColors.ink),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('send-image'),
                      tooltip: '发图片',
                      onPressed: canSpeak ? () => _openImageSheet(cv) : null,
                      icon: const Icon(Icons.image_outlined, color: AppColors.starPurple),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _text,
                        enabled: canSpeak,
                        decoration: InputDecoration(hintText: hint),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.starPurple),
                      onPressed: canSpeak
                          ? () async {
                              final err = await context.read<AppState>().sendMessage(cv.id, _text.text);
                              await _afterSend(err);
                            }
                          : null,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatImage extends StatelessWidget {
  const _ChatImage({
    required this.imageUrl,
    required this.caption,
    required this.mine,
  });

  final String imageUrl;
  final String caption;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final hue = parseIllustrationHue(imageUrl);
    final title = caption == '[图片]' || caption.isEmpty ? '插画卡' : caption;
    Widget image;
    if (hue != null) {
      image = IllustratedBanner(hue: hue, title: title, height: 132);
    } else {
      final data = decodeDataImage(imageUrl);
      if (data != null) {
        image = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(data, height: 160, fit: BoxFit.cover),
        );
      } else {
        image = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            resolveChatMediaUrl(imageUrl),
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => IllustratedBanner(hue: mine ? 280 : 200, title: title, height: 132),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image,
        if (caption.isNotEmpty && caption != '[图片]' && hue == null) ...[
          const SizedBox(height: 6),
          Text(caption, style: TextStyle(color: mine ? AppColors.ink : AppColors.ink, fontSize: 13)),
        ],
      ],
    );
  }
}
