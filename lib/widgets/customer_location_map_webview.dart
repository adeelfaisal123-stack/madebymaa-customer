import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';

/// Controls programmatic map moves without remounting the WebView.
class CustomerLocationMapController {
  _CustomerLocationMapWebViewState? _state;

  void _attach(_CustomerLocationMapWebViewState state) => _state = state;

  void _detach(_CustomerLocationMapWebViewState state) {
    if (identical(_state, state)) _state = null;
  }

  Future<void> moveTo(LatLng target, {bool animate = true}) {
    return _state?.moveTo(target, animate: animate) ?? Future.value();
  }
}

/// Google Maps JS map — fixed center pin; user pans the map underneath.
class CustomerLocationMapWebView extends StatefulWidget {
  const CustomerLocationMapWebView({
    super.key,
    required this.apiKey,
    required this.initialCenter,
    required this.onCenterChanged,
    this.controller,
  });

  final String apiKey;
  final LatLng initialCenter;
  final ValueChanged<LatLng> onCenterChanged;
  final CustomerLocationMapController? controller;

  @override
  State<CustomerLocationMapWebView> createState() =>
      _CustomerLocationMapWebViewState();
}

class _CustomerLocationMapWebViewState extends State<CustomerLocationMapWebView> {
  late final WebViewController _controller;
  var _ready = false;
  var _dragging = false;
  var _suppressNotify = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _initController();
  }

  @override
  void didUpdateWidget(covariant CustomerLocationMapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.apiKey != widget.apiKey) {
      _loadMap();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  Future<void> moveTo(LatLng target, {bool animate = true}) async {
    if (!_ready) return;
    _suppressNotify = true;
    final lat = target.latitude;
    final lng = target.longitude;
    final js = animate
        ? 'window.panMapTo($lat, $lng, true);'
        : 'window.panMapTo($lat, $lng, false);';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
    // Allow idle notify after pan settles.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      _suppressNotify = false;
    });
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'MapChannel',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);
            if (data is! Map<String, dynamic>) return;
            final type = data['type'] as String?;
            if (type == 'drag') {
              final active = data['active'] == true;
              if (mounted && _dragging != active) {
                setState(() => _dragging = active);
              }
              return;
            }
            if (type != 'center') return;
            if (_suppressNotify) return;
            final lat = (data['lat'] as num?)?.toDouble();
            final lng = (data['lng'] as num?)?.toDouble();
            if (lat == null || lng == null) return;
            widget.onCenterChanged(LatLng(lat, lng));
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
          },
        ),
      );
    _loadMap();
  }

  void _loadMap() {
    setState(() => _ready = false);
    _controller.loadHtmlString(
      _buildHtml(
        apiKey: widget.apiKey,
        center: widget.initialCenter,
      ),
      baseUrl: 'https://maps.googleapis.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        // Fixed pin — map moves under this pointer.
        IgnorePointer(
          child: Center(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: _dragging ? 22 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 52,
                    color: AppColors.brandPurple,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Container(
                      width: _dragging ? 10 : 6,
                      height: _dragging ? 10 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPurple.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_ready)
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
      ],
    );
  }
}

String _buildHtml({
  required String apiKey,
  required LatLng center,
}) {
  final centerJson = jsonEncode({
    'lat': center.latitude,
    'lng': center.longitude,
  });
  final keyParam = Uri.encodeComponent(apiKey);

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <style>
    html, body, #map { height: 100%; margin: 0; padding: 0; }
  </style>
  <script src="https://maps.googleapis.com/maps/api/js?key=$keyParam&callback=initMap" async defer></script>
</head>
<body>
  <div id="map"></div>
  <script>
    const defaultCenter = $centerJson;
    let map;
    let notifyTimer = null;

    function initMap() {
      map = new google.maps.Map(document.getElementById('map'), {
        center: defaultCenter,
        zoom: 16,
        disableDefaultUI: true,
        zoomControl: true,
        gestureHandling: 'greedy',
        clickableIcons: false,
      });

      map.addListener('dragstart', function() {
        MapChannel.postMessage(JSON.stringify({ type: 'drag', active: true }));
      });

      map.addListener('dragend', function() {
        MapChannel.postMessage(JSON.stringify({ type: 'drag', active: false }));
      });

      // After pan / zoom settles, report the map center (under the fixed pin).
      map.addListener('idle', function() {
        MapChannel.postMessage(JSON.stringify({ type: 'drag', active: false }));
        scheduleNotify();
      });

      // First paint center.
      scheduleNotify();
    }

    function scheduleNotify() {
      if (!map) return;
      if (notifyTimer) clearTimeout(notifyTimer);
      notifyTimer = setTimeout(function() {
        const c = map.getCenter();
        if (!c) return;
        MapChannel.postMessage(JSON.stringify({
          type: 'center',
          lat: c.lat(),
          lng: c.lng()
        }));
      }, 120);
    }

    window.panMapTo = function(lat, lng, animate) {
      if (!map) return;
      const target = { lat: lat, lng: lng };
      if (animate) {
        map.panTo(target);
      } else {
        map.setCenter(target);
      }
    };
  </script>
</body>
</html>
''';
}
