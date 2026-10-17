import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/app_navigation.dart';
import '../utils/app_system_ui.dart';

class IntroOnboardingScreen extends StatefulWidget {
  const IntroOnboardingScreen({super.key});

  @override
  State<IntroOnboardingScreen> createState() => _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _ambient;
  double _page = 0;

  static const _slides = <_IntroSlide>[
    _IntroSlide(
      image: 'assets/images/intro_customer_1.png',
      icon: Icons.explore_rounded,
      accent: AppColors.brandPurple,
      accentSoft: Color(0xFF8B4FD4),
      title: 'Taste what\'s nearby',
      body: 'Discover home kitchens and market-fresh meals around you.',
    ),
    _IntroSlide(
      image: 'assets/images/intro_customer_2.png',
      icon: Icons.delivery_dining_rounded,
      accent: AppColors.terracotta,
      accentSoft: Color(0xFFE88B52),
      title: 'Order in seconds',
      body: 'Browse menus, customize, and track pickup or delivery live.',
    ),
    _IntroSlide(
      image: 'assets/images/intro_customer_3.png',
      icon: Icons.favorite_rounded,
      accent: AppColors.sage,
      accentSoft: Color(0xFF8B5CF6),
      title: 'Every bite helps',
      body: 'Your orders support families who cook, sell, and earn with pride.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pageController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final s in _slides) {
        precacheImage(AssetImage(s.image), context);
      }
    });
  }

  void _onScroll() {
    final p = _pageController.page;
    if (p != null && (p - _page).abs() > 0.001) {
      setState(() => _page = p);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!mounted) return;
    await AppNavigation.afterIntroCompleted(context);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page.round() >= _slides.length - 1;
    final slide = _slides[_page.round().clamp(0, _slides.length - 1)];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) {
                return CustomPaint(
                  painter: _IntroMeshPainter(
                    progress: _ambient.value,
                    accent: slide.accent,
                    accentSoft: slide.accentSoft,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSystemUi.topInset(context, 8)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _MiniLogo(),
                      const Spacer(),
                      TextButton(
                        onPressed: _complete,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.exo2(
                            fontWeight: FontWeight.w700,
                            color: slide.accent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _IntroSlideView(
                        slide: _slides[index],
                        pageOffset: _page - index,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _PageDots(count: _slides.length, page: _page),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    AppSystemUi.bottomInset(context, 28),
                  ),
                  child: _AnimatedCta(
                    label: last ? 'Start exploring' : 'Continue',
                    accent: slide.accent,
                    onPressed: last
                        ? _complete
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 480),
                              curve: Curves.easeOutCubic,
                            );
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.image,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.body,
  });

  final String image;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String title;
  final String body;
}

class _IntroSlideView extends StatelessWidget {
  const _IntroSlideView({
    required this.slide,
    required this.pageOffset,
  });

  final _IntroSlide slide;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final o = pageOffset.abs().clamp(0.0, 1.0);
    final enter = (1 - o).clamp(0.0, 1.0);
    final imageScale = 1.08 - o * 0.1;
    final imageShift = pageOffset * 48;
    final titleShift = pageOffset * 28;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const imageAspect = 3 / 2;
                var cardW = constraints.maxWidth;
                var cardH = cardW / imageAspect;
                if (cardH > constraints.maxHeight) {
                  cardH = constraints.maxHeight;
                  cardW = cardH * imageAspect;
                }

                return Center(
                  child: Transform.translate(
                    offset: Offset(imageShift, 0),
                    child: Transform.scale(
                      scale: imageScale,
                      child: Opacity(
                        opacity: (0.55 + 0.45 * enter).clamp(0.0, 1.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(imageShift * 0.15, 8 * o),
                              child: Container(
                                width: cardW * 0.92,
                                height: cardH * 0.92,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: RadialGradient(
                                    colors: [
                                      slide.accentSoft.withValues(alpha: 0.3 * enter),
                                      slide.accent.withValues(alpha: 0.04),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardW,
                              height: cardH,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: AppColors.cream,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 36,
                                      offset: const Offset(0, 16),
                                      color: slide.accent.withValues(alpha: 0.22 * enter),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        slide.image,
                                        fit: BoxFit.contain,
                                        alignment: Alignment.center,
                                      ),
                                      Positioned(
                                        right: 12,
                                        bottom: 12,
                                        child: _FloatingBadge(
                                          icon: slide.icon,
                                          accent: slide.accent,
                                          enter: enter,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          Transform.translate(
            offset: Offset(0, titleShift),
            child: Opacity(
              opacity: enter,
              child: Column(
                children: [
                  _StaggeredTitle(
                    text: slide.title,
                    accent: slide.accent,
                    progress: enter,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      color: AppColors.deepGreen.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _StaggeredTitle extends StatelessWidget {
  const _StaggeredTitle({
    required this.text,
    required this.accent,
    required this.progress,
  });

  final String text;
  final Color accent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var wi = 0; wi < words.length; wi++)
          Builder(
            builder: (context) {
              final delay = wi * 0.14;
              final t = ((progress - delay) / 0.4).clamp(0.0, 1.0);
              final curved = Curves.easeOutBack.transform(t);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - curved)),
                  child: Transform.scale(
                    scale: 0.88 + 0.12 * curved,
                    child: Text(
                      '${words[wi]}${wi < words.length - 1 ? ' ' : ''}',
                      style: GoogleFonts.exo2(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: wi == 0 ? accent : AppColors.deepGreen,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.accent,
    required this.enter,
  });

  final IconData icon;
  final Color accent;
  final double enter;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.7 + 0.3 * Curves.elasticOut.transform(enter.clamp(0.0, 1.0)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: accent.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: accent, size: 28),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.page});

  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final dist = (page - i).abs();
        final active = dist < 0.5;
        final width = active ? 32.0 : 8.0 + (1 - dist.clamp(0.0, 1.0)) * 6;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: width,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: active
                ? const LinearGradient(
                    colors: [AppColors.brandPurple, AppColors.terracotta],
                  )
                : null,
            color: active
                ? null
                : AppColors.brandPurple.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }
}

class _AnimatedCta extends StatelessWidget {
  const _AnimatedCta({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MiniLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Image.asset(
        'assets/images/made_by_maa_logo.png',
        height: 48,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _IntroMeshPainter extends CustomPainter {
  _IntroMeshPainter({
    required this.progress,
    required this.accent,
    required this.accentSoft,
  });

  final double progress;
  final Color accent;
  final Color accentSoft;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    void blob(double ox, double oy, double r, Color c) {
      final cx = size.width * ox + math.cos(t + ox * 3) * 24;
      final cy = size.height * oy + math.sin(t + oy * 2) * 20;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: 0.22), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    blob(0.15, 0.12, size.width * 0.42, accentSoft);
    blob(0.88, 0.2, size.width * 0.35, accent);
    blob(0.5, 0.78, size.width * 0.5, AppColors.amberGlow);
  }

  @override
  bool shouldRepaint(covariant _IntroMeshPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.accentSoft != accentSoft;
}
