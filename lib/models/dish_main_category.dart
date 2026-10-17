/// Main meal category for a dish (Breakfast, Lunch, etc.).
class DishMainCategory {
  const DishMainCategory({
    required this.id,
    required this.name,
    required this.timeRange,
    this.slug = '',
    this.startTime,
    this.endTime,
  });

  final int id;
  final String name;
  final String timeRange;
  final String slug;
  final String? startTime;
  final String? endTime;

  bool get isValid => id > 0 && name.isNotEmpty;

  /// Start/end as minutes from midnight, parsed from API times or [timeRange].
  (int, int)? get timeWindowMinutes {
    final start = _parseTimeMinutes(startTime);
    final end = _parseTimeMinutes(endTime);
    if (start != null && end != null && end > start) {
      return (start, end);
    }

    return _parseTimeRangeLabel(timeRange);
  }

  factory DishMainCategory.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const DishMainCategory(id: 0, name: '', timeRange: '');
    }

    return DishMainCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      timeRange: (json['time_range'] as String? ?? '').trim(),
      slug: (json['slug'] as String? ?? '').trim(),
      startTime: (json['start_time'] as String?)?.trim(),
      endTime: (json['end_time'] as String?)?.trim(),
    );
  }
}

int? _parseTimeMinutes(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

(int, int)? _parseTimeRangeLabel(String label) {
  if (label.isEmpty) return null;
  final parts = label.split('–').map((p) => p.trim()).toList();
  if (parts.length < 2) {
    parts
      ..clear()
      ..addAll(label.split('-').map((p) => p.trim()));
  }
  if (parts.length < 2) return null;

  final start = _parseDisplayTime(parts[0]);
  final end = _parseDisplayTime(parts[1]);
  if (start == null || end == null || end <= start) return null;
  return (start, end);
}

int? _parseDisplayTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (match == null) return null;

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)?.toUpperCase();

  if (period == 'PM' && hour < 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;

  return hour * 60 + minute;
}
