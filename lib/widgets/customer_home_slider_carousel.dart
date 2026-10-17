import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_home_slider.dart';
import '../theme/app_colors.dart';
import '../utils/optica2_asset_url.dart';

class CustomerHomeSliderCarousel extends StatefulWidget {
  const CustomerHomeSliderCarousel({
    super.key,
    required this.sliders,
    this.isLoading = false,
    this.onPageChanged,
    this.onSlideTap,
    this.dotColor,
    this.embedded = false,
    this.aspectRatio,
    this.peekAdjacentSlides = false,
  });

  final List<CustomerHomeSlider> sliders;
  final bool isLoading;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<CustomerHomeSlider>? onSlideTap;
  final Color? dotColor;
  /// When true, renders only the slide card (no padding or dots) for header embed.
  final bool embedded;
  /// When set, uses a compact banner height instead of the hero viewport fraction.
  final double? aspectRatio;
  /// When true, shows slivers of the previous/next slide on the sides.
  final bool peekAdjacentSlides;

  static const viewportHeightFraction = 0.5;
  static const horizontalPadding = 40.0;
  static const peekViewportFraction = 0.88;
  static const peekSlideGap = 8.0;

  static double slideHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * viewportHeightFraction;

  static double bannerHeight(
    BuildContext context,
    double aspectRatio, {
    bool peek = false,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final slideWidth = peek
        ? width * peekViewportFraction - peekSlideGap * 2
        : width - horizontalPadding;
    return slideWidth / aspectRatio;
  }

  static Widget pageDots({
    required int count,
    required int activeIndex,
    required Color dotColor,
  }) {
    if (count < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = activeIndex == i;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? dotColor : dotColor.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }

  @override
  State<CustomerHomeSliderCarousel> createState() =>
      _CustomerHomeSliderCarouselState();
}

class _CustomerHomeSliderCarouselState extends State<CustomerHomeSliderCarousel> {
  static const _autoInterval = Duration(seconds: 4);

  double _slideHeight(BuildContext context) {
    final ratio = widget.aspectRatio;
    if (ratio != null && ratio > 0) {
      return CustomerHomeSliderCarousel.bannerHeight(
        context,
        ratio,
        peek: widget.peekAdjacentSlides,
      );
    }
    return CustomerHomeSliderCarousel.slideHeight(context);
  }

  PageController? _pageController;
  Timer? _autoTimer;
  var _page = 0;

  bool get _infinitePeek =>
      widget.peekAdjacentSlides && widget.sliders.length >= 2;

  int get _virtualItemCount {
    if (_infinitePeek) return widget.sliders.length + 2;
    return widget.sliders.length;
  }

  int get _initialVirtualPage => _infinitePeek ? 1 : 0;

  PageController get _controller {
    _pageController ??= PageController(
      viewportFraction: widget.peekAdjacentSlides
          ? CustomerHomeSliderCarousel.peekViewportFraction
          : 1.0,
      initialPage: _initialVirtualPage,
    );
    return _pageController!;
  }

  CustomerHomeSlider _slideAtVirtualIndex(int index) {
    final count = widget.sliders.length;
    if (!_infinitePeek) return widget.sliders[index];
    if (index == 0) return widget.sliders[count - 1];
    if (index == count + 1) return widget.sliders[0];
    return widget.sliders[index - 1];
  }

  int _logicalIndexFromVirtual(int virtualIndex) {
    final count = widget.sliders.length;
    if (!_infinitePeek) return virtualIndex;
    if (virtualIndex == 0) return count - 1;
    if (virtualIndex == count + 1) return 0;
    return virtualIndex - 1;
  }

  @override
  void initState() {
    super.initState();
    _restartAutoPlay();
    _centerActivePage();
  }

  @override
  void didUpdateWidget(CustomerHomeSliderCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slidersChanged = oldWidget.sliders.length != widget.sliders.length;
    final finishedLoading = oldWidget.isLoading && !widget.isLoading;

    if (slidersChanged) {
      _page = 0;
      widget.onPageChanged?.call(0);
      _resetPageController();
      _restartAutoPlay();
    } else if (finishedLoading &&
        widget.peekAdjacentSlides &&
        widget.sliders.length >= 2) {
      _resetPageController();
    }

    if (slidersChanged || finishedLoading) {
      _centerActivePage();
    }
  }

  void _resetPageController() {
    _pageController?.dispose();
    _pageController = null;
  }

  void _centerActivePage() {
    if (!widget.peekAdjacentSlides) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.jumpToPage(_infinitePeek ? _page + 1 : _page);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _restartAutoPlay() {
    _autoTimer?.cancel();
    if (widget.sliders.length < 2) return;
    _autoTimer = Timer.periodic(_autoInterval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || widget.sliders.length < 2) return;
    if (!_controller.hasClients) return;
    final current = _controller.page?.round() ?? _initialVirtualPage;
    _controller.animateToPage(
      current + 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _onVirtualPageChanged(int virtualIndex) {
    final logical = _logicalIndexFromVirtual(virtualIndex);
    if (logical != _page) {
      setState(() => _page = logical);
      widget.onPageChanged?.call(logical);
    }

    if (!_infinitePeek) return;

    final count = widget.sliders.length;
    if (virtualIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(count);
      });
    } else if (virtualIndex == count + 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(1);
      });
    }
  }

  void _onPage(int index) {
    setState(() => _page = index);
    widget.onPageChanged?.call(index);
  }

  Widget _buildSlideContent(CustomerHomeSlider slide) {
    return _SlideCard(
      slide: slide,
      onTap: slide.hasLink && widget.onSlideTap != null
          ? () => widget.onSlideTap!(slide)
          : null,
    );
  }

  Widget _wrapSlide(Widget slideContent, double slideHeight) {
    final card = _SliderCard(
      child: SizedBox(
        height: slideHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: slideContent,
        ),
      ),
    );

    if (!widget.peekAdjacentSlides) return card;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CustomerHomeSliderCarousel.peekSlideGap,
      ),
      child: card,
    );
  }

  Widget _buildCarousel(double slideHeight) {
    if (widget.peekAdjacentSlides) {
      final physics = widget.sliders.length < 2
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics();

      return SizedBox(
        height: slideHeight,
        child: PageView.builder(
          controller: _controller,
          padEnds: true,
          clipBehavior: Clip.none,
          physics: physics,
          itemCount: _virtualItemCount,
          onPageChanged: _onVirtualPageChanged,
          itemBuilder: (context, index) {
            return _wrapSlide(
              _buildSlideContent(_slideAtVirtualIndex(index)),
              slideHeight,
            );
          },
        ),
      );
    }

    return _SliderCard(
      child: SizedBox(
        height: slideHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.sliders.length,
            onPageChanged: _onPage,
            itemBuilder: (context, index) {
              return _buildSlideContent(widget.sliders[index]);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slideHeight = _slideHeight(context);
    final horizontalInset = widget.peekAdjacentSlides ? 0.0 : 20.0;

    if (widget.isLoading) {
      final carousel = widget.peekAdjacentSlides
          ? SizedBox(
              height: slideHeight,
              child: PageView.builder(
                controller: _controller,
                padEnds: true,
                clipBehavior: Clip.none,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return _wrapSlide(const _SliderPlaceholder(), slideHeight);
                },
              ),
            )
          : _SliderCard(
              child: SizedBox(
                height: slideHeight,
                child: const _SliderPlaceholder(),
              ),
            );
      if (widget.embedded) return carousel;
      return Padding(
        padding: EdgeInsets.fromLTRB(horizontalInset, 12, horizontalInset, 0),
        child: carousel,
      );
    }

    if (widget.sliders.isEmpty) {
      return const SizedBox.shrink();
    }

    final dotActive = widget.dotColor ?? AppColors.brandPurple;
    final carousel = _buildCarousel(slideHeight);

    if (widget.embedded) return carousel;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalInset, 12, horizontalInset, 0),
      child: Column(
        children: [
          carousel,
          CustomerHomeSliderCarousel.pageDots(
            count: widget.sliders.length,
            activeIndex: _page,
            dotColor: dotActive,
          ),
        ],
      ),
    );
  }
}

class _SlideCard extends StatefulWidget {
  const _SlideCard({required this.slide, this.onTap});

  final CustomerHomeSlider slide;
  final VoidCallback? onTap;

  @override
  State<_SlideCard> createState() => _SlideCardState();
}

class _SlideCardState extends State<_SlideCard> {
  Offset? _pointerDown;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    final down = _pointerDown;
    _pointerDown = null;
    final onTap = widget.onTap;
    if (down == null || onTap == null) return;
    if ((event.position - down).distance > 18) return;
    onTap();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDown = null;
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final imageUrl = resolveOptica2AssetUrl(slide.imageUrl) ?? '';

    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isEmpty)
          const _SliderPlaceholder()
        else
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            headers: const {
              'User-Agent': 'MadeByMaa-Customer/1.0',
              'Accept': 'image/*',
            },
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const _SliderPlaceholder();
            },
            errorBuilder: (_, _, _) => Container(
              color: AppColors.brandPurple.withValues(alpha: 0.12),
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.brandPurple,
                size: 40,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
        if (slide.title != null && slide.title!.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Text(
              slide.title!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
      ],
    );

    if (widget.onTap == null) return content;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: content,
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: AppColors.brandPurple.withValues(alpha: 0.14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SliderPlaceholder extends StatelessWidget {
  const _SliderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.brandPurple,
          ),
        ),
      ),
    );
  }
}
