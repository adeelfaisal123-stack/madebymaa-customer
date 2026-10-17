import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_order.dart';
import '../theme/app_colors.dart';

/// Horizontal animated delivery timeline for customer orders.
class OrderStatusTimeline extends StatefulWidget {
  const OrderStatusTimeline({
    super.key,
    required this.status,
    this.compact = false,
    this.showStepLabels = true,
  });

  final String status;
  final bool compact;
  final bool showStepLabels;

  @override
  State<OrderStatusTimeline> createState() => _OrderStatusTimelineState();
}

class _OrderStatusTimelineState extends State<OrderStatusTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  static const _steps = CustomerOrder.statusFlow;

  static const _shortLabels = <String>[
    'Pending',
    'Ready',
    'Picked',
    'On way',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int get _activeIndex {
    final index = _steps.indexOf(widget.status);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final dotSize = widget.compact ? 10.0 : 12.0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  _TimelineDot(
                    index: i,
                    activeIndex: active,
                    pulse: _pulse.value,
                    size: dotSize,
                  ),
                  if (i < _steps.length - 1)
                    Expanded(
                      child: _TimelineConnector(
                        filled: i < active,
                        animating: i == active,
                        pulse: _pulse.value,
                        height: widget.compact ? 2 : 3,
                      ),
                    ),
                ],
              ],
            ),
            if (widget.showStepLabels) ...[
              SizedBox(height: widget.compact ? 8 : 10),
              Row(
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    Expanded(
                      child: Text(
                        widget.compact
                            ? _shortLabels[i]
                            : CustomerOrder.statusLabels[_steps[i]] ?? _steps[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.exo2(
                          fontSize: widget.compact ? 10 : 12,
                          height: 1.2,
                          fontWeight: i == active ? FontWeight.w800 : FontWeight.w600,
                          color: i <= active
                              ? (i == active
                                  ? AppColors.brandPurple
                                  : AppColors.deepGreen.withValues(alpha: 0.75))
                              : AppColors.deepGreen.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.index,
    required this.activeIndex,
    required this.pulse,
    required this.size,
  });

  final int index;
  final int activeIndex;
  final double pulse;
  final double size;

  @override
  Widget build(BuildContext context) {
    final completed = index < activeIndex;
    final active = index == activeIndex;
    final outer = active ? size + 4 + pulse * 3 : size;

    Color fill;
    Color border;
    if (completed) {
      fill = AppColors.brandPurple;
      border = AppColors.brandPurple;
    } else if (active) {
      fill = AppColors.brandPurple;
      border = AppColors.amberGlow;
    } else {
      fill = Colors.white;
      border = AppColors.deepGreen.withValues(alpha: 0.18);
    }

    return SizedBox(
      width: outer,
      height: outer,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(
              color: border,
              width: active ? 2 : 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.18 + pulse * 0.12),
                      blurRadius: 8 + pulse * 4,
                      spreadRadius: pulse,
                    ),
                  ]
                : null,
          ),
          child: completed
              ? Icon(Icons.check_rounded, size: size * 0.65, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({
    required this.filled,
    required this.animating,
    required this.pulse,
    required this.height,
  });

  final bool filled;
  final bool animating;
  final double pulse;
  final double height;

  @override
  Widget build(BuildContext context) {
    final base = AppColors.deepGreen.withValues(alpha: 0.12);
    final progress = filled ? 1.0 : (animating ? 0.35 + pulse * 0.25 : 0.0);

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(height),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height),
              gradient: const LinearGradient(
                colors: [AppColors.brandPurple, AppColors.amberGlow],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
