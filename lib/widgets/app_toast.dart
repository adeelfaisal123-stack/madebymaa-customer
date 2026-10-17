import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../navigation/customer_shell_navigation.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

enum _ToastKind { success, error, info, warning, cart }

/// Branded top toasts — slide in from the top, auto-dismiss.
abstract final class AppToast {
  static const _defaultDuration = Duration(seconds: 3);
  static const _longDuration = Duration(seconds: 4);

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      kind: _ToastKind.success,
      duration: duration ?? _defaultDuration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      kind: _ToastKind.error,
      duration: duration ?? _longDuration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      kind: _ToastKind.info,
      duration: duration ?? _defaultDuration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      kind: _ToastKind.warning,
      duration: duration ?? _defaultDuration,
    );
  }

  static void cart(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _show(
      context,
      message: message,
      kind: _ToastKind.cart,
      duration: duration ?? _defaultDuration,
      onTap: onTap,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required _ToastKind kind,
    required Duration duration,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismissImmediate();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopToast(
        key: ValueKey('app_toast_${DateTime.now().microsecondsSinceEpoch}'),
        message: message,
        kind: kind,
        duration: duration,
        sourceContext: context,
        onTap: onTap,
        onDismissed: () {
          entry.remove();
          if (_entry == entry) {
            _entry = null;
          }
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }

  static void _dismissImmediate() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    super.key,
    required this.message,
    required this.kind,
    required this.duration,
    required this.sourceContext,
    required this.onDismissed,
    this.onTap,
  });

  final String message;
  final _ToastKind kind;
  final Duration duration;
  final BuildContext sourceContext;
  final VoidCallback? onTap;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  var _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward();
      AppToast._timer = Timer(widget.duration, dismissAnimated);
    });
  }

  Future<void> dismissAnimated() async {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    AppToast._timer?.cancel();
    AppToast._timer = null;
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    AppToast._timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  _ToastVisual _visualFor(_ToastKind kind) {
    return switch (kind) {
      _ToastKind.success => const _ToastVisual(
          icon: Icons.check_rounded,
          gradient: [AppColors.brandPurple, AppColors.brandPurpleDeep],
          accent: AppColors.brandPurpleLight,
          sparkle: true,
        ),
      _ToastKind.error => const _ToastVisual(
          icon: Icons.error_outline_rounded,
          gradient: [AppColors.terracotta, Color(0xFF9E4518)],
          accent: Color(0xFFFFCCBC),
        ),
      _ToastKind.info => const _ToastVisual(
          icon: Icons.info_outline_rounded,
          gradient: [AppColors.brandPurple, AppColors.brandPurpleDeep],
          accent: AppColors.amberGlow,
        ),
      _ToastKind.warning => const _ToastVisual(
          icon: Icons.warning_amber_rounded,
          gradient: [Color(0xFFC9871E), Color(0xFF9A6210)],
          accent: AppColors.amberGlow,
        ),
      _ToastKind.cart => const _ToastVisual(
          icon: Icons.shopping_bag_rounded,
          gradient: [AppColors.brandPurple, AppColors.brandPurpleDeep],
          accent: AppColors.amberGlow,
          sparkle: true,
        ),
    };
  }

  Future<void> _handleTap() async {
    final kind = widget.kind;
    final onTap = widget.onTap;
    final sourceContext = widget.sourceContext;

    await dismissAnimated();

    if (onTap != null) {
      onTap();
      return;
    }

    if (kind == _ToastKind.cart && sourceContext.mounted) {
      CustomerShellNavigation.selectTab(
        sourceContext,
        CustomerShellNavigation.tabCart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final visual = _visualFor(widget.kind);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top + 10, 16, 0),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -200) {
                    dismissAnimated();
                  }
                },
                onTap: _handleTap,
                child: _ToastCard(
                  message: widget.message,
                  visual: visual,
                  actionLabel:
                      widget.kind == _ToastKind.cart ? 'View cart' : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastVisual {
  const _ToastVisual({
    required this.icon,
    required this.gradient,
    required this.accent,
    this.sparkle = false,
  });

  final IconData icon;
  final List<Color> gradient;
  final Color accent;
  final bool sparkle;
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.message,
    required this.visual,
    this.actionLabel,
  });

  final String message;
  final _ToastVisual visual;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: visual.gradient,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: visual.gradient.first.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (visual.sparkle)
                Positioned(
                  right: -8,
                  top: -12,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: visual.accent.withValues(alpha: 0.65),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        visual.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            style: AppFonts.style(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (actionLabel != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              actionLabel!,
                              style: AppFonts.style(
                                context,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      actionLabel != null
                          ? Icons.chevron_right_rounded
                          : Icons.close_rounded,
                      size: actionLabel != null ? 22 : 18,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
