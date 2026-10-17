import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_toast.dart';
import '../models/customer_featured_kitchen.dart';

/// Opens the kitchen location in Google Maps (app or browser) at the stored pin.
Future<void> openKitchenInGoogleMaps(
  BuildContext context,
  CustomerFeaturedKitchen kitchen,
) async {
  final coords = kitchen.mapCoordinates;
  final uris = coords != null
      ? _coordinateLaunchUris(
          coords.latitude,
          coords.longitude,
          label: kitchen.name,
        )
      : _addressLaunchUris(kitchen.address);

  if (uris == null || uris.isEmpty) {
    if (!context.mounted) return;
    AppToast.warning(context, 'No location available for this kitchen.');
    return;
  }

  for (final uri in uris) {
    try {
      if (await canLaunchUrl(uri)) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      }
    } catch (_) {
      // Try next URI scheme.
    }
  }

  // Last resort: HTTPS Google Maps (no canLaunchUrl gate).
  final https = uris.lastWhere(
    (u) => u.scheme == 'https',
    orElse: () => uris.first,
  );
  final launched =
      await launchUrl(https, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppToast.error(context, 'Could not open Google Maps.');
  }
}

/// Precise pin URIs — native schemes first, then universal HTTPS.
List<Uri> _coordinateLaunchUris(
  double lat,
  double lng, {
  String? label,
}) {
  final latStr = _formatCoord(lat);
  final lngStr = _formatCoord(lng);
  final pin = '$latStr,$lngStr';
  final encodedLabel = label != null && label.trim().isNotEmpty
      ? Uri.encodeComponent(label.trim())
      : null;
  final q = encodedLabel != null ? '$pin($encodedLabel)' : pin;

  final uris = <Uri>[];

  if (!kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        uris.add(Uri.parse('geo:$pin?q=$q&z=18'));
        break;
      case TargetPlatform.iOS:
        uris.add(Uri.parse('comgooglemaps://?q=$q&zoom=18'));
        uris.add(Uri.parse('maps://?q=$q&z=18'));
        break;
      default:
        break;
    }
  }

  // Drops a pin at exact coordinates (not a text search).
  uris.add(Uri.parse('https://www.google.com/maps?q=$q&z=18'));
  uris.add(
    Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=map'
      '&center=$pin&zoom=18',
    ),
  );

  return uris;
}

List<Uri>? _addressLaunchUris(String? address) {
  final trimmed = address?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final query = Uri.encodeComponent(trimmed);
  return [
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
  ];
}

String _formatCoord(double value) => value.toStringAsFixed(7);
