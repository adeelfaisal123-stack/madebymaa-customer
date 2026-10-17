import 'dart:async';

import 'package:flutter/material.dart';

/// Runs a reveal animation once, only after this widget enters the viewport.
class ViewportLoadAnimation extends StatefulWidget {
  const ViewportLoadAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 320),
    this.stagger = const Duration(milliseconds: 40),
    this.beginOffset = const Offset(0, 14),
    this.beginScale = 0.92,
    this.alignment = Alignment.center,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration stagger;
  final Offset beginOffset;
  final double beginScale;
  final Alignment alignment;
  final Curve curve;

  @override
  State<ViewportLoadAnimation> createState() => _ViewportLoadAnimationState();
}

class _ViewportLoadAnimationState extends State<ViewportLoadAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ScrollPosition? _position;
  Timer? _delayTimer;
  Timer? _pollTimer;
  bool _started = false;
  bool _checkScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleCheck());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (_position == nextPosition) return;
    _position?.removeListener(_scheduleCheck);
    _position = nextPosition;
    _position?.addListener(_scheduleCheck);
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant ViewportLoadAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  void _scheduleCheck() {
    if (_started || _checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted || _started) return;
      if (!_startIfVisible()) {
        _startPolling();
      }
    });
  }

  void _startPolling() {
    if (_pollTimer != null || _started) return;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted || _started) {
        _pollTimer?.cancel();
        _pollTimer = null;
        return;
      }
      _startIfVisible();
    });
  }

  bool _startIfVisible() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return false;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final bottom = topLeft.dy + renderObject.size.height;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final isVisible = bottom > 0 && topLeft.dy < viewportHeight;

    if (!isVisible) return false;

    _started = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    final delayIndex = widget.index > 8 ? 8 : widget.index;
    _delayTimer = Timer(widget.stagger * delayIndex, () {
      if (!mounted) return;
      _controller.forward();
    });
    return true;
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _pollTimer?.cancel();
    _position?.removeListener(_scheduleCheck);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = widget.curve.transform(_controller.value);
        final opacity = value.clamp(0.0, 1.0);
        final offset = Offset(
          widget.beginOffset.dx * (1 - value),
          widget.beginOffset.dy * (1 - value),
        );
        final scale = widget.beginScale + ((1 - widget.beginScale) * value);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: offset,
            child: Transform.scale(
              alignment: widget.alignment,
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
