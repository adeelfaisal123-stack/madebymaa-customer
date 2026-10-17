import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Home screen footer — clean brand lockup with subtle heart accent.
class WithLoveFromMaaFooter extends StatelessWidget {
  const WithLoveFromMaaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const WithLoveFromFooter(name: 'Maa');
  }
}

/// Footer lockup: “With love from {name}” — used on home and kitchen pages.
class WithLoveFromFooter extends StatelessWidget {
  const WithLoveFromFooter({
    super.key,
    required this.name,
    this.fssaiNumber,
    this.bottomSpacing = 28,
  });

  final String name;
  final String? fssaiNumber;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return SizedBox(height: bottomSpacing);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 40, 24, bottomSpacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _FooterDivider(),
          const SizedBox(height: 26),
          Text(
            'WITH LOVE',
            style: AppFonts.style(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.4,
              height: 1,
              color: AppColors.deepGreen.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 10),
          _FromNameLockup(name: trimmed),
          if (fssaiNumber != null && fssaiNumber!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'FSSAI Lic. No. ${fssaiNumber!.trim()}',
              textAlign: TextAlign.center,
              style: AppFonts.style(
                context,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                height: 1.35,
                color: AppColors.deepGreen.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FromNameLockup extends StatelessWidget {
  const _FromNameLockup({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final nameLength = name.length;
    final nameFontSize = nameLength > 28
        ? 22.0
        : nameLength > 18
        ? 26.0
        : 30.0;

    final fromStyle = AppFonts.style(
      context,
      fontSize: nameFontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      height: 1.15,
      color: AppColors.deepGreen.withValues(alpha: 0.88),
    );
    final accentStyle = AppFonts.style(
      context,
      fontSize: nameFontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.15,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('From ', style: fromStyle),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brandPurple,
              AppColors.brandPurpleDeep,
            ],
          ).createShader(bounds),
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: accentStyle.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _FooterDivider extends StatelessWidget {
  const _FooterDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepGreen.withValues(alpha: 0),
                  AppColors.deepGreen.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _HeartbeatHeart(),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepGreen.withValues(alpha: 0.12),
                  AppColors.deepGreen.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeartbeatHeart extends StatefulWidget {
  const _HeartbeatHeart();

  @override
  State<_HeartbeatHeart> createState() => _HeartbeatHeartState();
}

class _HeartbeatHeartState extends State<_HeartbeatHeart>
    with SingleTickerProviderStateMixin {
  static const _iconSize = 22.0;

  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.14, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 60,
      ),
    ]).animate(_controller);
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
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value,
          child: Icon(
            Icons.favorite_rounded,
            size: _iconSize,
            color: AppColors.terracotta.withValues(alpha: 0.82),
          ),
        );
      },
    );
  }
}
