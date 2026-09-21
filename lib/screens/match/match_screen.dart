import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../network/api_exception.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../messages/chat_screen.dart';
import '../profile/user_profile_screen.dart';
import 'match_deck.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _deckKey = GlobalKey<SwipeMatchDeckState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.matches.isEmpty && !state.matchLoading) {
        state.loadMatches();
      }
    });
  }

  Future<void> _openProfile(MatchCandidate candidate) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => UserProfileScreen(userId: candidate.userId),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openChat(MatchCandidate candidate) async {
    try {
      final conversation = await context.read<AppState>().ensureConversation(candidate.userId);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation.id)),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _like(MatchCandidate candidate) async {
    await _likeAll([candidate]);
  }

  Future<void> _likeAll(List<MatchCandidate> batch) async {
    if (batch.isEmpty) {
      return;
    }
    final liked = await context.read<AppState>().likeMatches([
      for (final item in batch) item.userId,
    ]);
    if (!mounted || liked.isEmpty) {
      return;
    }
    if (liked.any((item) => item.isResonance)) {
      return;
    }
    final names = liked.map((item) => item.user.nickname).join('、');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已把心动寄给 $names')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;

    return StarryBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxHeight < 680;
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, compact ? 72 : 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CuteAvatar(
                            emoji: me.emoji,
                            accentIndex: me.accentIndex,
                            size: compact ? 36 : 42,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('次元匹配', style: TextStyle(fontSize: 26, height: 1.1)),
                                Text(
                                  'AI 把附近、同好与默契的人织到你面前',
                                  style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 14),
                      Align(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _ModeSwitcher(
                            mode: state.matchMode,
                            onChanged: (mode) => context.read<AppState>().setMatchMode(mode),
                          ),
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: Text(
                              state.matchMode.hint,
                              key: ValueKey(state.matchMode),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: compact ? 8 : 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _buildStage(state),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (state.matches.isNotEmpty)
                        Align(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _ActionRow(deckKey: _deckKey, compact: compact),
                          ),
                        ),
                      if (!compact) ...[
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            '一行三张 · 点卡片看主页 · 心动收下当前三张',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.inkMuted, fontSize: 11, height: 1.35),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (state.resonance != null)
                  _ResonanceOverlay(
                    me: me,
                    candidate: state.resonance!,
                    onContinue: () => context.read<AppState>().clearResonance(),
                    onChat: () {
                      final candidate = state.resonance!;
                      context.read<AppState>().clearResonance();
                      _openChat(candidate);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStage(AppState state) {
    if (state.matches.isEmpty) {
      if (state.matchLoading) {
        return const _ScanningHint(key: ValueKey('scanning'));
      }
      return _EmptyDeck(
        key: const ValueKey('empty'),
        message: state.matchError ?? '暂时没有新的次元信号',
        onRefresh: () => context.read<AppState>().loadMatches(refresh: true),
      );
    }
    return Align(
      key: const ValueKey('deck'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SwipeMatchDeck(
          key: _deckKey,
          candidates: state.matches,
          onLike: _like,
          onLikeAll: _likeAll,
          onPass: (candidate) => context.read<AppState>().passMatch(candidate.userId),
          onOpen: _openProfile,
        ),
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.mode, required this.onChanged});

  final MatchMode mode;
  final ValueChanged<MatchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / MatchMode.values.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + mode.index * (2 / (MatchMode.values.length - 1)), 0),
                child: Container(
                  width: width,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final item in MatchMode.values)
                    Expanded(
                      child: InkWell(
                        key: Key('match-mode-${item.key}'),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onChanged(item),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontFamily: 'ZCOOLKuaiLe',
                                fontSize: 14,
                                color: mode == item ? Colors.white : AppColors.inkMuted,
                              ),
                              child: Text(item.label),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.deckKey, this.compact = false});

  final GlobalKey<SwipeMatchDeckState> deckKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundAction(
          key: const Key('match-pass'),
          icon: Icons.close_rounded,
          color: AppColors.inkMuted,
          compact: compact,
          onTap: () => deckKey.currentState?.passTop(),
        ),
        _RoundAction(
          key: const Key('match-like'),
          icon: Icons.favorite_rounded,
          color: AppColors.sakura,
          big: true,
          compact: compact,
          onTap: () => deckKey.currentState?.likeTop(),
        ),
      ],
    );
  }
}

class _RoundAction extends StatefulWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.big = false,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool big;
  final bool compact;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.big
        ? (widget.compact ? 58.0 : 72.0)
        : (widget.compact ? 46.0 : 56.0);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.color, size: widget.big ? 32 : 24),
        ),
      ),
    );
  }
}

class _ScanningHint extends StatelessWidget {
  const _ScanningHint({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.starPurple),
          ),
          SizedBox(height: 14),
          Text('AI 正在扫描附近的次元信号…', style: TextStyle(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({super.key, required this.message, required this.onRefresh});

  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: MochiCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✦', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(message, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                GradientButton(label: '换一批信号', onPressed: onRefresh),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResonanceOverlay extends StatefulWidget {
  const _ResonanceOverlay({
    required this.me,
    required this.candidate,
    required this.onContinue,
    required this.onChat,
  });

  final AppUser me;
  final MatchCandidate candidate;
  final VoidCallback onContinue;
  final VoidCallback onChat;

  @override
  State<_ResonanceOverlay> createState() => _ResonanceOverlayState();
}

class _ResonanceOverlayState extends State<_ResonanceOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC2A1848),
        child: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: _BurstField())),
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.72, end: 1).animate(pop),
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: MochiCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('次元共振', style: TextStyle(fontSize: 28, color: AppColors.sakura)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CuteAvatar(
                                emoji: widget.me.emoji,
                                accentIndex: widget.me.accentIndex,
                                size: 64,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('♡', style: TextStyle(fontSize: 28, color: AppColors.sakura)),
                              ),
                              CuteAvatar(
                                emoji: widget.candidate.user.emoji,
                                accentIndex: widget.candidate.user.accentIndex,
                                size: 64,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '与 ${widget.candidate.user.nickname} 的默契 ${widget.candidate.score}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.candidate.reason,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          GradientButton(label: '把心动寄过去', onPressed: widget.onChat),
                          TextButton(onPressed: widget.onContinue, child: const Text('继续探索')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurstField extends StatefulWidget {
  const _BurstField();

  @override
  State<_BurstField> createState() => _BurstFieldState();
}

class _BurstFieldState extends State<_BurstField> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _BurstPainter(progress: _controller.value)),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(21);
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 18; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final dist = 40 + (progress * 160 + random.nextDouble() * 80) % 180;
      final offset = Offset(center.dx + math.cos(angle) * dist, center.dy + math.sin(angle) * dist);
      canvas.drawCircle(
        offset,
        2.4 + random.nextDouble() * 2,
        Paint()..color = Colors.white.withValues(alpha: 0.18 + random.nextDouble() * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.progress != progress;
}
