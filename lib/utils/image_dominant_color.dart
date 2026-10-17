import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'optica2_asset_url.dart';

/// Dominant tone from an image URL (matches what the slider shows).
Future<Color?> dominantColorFromImageUrl(
  String url, {
  http.Client? client,
}) async {
  final resolved = resolveOptica2AssetUrl(url) ?? url;
  if (resolved.isEmpty) return null;

  final httpClient = client ?? http.Client();
  final ownsClient = client == null;

  try {
    final response = await httpClient.get(
      Uri.parse(resolved),
      headers: const {
        'User-Agent': 'MadeByMaa-Customer/1.0',
        'Accept': 'image/*',
      },
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return null;

    return dominantColorFromBytes(Uint8List.fromList(response.bodyBytes));
  } catch (_) {
    return null;
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

/// Weighted dominant color — favors saturated mid-tones, falls back to full average.
Future<Color?> dominantColorFromBytes(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 64,
      targetHeight: 64,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) return null;

    var ar = 0.0;
    var ag = 0.0;
    var ab = 0.0;
    var aWeight = 0.0;

    Color? vividBest;
    var vividScore = 0.0;

    for (var i = 0; i < byteData.lengthInBytes; i += 4) {
      final alpha = byteData.getUint8(i + 3) / 255.0;
      if (alpha < 0.15) continue;

      final r = byteData.getUint8(i);
      final g = byteData.getUint8(i + 1);
      final b = byteData.getUint8(i + 2);
      final color = Color.fromARGB(255, r, g, b);
      final hsl = HSLColor.fromColor(color);

      if (hsl.lightness < 0.08 || hsl.lightness > 0.92) continue;

      final colorful = 0.25 + hsl.saturation * 0.75;
      final midTone = 1 - (hsl.lightness - 0.42).abs() * 1.6;
      final w = alpha * colorful * midTone.clamp(0.15, 1.0);

      ar += r * w;
      ag += g * w;
      ab += b * w;
      aWeight += w;

      if (hsl.saturation >= 0.12 && hsl.lightness >= 0.15 && hsl.lightness <= 0.78) {
        final score = hsl.saturation * midTone.clamp(0.2, 1.0);
        if (score > vividScore) {
          vividScore = score;
          vividBest = color;
        }
      }
    }

    if (aWeight <= 0) return null;

    final averaged = Color.fromARGB(
      255,
      (ar / aWeight).round().clamp(0, 255),
      (ag / aWeight).round().clamp(0, 255),
      (ab / aWeight).round().clamp(0, 255),
    );

    // Blend vivid accent with average so browns/greens from food stay faithful.
    if (vividBest != null && vividScore > 0.08) {
      return Color.lerp(vividBest, averaged, 0.45) ?? averaged;
    }

    return averaged;
  } catch (_) {
    return null;
  }
}

/// Keeps the image hue and character; only adjusts for header contrast.
Color heroColorFromImage(Color fromImage) {
  final hsl = HSLColor.fromColor(fromImage);

  var saturation = hsl.saturation;
  var lightness = hsl.lightness;

  if (saturation < 0.22) {
    saturation = (saturation + 0.28).clamp(0.32, 0.75);
  } else {
    saturation = (saturation * 1.08).clamp(0.35, 0.92);
  }

  if (lightness > 0.5) {
    lightness = 0.42;
  } else if (lightness < 0.2) {
    lightness = 0.32;
  } else {
    lightness = lightness.clamp(0.26, 0.46);
  }

  return HSLColor.fromAHSL(1, hsl.hue, saturation, lightness).toColor();
}

/// Gradient pair for hero backgrounds (derived from the image tone).
(Color primary, Color deep) heroGradientFromColor(Color base) {
  final hsl = HSLColor.fromColor(base);
  final primary = hsl.toColor();
  final deep = hsl
      .withLightness((hsl.lightness * 0.58).clamp(0.14, 0.32))
      .withSaturation((hsl.saturation * 1.05).clamp(0.35, 1.0))
      .toColor();
  return (primary, deep);
}
