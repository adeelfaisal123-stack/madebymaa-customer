import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/app_navigation.dart';
import '../utils/app_system_ui.dart';
import '../utils/app_version.dart';
import '../widgets/floating_food_icons.dart';

/// Splash: white field, logo, animated title + pills (seller layout, light theme).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _shimmer;
  late final AnimationController _float;
  Timer? _navTimer;
  bool _navigating = false;

  static const _assetLogo = AssetImage('assets/images/made_by_maa_logo.png');

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(_assetLogo, context);
      _reveal.forward();
      _navTimer = Timer(const Duration(milliseconds: 3800), _goNext);
    });
  }

  Future<void> _goNext() async {
    if (_navigating || !mounted) return;
    _navigating = true;

    final next = await AppNavigation.postSplashDestination();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuad,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _reveal.dispose();
    _shimmer.dispose();
    _float.dispose();
    super.dispose();
  }

  TextStyle _exo(
    double size,
    FontWeight w, {
    Color? color,
    double height = 1,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.exo2(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final logoWidth = math.min(MediaQuery.sizeOf(context).width * 0.78, 320.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _SplashBackground(reveal: _reveal, float: _float),
            const Positioned.fill(
              child: FloatingFoodIcons(
                opacity: 0.14,
                count: 48,
                minSize: 16,
                maxSize: 36,
                seed: 7,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(28, top + 20, 28, bottom + 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          _LogoCard(
                            reveal: _reveal,
                            float: _float,
                            logoWidth: logoWidth,
                          ),
                          const SizedBox(height: 36),
                          _TaglineBadges(
                            reveal: _reveal,
                            shimmer: _shimmer,
                            exo: _exo,
                          ),
                          const SizedBox(height: 48),
                          _LoadingFooter(reveal: _reveal, exo: _exo),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom + 12,
              child: Center(
                child: Text(
                  AppVersion.label,
                  style: _exo(
                    11,
                    FontWeight.w600,
                    color: AppColors.deepGreen.withValues(alpha: 0.4),
                    letterSpacing: 0.4,
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

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({
    required this.reveal,
    required this.float,
  });

  final Animation<double> reveal;
  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([reveal, float]),
      builder: (context, _) {
        final p = Curves.easeOut.transform(reveal.value.clamp(0, 1));
        final drift = Curves.easeInOut.transform(float.value);

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFEFB),
                    Color(0xFFFBF7F0),
                    Color(0xFFF6F0E6),
                    Color(0xFFFFFEFB),
                  ],
                  stops: [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.1 - 0.15 * drift, -0.72),
                  radius: 0.95,
                  colors: [
                    const Color(0xFFFFF6E8).withValues(alpha: 0.85 * p),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.85 + 0.1 * drift, 0.55),
                  radius: 0.7,
                  colors: [
                    const Color(0xFFF5EDE0).withValues(alpha: 0.7 * p),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _SplashOrbsPainter(
                progress: p,
                drift: drift,
              ),
              size: Size.infinite,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFEFB).withValues(alpha: 0.65),
                    Colors.transparent,
                    const Color(0xFFF0E8DC).withValues(alpha: 0.35),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SplashOrbsPainter extends CustomPainter {
  _SplashOrbsPainter({required this.progress, required this.drift});

  final double progress;
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    void orb(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final w = size.width;
    final h = size.height;

    orb(
      Offset(w * (0.12 + 0.04 * drift), h * (0.18 - 0.03 * drift)),
      w * 0.22 * progress,
      const Color(0xFFFFF0D8).withValues(alpha: 0.55),
    );
    orb(
      Offset(w * (0.88 - 0.05 * drift), h * (0.28 + 0.04 * drift)),
      w * 0.18 * progress,
      const Color(0xFFEDE6DA).withValues(alpha: 0.65),
    );
    orb(
      Offset(w * 0.5, h * (0.78 + 0.02 * drift)),
      w * 0.35 * progress,
      const Color(0xFFF2E8D8).withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashOrbsPainter old) =>
      old.progress != progress || old.drift != drift;
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({
    required this.reveal,
    required this.float,
    required this.logoWidth,
  });

  final Animation<double> reveal;
  final Animation<double> float;
  final double logoWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([reveal, float]),
      builder: (context, _) {
        final enter = Curves.elasticOut
            .transform((reveal.value / 0.38).clamp(0.0, 1.0));
        final bob = 5 * math.sin(float.value * math.pi * 2);

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(
            scale: enter.clamp(0.0, 1.12),
            child: Opacity(
              opacity: (reveal.value / 0.2).clamp(0.0, 1.0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  AppColors.brandPurple,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/made_by_maa_logo.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaglineBadges extends StatelessWidget {
  const _TaglineBadges({
    required this.reveal,
    required this.shimmer,
    required this.exo,
  });

  final Animation<double> reveal;
  final Animation<double> shimmer;
  final TextStyle Function(
    double size,
    FontWeight w, {
    Color? color,
    double height,
    double letterSpacing,
  }) exo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([reveal, shimmer]),
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _badge(
              index: 0,
              label: 'Eat Right',
              icon: Icons.restaurant_rounded,
              accent: AppColors.terracotta,
            ),
            const SizedBox(width: 10),
            _badge(
              index: 1,
              label: 'Eat by Maa',
              icon: Icons.favorite_rounded,
              accent: AppColors.brandPurple,
              shimmerBrand: true,
            ),
          ],
        );
      },
    );
  }

  Widget _badge({
    required int index,
    required String label,
    required IconData icon,
    required Color accent,
    bool shimmerBrand = false,
  }) {
    final start = 0.38 + index * 0.12;
    final raw = ((reveal.value - start) / 0.18).clamp(0.0, 1.0);
    final curved = Curves.easeOutBack.transform(raw);
    final opacity = curved.clamp(0.0, 1.0);
    final scale = 0.88 + 0.12 * curved.clamp(0.0, 1.0);

    Widget labelWidget;
    if (shimmerBrand) {
      // "Eat " plain + shimmer on "by Maa"
      const prefix = 'Eat ';
      const brand = 'by Maa';
      labelWidget = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: prefix,
              style: exo(15, FontWeight.w700, color: AppColors.deepGreen),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  final t = -0.3 + 1.6 * shimmer.value;
                  return LinearGradient(
                    colors: const [
                      AppColors.brandPurple,
                      Color(0xFF9B6FD4),
                      AppColors.brandPurpleDeep,
                      AppColors.brandPurple,
                    ],
                    stops: [
                      (t - 0.4).clamp(0.0, 1.0),
                      (t - 0.1).clamp(0.0, 1.0),
                      (t + 0.15).clamp(0.0, 1.0),
                      (t + 0.45).clamp(0.0, 1.0),
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  brand,
                  style: exo(15, FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      labelWidget = Text(
        label,
        style: exo(15, FontWeight.w800, color: AppColors.deepGreen),
      );
    }

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.12),
                accent.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 6),
                color: accent.withValues(alpha: 0.1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              labelWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter({required this.reveal, required this.exo});

  final Animation<double> reveal;
  final TextStyle Function(
    double size,
    FontWeight w, {
    Color? color,
    double height,
    double letterSpacing,
  }) exo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final visible = reveal.value > 0.7;
        return Opacity(
          opacity: visible ? 1 : 0,
          child: Column(
            children: [
              Text(
                'Finding kitchens near you…',
                style: exo(
                  12,
                  FontWeight.w600,
                  color: AppColors.deepGreen.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor:
                        AppColors.brandPurple.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.brandPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
