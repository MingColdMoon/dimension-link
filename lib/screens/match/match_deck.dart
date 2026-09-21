import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';

/// 一行平铺三张推荐卡，点击进主页，心动 / 跳过用底部按钮或滑动。
class SwipeMatchDeck extends StatefulWidget {
  const SwipeMatchDeck({
    super.key,
    required this.candidates,
    required this.onLike,
    required this.onLikeAll,
    required this.onPass,
    required this.onOpen,
  });

  final List<MatchCandidate> candidates;
  final ValueChanged<MatchCandidate> onLike;
  final ValueChanged<List<MatchCandidate>> onLikeAll;
  final ValueChanged<MatchCandidate> onPass;
  final ValueChanged<MatchCandidate> onOpen;

  @override
  State<SwipeMatchDeck> createState() => SwipeMatchDeckState();
}

class SwipeMatchDeckState extends State<SwipeMatchDeck> {
  List<MatchCandidate> get _visible => widget.candidates.take(3).toList();

  MatchCandidate? get top => _visible.isEmpty ? null : _visible.first;

  void likeTop() {
    final batch = List<MatchCandidate>.from(_visible);
    if (batch.isEmpty) {
      return;
    }
    HapticFeedback.lightImpact();
    widget.onLikeAll(batch);
  }

  void passTop() => _decide(top, liked: false);

  void _decide(MatchCandidate? candidate, {required bool liked}) {
    if (candidate == null) {
      return;
    }
    HapticFeedback.lightImpact();
    if (liked) {
      widget.onLike(candidate);
    } else {
      widget.onPass(candidate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    if (items.isEmpty) {
      return const SizedBox.expand();
    }
    return KeyedSubtree(
      key: const Key('match-deck'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = constraints.maxWidth < 420 ? 8.0 : 12.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: _TiledCard(
                    candidate: items[i],
                    onOpen: () => widget.onOpen(items[i]),
                    onLike: () => _decide(items[i], liked: true),
                    onPass: () => _decide(items[i], liked: false),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TiledCard extends StatelessWidget {
  const _TiledCard({
    required this.candidate,
    required this.onOpen,
    required this.onLike,
    required this.onPass,
  });

  final MatchCandidate candidate;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      onHorizontalDragEnd: (details) {
        final vx = details.primaryVelocity ?? 0;
        if (vx > 420) {
          onLike();
        } else if (vx < -420) {
          onPass();
        }
      },
      child: MatchPersonaCard(candidate: candidate),
    );
  }
}

class MatchPersonaCard extends StatelessWidget {
  const MatchPersonaCard({
    super.key,
    required this.candidate,
    this.stamp = 0,
  });

  final MatchCandidate candidate;
  final double stamp;

  @override
  Widget build(BuildContext context) {
    final user = candidate.user;
    final hue = (280 + user.accentIndex * 18) % 360;
    final aura = MatchAura.of(candidate.borderTier);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 168;
        final radius = narrow ? 24.0 : 32.0;
        final avatarSize = (constraints.maxWidth * (narrow ? 0.5 : 0.38)).clamp(
          narrow ? 48.0 : 64.0,
          narrow ? 72.0 : 104.0,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: aura.color, width: aura.borderWidth),
            boxShadow: [
              BoxShadow(
                color: aura.color.withValues(alpha: aura.glowAlpha),
                blurRadius: aura.glowBlur,
                spreadRadius: aura.spread,
              ),
              BoxShadow(
                color: AppColors.starPurple.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 3),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSLColor.fromAHSL(1, hue.toDouble(), 0.62, 0.72).toColor(),
                        HSLColor.fromAHSL(1, (hue + 46) % 360, 0.55, 0.58).toColor(),
                      ],
                    ),
                  ),
                ),
                IgnorePointer(child: CustomPaint(painter: _CardSparklePainter(hue: hue))),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        AppColors.card.withValues(alpha: 0.97),
                      ],
                      stops: const [0.48, 0.78],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(narrow ? 8 : 14, 10, narrow ? 8 : 14, 0),
                      child: Row(
                        children: [
                          if (candidate.online) _OnlineMark(compact: narrow),
                          const Spacer(),
                          _ScoreBadge(score: candidate.score, color: aura.color),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: CuteAvatar(
                          emoji: user.emoji,
                          accentIndex: user.accentIndex,
                          size: avatarSize,
                        ),
                      ),
                    ),
                    _PersonaFooter(candidate: candidate, narrow: narrow),
                  ],
                ),
                if (stamp.abs() > 0.18)
                  Positioned(
                    top: 72,
                    left: stamp > 0 ? 12 : null,
                    right: stamp < 0 ? 12 : null,
                    child: Opacity(
                      opacity: stamp.abs().clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: stamp > 0 ? -0.28 : 0.28,
                        child: _DecisionStamp(liked: stamp > 0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonaFooter extends StatelessWidget {
  const _PersonaFooter({required this.candidate, required this.narrow});

  final MatchCandidate candidate;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final user = candidate.user;
    final hobbies = candidate.hobbies.take(narrow ? 2 : 3).toList();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(narrow ? 8 : 14, 8, narrow ? 8 : 14, narrow ? 10 : 14),
      color: AppColors.card.withValues(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: narrow ? 15 : 22, height: 1.15),
          ),
          const SizedBox(height: 2),
          Text(
            narrow ? candidate.shortDistanceLabel : candidate.distanceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.starPurple, fontSize: narrow ? 11 : 13),
          ),
          if (!narrow) ...[
            Text(
              user.handle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ],
          ],
          if (hobbies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final hobby in hobbies)
                  _SoftChip(
                    compact: narrow,
                    color: candidate.sharedHobbies.contains(hobby)
                        ? AppColors.sakuraSoft
                        : Colors.white.withValues(alpha: 0.86),
                    child: Text(
                      hobby,
                      style: TextStyle(
                        fontSize: narrow ? 10 : 11,
                        color: candidate.sharedHobbies.contains(hobby)
                            ? AppColors.sakura
                            : AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (!narrow && candidate.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              candidate.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardSparklePainter extends CustomPainter {
  _CardSparklePainter({required this.hue});

  final int hue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), 28, paint);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.38), 12, paint);
  }

  @override
  bool shouldRepaint(covariant _CardSparklePainter oldDelegate) => oldDelegate.hue != hue;
}

class _OnlineMark extends StatelessWidget {
  const _OnlineMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.mint,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.6),
          boxShadow: [
            BoxShadow(color: AppColors.mint.withValues(alpha: 0.55), blurRadius: 6),
          ],
        ),
      );
    }
    return const _SoftChip(
      color: AppColors.mint,
      child: Text('在线', style: TextStyle(fontSize: 11, color: AppColors.ink)),
    );
  }
}

/// 匹配分边框：白 < 紫 < 金 < 红，越高越亮。
class MatchAura {
  const MatchAura({
    required this.color,
    required this.borderWidth,
    required this.glowBlur,
    required this.glowAlpha,
    required this.spread,
  });

  final Color color;
  final double borderWidth;
  final double glowBlur;
  final double glowAlpha;
  final double spread;

  static MatchAura of(MatchBorderTier tier) {
    return switch (tier) {
      MatchBorderTier.white => const MatchAura(
          color: Color(0xFFFFF8FF),
          borderWidth: 2,
          glowBlur: 10,
          glowAlpha: 0.42,
          spread: 0,
        ),
      MatchBorderTier.purple => const MatchAura(
          color: Color(0xFFB79CFF),
          borderWidth: 2.6,
          glowBlur: 16,
          glowAlpha: 0.62,
          spread: 0.6,
        ),
      MatchBorderTier.gold => const MatchAura(
          color: Color(0xFFFFD56A),
          borderWidth: 3.2,
          glowBlur: 22,
          glowAlpha: 0.78,
          spread: 1.2,
        ),
      MatchBorderTier.red => const MatchAura(
          color: Color(0xFFFF4B6E),
          borderWidth: 3.8,
          glowBlur: 28,
          glowAlpha: 0.88,
          spread: 1.8,
        ),
    };
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.score,
    required this.color,
  });

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.85)),
      ),
      child: Text(
        '$score',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color.computeLuminance() > 0.72 ? AppColors.ink : color,
          fontSize: 12,
          height: 1.1,
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.child,
    required this.color,
    this.compact = false,
  });

  final Widget child;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
      ),
      child: child,
    );
  }
}

class _DecisionStamp extends StatelessWidget {
  const _DecisionStamp({required this.liked});

  final bool liked;

  @override
  Widget build(BuildContext context) {
    final color = liked ? AppColors.sakura : AppColors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        liked ? '心动' : '下一个',
        style: TextStyle(color: color, fontSize: 22, letterSpacing: 2),
      ),
    );
  }
}
