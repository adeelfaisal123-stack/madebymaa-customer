import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Splash tagline — unified Plus Jakarta Sans, typewriter reveal, accent colors.
class CookSellEarnTagline extends StatefulWidget {
  const CookSellEarnTagline({
    super.key,
    this.reveal,
    this.fontSize = 26,
    this.onDark = true,
  });

  /// Optional parent splash progress; typing starts once this passes ~0.34.
  final Animation<double>? reveal;

  final double fontSize;
  final bool onDark;

  @override
  State<CookSellEarnTagline> createState() => _CookSellEarnTaglineState();
}

class _CookSellEarnTaglineState extends State<CookSellEarnTagline>
    with TickerProviderStateMixin {
  static const _line1 = 'Eat Right';
  static const _line2Prefix = 'Eat ';
  static const _line2Brand = 'Made by Maa';

  static const _charDelay = Duration(milliseconds: 52);
  static const _linePause = Duration(milliseconds: 280);

  int _line1Count = 0;
  int _line2Count = 0;
  var _showCursor = true;
  var _typingStarted = false;
  var _typingComplete = false;

  Timer? _typeTimer;
  Timer? _cursorTimer;
  Timer? _startTimer;
  VoidCallback? _revealListener;
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  late final Animation<double> _brandScale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _brandScale = Tween<double>(begin: 0.97, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic),
    );

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      if (!mounted || _typingComplete) return;
      setState(() => _showCursor = !_showCursor);
    });

    final reveal = widget.reveal;
    if (reveal != null) {
      _revealListener = _maybeStartTyping;
      reveal.addListener(_revealListener!);
      _maybeStartTyping();
    } else {
      _startTimer = Timer(const Duration(milliseconds: 280), _beginTyping);
    }
  }

  @override
  void didUpdateWidget(CookSellEarnTagline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reveal != widget.reveal) {
      oldWidget.reveal?.removeListener(_revealListener ?? () {});
      _revealListener = _maybeStartTyping;
      widget.reveal?.addListener(_revealListener!);
      _maybeStartTyping();
    }
  }

  void _maybeStartTyping() {
    if (_typingStarted) return;
    final reveal = widget.reveal;
    if (reveal == null || reveal.value < 0.34) return;
    _beginTyping();
  }

  void _beginTyping() {
    if (_typingStarted || !mounted) return;
    _typingStarted = true;
    _typeLine1();
  }

  void _typeLine1() {
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(_charDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_line1Count >= _line1.length) {
        timer.cancel();
        Timer(_linePause, () {
          if (mounted) _typeLine2();
        });
        return;
      }
      setState(() => _line1Count++);
    });
  }

  void _typeLine2() {
    _typeTimer?.cancel();
    final fullLine2 = '$_line2Prefix$_line2Brand';
    _typeTimer = Timer.periodic(_charDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_line2Count >= fullLine2.length) {
        timer.cancel();
        setState(() {
          _typingComplete = true;
          _showCursor = false;
        });
        _pulse.forward(from: 0);
        _shimmer.repeat();
        return;
      }
      setState(() => _line2Count++);
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    _startTimer?.cancel();
    _pulse.dispose();
    _shimmer.dispose();
    widget.reveal?.removeListener(_revealListener ?? () {});
    super.dispose();
  }

  TextStyle _font({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.4,
    double height = 1.15,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  Color get _inkPrimary =>
      widget.onDark ? Colors.white : const Color(0xFF1A1228);

  Color get _inkSecondary => widget.onDark
      ? Colors.white.withValues(alpha: 0.78)
      : AppColors.deepGreen.withValues(alpha: 0.65);

  Color get _cursorColor =>
      widget.onDark ? AppColors.amberGlow : AppColors.brandPurple;

  TextStyle _caretStyle(double size) => _font(
        size: size * 0.92,
        weight: FontWeight.w300,
        color: _showCursor ? _cursorColor : Colors.transparent,
        letterSpacing: 0,
      );

  Widget _gradientBrandText(String text, double size) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final t = -0.35 + 1.7 * _shimmer.value;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              AppColors.brandPurple,
              Color(0xFF9B6FD4),
              AppColors.brandPurpleDeep,
            ],
            stops: [
              (t - 0.35).clamp(0.0, 1.0),
              t.clamp(0.0, 1.0),
              (t + 0.35).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: Text(
        text,
        style: _font(
          size: size,
          weight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  /// Splits "Eat …" so "Eat" stays neutral and the rest can take an accent.
  List<TextSpan> _eatLineSpans({
    required String visible,
    required bool complete,
    required bool showCaret,
    required Color accentColor,
  }) {
    const eatLen = 4; // "Eat "
    final eatPart =
        visible.length <= eatLen ? visible : visible.substring(0, eatLen);
    final rest =
        visible.length > eatLen ? visible.substring(eatLen) : '';
    final size = widget.fontSize;

    return [
      TextSpan(
        text: eatPart,
        style: _font(
          size: size,
          weight: FontWeight.w600,
          color: _inkSecondary,
          letterSpacing: -0.2,
        ),
      ),
      if (rest.isNotEmpty)
        TextSpan(
          text: rest,
          style: _font(
            size: size,
            weight: FontWeight.w800,
            color: complete ? accentColor : _inkPrimary,
            letterSpacing: -0.5,
          ),
        ),
      if (showCaret)
        TextSpan(text: '|', style: _caretStyle(size)),
    ];
  }

  Widget _lineOne() {
    final visible = _line1.substring(0, _line1Count.clamp(0, _line1.length));
    final complete = _line1Count >= _line1.length;

    return Text.rich(
      TextSpan(
        children: _eatLineSpans(
          visible: visible,
          complete: complete,
          showCaret: !complete && !_typingComplete,
          accentColor: AppColors.terracotta,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _lineTwo() {
    final fullLine2 = '$_line2Prefix$_line2Brand';
    final visible =
        fullLine2.substring(0, _line2Count.clamp(0, fullLine2.length));
    final complete = _line2Count >= fullLine2.length;
    final line2Active = _line1Count >= _line1.length;
    final showCaret = line2Active && !complete && !_typingComplete;

    final prefixVisible = visible.length <= _line2Prefix.length
        ? visible
        : _line2Prefix;
    final brandVisible = visible.length > _line2Prefix.length
        ? visible.substring(_line2Prefix.length)
        : '';

    final size = widget.fontSize;

    return AnimatedBuilder(
      animation: _brandScale,
      builder: (context, child) {
        return Transform.scale(
          scale: complete ? _brandScale.value : 1,
          child: child,
        );
      },
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: prefixVisible,
              style: _font(
                size: size,
                weight: FontWeight.w600,
                color: _inkSecondary,
                letterSpacing: -0.2,
              ),
            ),
            if (brandVisible.isNotEmpty)
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: complete
                    ? _gradientBrandText(_line2Brand, size)
                    : Text(
                        brandVisible,
                        style: _font(
                          size: size,
                          weight: FontWeight.w800,
                          color: AppColors.brandPurple.withValues(alpha: 0.9),
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
            if (showCaret)
              TextSpan(text: '|', style: _caretStyle(size)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reveal != null) {
      return AnimatedBuilder(
        animation: widget.reveal!,
        builder: (context, _) => _buildContent(),
      );
    }
    return _buildContent();
  }

  Widget _buildContent() {
    final dividerReady = _line1Count >= _line1.length;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _lineOne(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: widget.fontSize * 0.22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              width: dividerReady ? 48 : 20,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  colors: [
                    AppColors.terracotta.withValues(
                      alpha: dividerReady ? 0.15 : 0.08,
                    ),
                    AppColors.brandPurple.withValues(
                      alpha: dividerReady ? 0.55 : 0.2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _lineTwo(),
        ],
      ),
    );
  }
}
