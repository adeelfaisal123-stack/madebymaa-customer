import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Kitchen pin shown on the nearby map.
class NearbyKitchenPin {
  const NearbyKitchenPin({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.logoUrl,
    this.isOpen = true,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? logoUrl;
  final bool isOpen;
}

/// Google Maps JS map with user location and kitchen markers.
class CustomerNearbyMapWebView extends StatefulWidget {
  const CustomerNearbyMapWebView({
    super.key,
    required this.apiKey,
    required this.defaultCenter,
    this.userLocation,
    required this.kitchens,
    required this.onKitchenTap,
    this.highlightedKitchenId,
  });

  final String apiKey;
  final LatLng defaultCenter;
  final LatLng? userLocation;
  final List<NearbyKitchenPin> kitchens;
  final ValueChanged<int> onKitchenTap;
  final int? highlightedKitchenId;

  @override
  State<CustomerNearbyMapWebView> createState() =>
      CustomerNearbyMapWebViewState();
}

class CustomerNearbyMapWebViewState extends State<CustomerNearbyMapWebView> {
  late final WebViewController _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant CustomerNearbyMapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiKey != widget.apiKey ||
        oldWidget.defaultCenter != widget.defaultCenter ||
        !_sameKitchens(oldWidget.kitchens, widget.kitchens)) {
      _loadMap();
      return;
    }

    if (oldWidget.userLocation == null && widget.userLocation != null) {
      _loadMap();
      return;
    }

    if (oldWidget.highlightedKitchenId != widget.highlightedKitchenId &&
        widget.highlightedKitchenId != null) {
      focusKitchen(widget.highlightedKitchenId!);
    }
  }

  bool _sameKitchens(List<NearbyKitchenPin> a, List<NearbyKitchenPin> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].latitude != b[i].latitude ||
          a[i].longitude != b[i].longitude) {
        return false;
      }
    }
    return true;
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
            if (data['type'] != 'kitchen') return;
            final id = (data['id'] as num?)?.toInt();
            if (id == null) return;
            widget.onKitchenTap(id);
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _ready = true);
            final id = widget.highlightedKitchenId;
            if (id != null) {
              focusKitchen(id);
            }
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
        defaultCenter: widget.defaultCenter,
        userLocation: widget.userLocation,
        kitchens: widget.kitchens,
      ),
      baseUrl: 'https://maps.googleapis.com',
    );
  }

  /// Pans the map to a kitchen marker and briefly highlights it.
  Future<void> focusKitchen(int kitchenId) async {
    if (!_ready) return;
    await _controller.runJavaScript('window.focusKitchen && focusKitchen($kitchenId);');
  }

  /// Pans the map to the user and zooms in close.
  Future<void> focusUserLocation() async {
    if (!_ready) return;
    await _controller.runJavaScript(
      'window.focusUserLocation && focusUserLocation();',
    );
  }

  /// Pans to explicit coordinates (after GPS refresh without reloading the map).
  Future<void> focusUserLocationAt(double latitude, double longitude) async {
    if (!_ready) return;
    await _controller.runJavaScript(
      'window.focusUserLocationAt && focusUserLocationAt($latitude, $longitude);',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
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
  required LatLng defaultCenter,
  LatLng? userLocation,
  required List<NearbyKitchenPin> kitchens,
}) {
  final keyParam = Uri.encodeComponent(apiKey);
  final defaultJson = jsonEncode({
    'lat': defaultCenter.latitude,
    'lng': defaultCenter.longitude,
  });
  final userJson = userLocation == null
      ? 'null'
      : jsonEncode({
          'lat': userLocation.latitude,
          'lng': userLocation.longitude,
        });
  final kitchensJson = jsonEncode(
    kitchens
        .map(
          (k) => {
            'id': k.id,
            'name': k.name,
            'lat': k.latitude,
            'lng': k.longitude,
            'logoUrl': k.logoUrl ?? '',
            'isOpen': k.isOpen,
          },
        )
        .toList(),
  );

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <style>
    html, body, #map { height: 100%; margin: 0; padding: 0; }
    .gm-style-iw-chr { display: none !important; }
    .gm-style-iw-d { overflow: hidden !important; }
  </style>
  <script src="https://maps.googleapis.com/maps/api/js?key=$keyParam&callback=initMap" async defer></script>
</head>
<body>
  <div id="map"></div>
  <script>
    const defaultCenter = $defaultJson;
    const userLocation = $userJson;
    const kitchens = $kitchensJson;
    let map;
    const kitchenMarkers = {};
    let activeInfoWindow = null;
    let userPulseTimer = null;

    const KITCHEN_FOCUS_ZOOM = 18;
    const USER_FOCUS_ZOOM = 19;
    const INITIAL_MAX_ZOOM = 17;
    const BRAND = { purple: '#6221B3', purpleLight: '#8B5CF6', accent: '#3D1570' };

    function svgData(svg) {
      return 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg);
    }

    function restaurantPinIcon(kitchen, highlighted) {
      const open = kitchen.isOpen !== false;
      const c1 = open ? BRAND.purpleLight : '#A8A29E';
      const c2 = open ? BRAND.purple : '#78716C';
      const w = highlighted ? 58 : 52;
      const h = highlighted ? 66 : 60;
      const ring = highlighted
        ? '<circle cx="26" cy="19" r="14.5" fill="none" stroke="#FBBF24" stroke-width="2.5" opacity="0.95"/>'
        : '';
      const svg =
        '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 52 60">' +
        '<defs>' +
        '<linearGradient id="kg" x1="26" y1="4" x2="26" y2="44" gradientUnits="userSpaceOnUse">' +
        '<stop stop-color="' + c1 + '"/><stop offset="1" stop-color="' + c2 + '"/>' +
        '</linearGradient>' +
        '<filter id="ks" x="-30%" y="-20%" width="160%" height="150%">' +
        '<feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="' + c2 + '" flood-opacity="0.35"/>' +
        '</filter>' +
        '</defs>' +
        '<path filter="url(#ks)" fill="url(#kg)" stroke="#fff" stroke-width="2.2" ' +
        'd="M26 2C16.06 2 8 10.06 8 20c0 10.5 18 36 18 36s18-25.5 18-36C44 10.06 35.94 2 26 2z"/>' +
        ring +
        '<circle cx="26" cy="19" r="12" fill="#fff"/>' +
        '<g transform="translate(26 19) scale(0.72) translate(-12 -11)">' +
        '<path fill="' + c2 + '" d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5V8H19V2h-2v4z"/>' +
        '</g>' +
        '</svg>';
      return {
        url: svgData(svg),
        scaledSize: new google.maps.Size(w, h),
        anchor: new google.maps.Point(w / 2, h - 2),
      };
    }

    function kitchenMarkerIcon(kitchen, highlighted) {
      return restaurantPinIcon(kitchen, highlighted);
    }

    function userPinIcon() {
      return {
        url: svgData(
          '<svg xmlns="http://www.w3.org/2000/svg" width="52" height="64" viewBox="0 0 52 64">' +
          '<defs>' +
          '<linearGradient id="ug" x1="24" y1="4" x2="24" y2="52" gradientUnits="userSpaceOnUse">' +
          '<stop stop-color="#60A5FA"/><stop offset="1" stop-color="#2563EB"/>' +
          '</linearGradient>' +
          '<filter id="ush" x="-30%" y="-20%" width="160%" height="150%">' +
          '<feDropShadow dx="0" dy="3" stdDeviation="3" flood-color="#2563EB" flood-opacity="0.35"/>' +
          '</filter>' +
          '</defs>' +
          '<path filter="url(#ush)" fill="url(#ug)" stroke="#fff" stroke-width="2.5" ' +
          'd="M26 2C16.06 2 8 10.06 8 20c0 11.2 18 40 18 40s18-28.8 18-40C44 10.06 35.94 2 26 2z"/>' +
          '<circle cx="26" cy="20" r="9" fill="#fff"/>' +
          '<circle cx="26" cy="20" r="5" fill="#2563EB"/>' +
          '</svg>'
        ),
        scaledSize: new google.maps.Size(52, 64),
        anchor: new google.maps.Point(26, 58),
      };
    }

    function addUserLocationMarker(pos) {
      new google.maps.Marker({
        position: pos,
        map: map,
        zIndex: 1000,
        icon: userPinIcon(),
        title: 'Your location',
      });

      const rings = [
        { r: 42, stroke: 0.45, fill: 0.14 },
        { r: 68, stroke: 0.22, fill: 0.07 },
      ];
      rings.forEach((cfg) => {
        new google.maps.Circle({
          map: map,
          center: pos,
          radius: cfg.r,
          fillColor: '#3B82F6',
          fillOpacity: cfg.fill,
          strokeColor: '#3B82F6',
          strokeOpacity: cfg.stroke,
          strokeWeight: 1.5,
          zIndex: 990,
        });
      });

      let pulse = new google.maps.Circle({
        map: map,
        center: pos,
        radius: 38,
        fillColor: '#3B82F6',
        fillOpacity: 0.18,
        strokeColor: '#60A5FA',
        strokeOpacity: 0.5,
        strokeWeight: 1,
        zIndex: 995,
      });
      let growing = true;
      let radius = 38;
      if (userPulseTimer) clearInterval(userPulseTimer);
      userPulseTimer = setInterval(function() {
        radius += growing ? 1.2 : -1.2;
        if (radius >= 78) growing = false;
        if (radius <= 38) growing = true;
        pulse.setRadius(radius);
        pulse.setOptions({ fillOpacity: 0.06 + (78 - radius) / 40 * 0.16 });
      }, 40);
    }

    function modernInfoContent(name, open) {
      const status = open
        ? '<span style="color:#6221B3;font-size:11px;font-weight:600">Open</span>'
        : '<span style="color:#DC2626;font-size:11px;font-weight:600">Closed</span>';
      return '<div style="font-family:system-ui,sans-serif;padding:10px 12px;min-width:120px">' +
        '<div style="font-weight:800;font-size:14px;color:#3D1570;margin-bottom:4px">' + name + '</div>' +
        status + '</div>';
    }

    function placeKitchenMarker(kitchen) {
      const pos = { lat: kitchen.lat, lng: kitchen.lng };
      const marker = new google.maps.Marker({
        position: pos,
        map: map,
        title: kitchen.name,
        icon: kitchenMarkerIcon(kitchen, false),
        zIndex: kitchen.isOpen ? 500 : 400,
      });
      const info = new google.maps.InfoWindow({
        content: modernInfoContent(kitchen.name, kitchen.isOpen),
        maxWidth: 220,
      });
      marker.addListener('click', function() {
        MapChannel.postMessage(JSON.stringify({ type: 'kitchen', id: kitchen.id }));
      });
      kitchenMarkers[kitchen.id] = { marker: marker, info: info, kitchen: kitchen };
    }

    function initMap() {
      map = new google.maps.Map(document.getElementById('map'), {
        center: defaultCenter,
        zoom: 13,
        disableDefaultUI: true,
        zoomControl: true,
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: false,
        gestureHandling: 'greedy',
        styles: [
          { featureType: 'poi', stylers: [{ visibility: 'off' }] },
          { featureType: 'transit', stylers: [{ visibility: 'off' }] },
        ],
      });

      const bounds = new google.maps.LatLngBounds();

      if (userLocation) {
        bounds.extend(userLocation);
        addUserLocationMarker(userLocation);
      }

      kitchens.forEach(function(kitchen) {
        bounds.extend({ lat: kitchen.lat, lng: kitchen.lng });
        placeKitchenMarker(kitchen);
      });

      window.focusKitchen = function(id) {
        const entry = kitchenMarkers[id];
        if (!entry) return;
        const kitchen = entry.kitchen;
        const marker = entry.marker;
        const pos = marker.getPosition();

        marker.setIcon(kitchenMarkerIcon(kitchen, true));
        marker.setZIndex(900);

        map.panTo(pos);
        map.setZoom(KITCHEN_FOCUS_ZOOM);

        if (activeInfoWindow) activeInfoWindow.close();
        entry.info.open(map, marker);
        activeInfoWindow = entry.info;

        marker.setAnimation(google.maps.Animation.BOUNCE);
        setTimeout(function() {
          marker.setAnimation(null);
          marker.setIcon(kitchenMarkerIcon(kitchen, false));
          marker.setZIndex(kitchen.isOpen ? 500 : 400);
        }, 1500);
      };

      window.focusUserLocation = function() {
        if (!userLocation) return;
        map.panTo(userLocation);
        map.setZoom(USER_FOCUS_ZOOM);
      };

      window.focusUserLocationAt = function(lat, lng) {
        map.panTo({ lat: lat, lng: lng });
        map.setZoom(USER_FOCUS_ZOOM);
      };

      if (kitchens.length > 0 || userLocation) {
        map.fitBounds(bounds, 64);
        google.maps.event.addListenerOnce(map, 'bounds_changed', function() {
          if (map.getZoom() > INITIAL_MAX_ZOOM) map.setZoom(INITIAL_MAX_ZOOM);
        });
      }
    }
  </script>
</body>
</html>
''';
}
