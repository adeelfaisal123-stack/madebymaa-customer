import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ambient layer of gently floating food / kitchen icons.
///
/// Fills the available space and scatters semi-transparent icons that bob and
/// rotate continuously. Purely decorative — wrapped in [IgnorePointer] so it
/// never intercepts taps. Positions are deterministic for a given [seed] so the
/// layout stays stable across rebuilds.
class FloatingFoodIcons extends StatefulWidget {
  const FloatingFoodIcons({
    super.key,
    this.color = AppColors.floatingIconSilver,
    this.opacity = 0.12,
    this.count = 14,
    this.minSize = 20,
    this.maxSize = 36,
    this.seed = 7,
    this.entrance = true,
  });

  final Color color;
  final double opacity;
  final int count;
  final double minSize;
  final double maxSize;
  final int seed;

  /// Plays a one-time staggered scale + fade "pop-in" when first shown.
  final bool entrance;

  static const List<IconData> _icons = [
    Icons.restaurant_rounded,
    Icons.local_pizza_rounded,
    Icons.ramen_dining_rounded,
    Icons.bakery_dining_rounded,
    Icons.coffee_rounded,
    Icons.icecream_rounded,
    Icons.lunch_dining_rounded,
    Icons.cake_rounded,
    Icons.local_cafe_rounded,
    Icons.kebab_dining_rounded,
    Icons.set_meal_rounded,
    Icons.egg_alt_rounded,
    Icons.rice_bowl_rounded,
    Icons.local_bar_rounded,
    Icons.dinner_dining_rounded,
    Icons.brunch_dining_rounded,
  ];

  @override
  State<FloatingFoodIcons> createState() => _FloatingFoodIconsState();
}

class _FloatingFoodIconsState extends State<FloatingFoodIcons>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: widget.entrance ? 0.0 : 1.0,
    );
    if (widget.entrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entrance.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final rng = math.Random(widget.seed);

          // Even "all over" coverage: lay the icons out on a jittered grid so
          // there are no large empty patches or clusters. Columns/rows are
          // derived from the count and the area's aspect ratio.
          final aspect = width <= 0 ? 1.0 : width / height;
          var columns = math.max(1, (math.sqrt(widget.count * aspect)).round());
          var rows = (widget.count / columns).ceil();
          columns = math.max(1, columns);
          rows = math.max(1, rows);
          final cellW = width / columns;
          final cellH = height / rows;

          final specs = <_FloatingSpec>[];
          for (var i = 0; i < widget.count; i++) {
            final col = i % columns;
            final row = (i ~/ columns) % rows;
            // Place within the cell with padding so icons never sit flush to an
            // edge, plus a random jitter for an organic, scattered feel.
            final jx = 0.15 + rng.nextDouble() * 0.7;
            final jy = 0.15 + rng.nextDouble() * 0.7;
            specs.add(
              _FloatingSpec(
                icon: FloatingFoodIcons
                    ._icons[rng.nextInt(FloatingFoodIcons._icons.length)],
                left: (col + jx) * cellW,
                top: (row + jy) * cellH,
                size:
                    widget.minSize +
                    rng.nextDouble() * (widget.maxSize - widget.minSize),
                phase: rng.nextDouble(),
                drift: 5 + rng.nextDouble() * 7,
                tilt: 0.1 + rng.nextDouble() * 0.18,
                opacityScale: 0.6 + rng.nextDouble() * 0.4,
              ),
            );
          }

          return AnimatedBuilder(
            animation: Listenable.merge([_controller, _entrance]),
            builder: (context, _) {
              final t = _controller.value;
              final e = _entrance.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < specs.length; i++)
                    _buildIcon(specs[i], i, specs.length, t, e),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIcon(
    _FloatingSpec spec,
    int index,
    int total,
    double t,
    double entrance,
  ) {
    // Staggered pop-in: each icon's reveal window is offset by its index so
    // they appear to scatter in one after another.
    const window = 0.55;
    final start = total <= 1 ? 0.0 : (index / total) * (1 - window);
    final raw = ((entrance - start) / window).clamp(0.0, 1.0);
    final popped = Curves.easeOutBack.transform(raw);
    final scale = (0.2 + 0.8 * popped).clamp(0.0, 1.2);
    final fade = raw.clamp(0.0, 1.0);

    final wobble = math.sin((t + spec.phase) * 2 * math.pi);

    return Positioned(
      left: spec.left,
      top: spec.top,
      child: Transform.translate(
        offset: Offset(0, spec.drift * wobble),
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: spec.tilt * wobble,
            child: Icon(
              spec.icon,
              size: spec.size,
              color: widget.color.withValues(
                alpha: (widget.opacity * spec.opacityScale * fade).clamp(
                  0.0,
                  1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingSpec {
  const _FloatingSpec({
    required this.icon,
    required this.left,
    required this.top,
    required this.size,
    required this.phase,
    required this.drift,
    required this.tilt,
    required this.opacityScale,
  });

  final IconData icon;
  final double left;
  final double top;
  final double size;
  final double phase;
  final double drift;
  final double tilt;
  final double opacityScale;
}
