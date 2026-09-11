import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';

/// 渐变星空背景，点缀漂浮光斑。
class StarryBackdrop extends StatelessWidget {
  const StarryBackdrop({
    super.key,
    required this.child,
    this.night = false,
  });

  final Widget child;
  final bool night;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: night ? AppColors.nightGradient : AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _SparkleField())),
          child,
        ],
      ),
    );
  }
}

class _SparkleField extends StatefulWidget {
  const _SparkleField();

  @override
  State<_SparkleField> createState() => _SparkleFieldState();
}

class _SparkleFieldState extends State<_SparkleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
      builder: (context, _) => CustomPaint(
        painter: _SparklePainter(progress: _controller.value),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    for (var i = 0; i < 28; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = (random.nextDouble() * size.height + progress * 40) % size.height;
      final radius = 1.2 + random.nextDouble() * 2.4;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18 + random.nextDouble() * 0.35);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 圆角软糖卡片。
class MochiCard extends StatelessWidget {
  const MochiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.starPurple.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// 二次元头像：渐变圆底 + 表情。
class CuteAvatar extends StatelessWidget {
  const CuteAvatar({
    super.key,
    required this.emoji,
    required this.accentIndex,
    this.size = 48,
    this.onTap,
  });

  final String emoji;
  final int accentIndex;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarPalette[accentIndex % AppColors.avatarPalette.length];
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.65)],
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.42)),
    );
    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.sakura.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoodPill extends StatelessWidget {
  const MoodPill({super.key, required this.mood, this.selected = false, this.onTap});

  final MoodTag mood;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.sakura : AppColors.sakuraSoft.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${mood.symbol} ${mood.label}',
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// 动态配图：渐变插画卡，不依赖网络图。
class IllustratedBanner extends StatelessWidget {
  const IllustratedBanner({
    super.key,
    required this.hue,
    required this.title,
    this.height = 168,
  });

  final int hue;
  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    final a = HSLColor.fromAHSL(1, hue.toDouble(), 0.62, 0.72).toColor();
    final b = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.55, 0.62).toColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [a, b],
                ),
              ),
            ),
            CustomPaint(painter: _DoodlePainter(hue: hue)),
            Positioned(
              left: 16,
              bottom: 14,
              right: 16,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter({required this.hue});

  final int hue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.28), 36, paint);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.7), 18, paint);
    final star = Path();
    final cx = size.width * 0.55;
    final cy = size.height * 0.42;
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 4 * math.pi / 5;
      final point = Offset(cx + math.cos(angle) * 22, cy + math.sin(angle) * 22);
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => oldDelegate.hue != hue;
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 16),
        ),
      ),
    );
  }
}
