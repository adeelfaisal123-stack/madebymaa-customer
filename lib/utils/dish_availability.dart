/// Meal-time keys aligned with Optica2 super category slugs.
const dishAvailabilityMeals = [
  'breakfast',
  'lunch',
  'evening',
  'dinner',
];

const dishAvailabilityDays = [
  'mon',
  'tue',
  'wed',
  'thu',
  'fri',
  'sat',
  'sun',
];

/// Normalized dish availability: meal slug → weekday → enabled.
typedef DishAvailabilityMap = Map<String, Map<String, bool>>;

/// Today's weekday key (`mon` … `sun`) in the kitchen's local calendar day.
String dishAvailabilityTodayKey([DateTime? at]) {
  final date = at ?? DateTime.now();
  return dishAvailabilityDays[date.weekday - 1];
}

DishAvailabilityMap parseDishAvailability(dynamic raw) {
  final defaults = _defaults(enabled: true);
  if (raw == null) return defaults;

  Map<String, dynamic>? decoded;
  if (raw is Map<String, dynamic>) {
    decoded = raw;
  } else if (raw is Map) {
    decoded = raw.map((key, value) => MapEntry(key.toString(), value));
  }

  if (decoded == null) return defaults;

  final out = _defaults(enabled: true);
  for (final meal in dishAvailabilityMeals) {
    final daysRaw = decoded[meal];
    if (daysRaw is! Map) continue;
    for (final day in dishAvailabilityDays) {
      if (daysRaw.containsKey(day)) {
        out[meal]![day] = _asBool(daysRaw[day]);
      }
    }
  }
  return out;
}

bool isDishAvailableOnDay({
  required DishAvailabilityMap availability,
  required String dayKey,
  required List<int> superCategoryIds,
  required Map<int, String> categorySlugById,
  int? filterSuperCategoryId,
}) {
  if (filterSuperCategoryId != null) {
    final slug = categorySlugById[filterSuperCategoryId];
    if (slug == null || !dishAvailabilityMeals.contains(slug)) {
      return superCategoryIds.contains(filterSuperCategoryId);
    }
    return availability[slug]?[dayKey] ?? true;
  }

  if (superCategoryIds.isNotEmpty) {
    for (final id in superCategoryIds) {
      final slug = categorySlugById[id];
      if (slug == null) {
        return true;
      }
      if (availability[slug]?[dayKey] ?? true) {
        return true;
      }
    }
    return false;
  }

  for (final meal in dishAvailabilityMeals) {
    if (availability[meal]?[dayKey] ?? true) {
      return true;
    }
  }
  return true;
}

DishAvailabilityMap _defaults({required bool enabled}) {
  return {
    for (final meal in dishAvailabilityMeals)
      meal: {for (final day in dishAvailabilityDays) day: enabled},
  };
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
  return false;
}
