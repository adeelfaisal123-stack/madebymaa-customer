import 'dish_main_category.dart';

/// Selected delivery slot for checkout.
class DeliverySlotSelection {
  const DeliverySlotSelection({
    required this.isNow,
    this.dayKey,
    this.superCategoryId,
    this.timeStart,
    this.timeEnd,
    required this.displayLabel,
    this.timeRange = '',
    this.categoryName = '',
  });

  const DeliverySlotSelection.now()
      : isNow = true,
        dayKey = null,
        superCategoryId = null,
        timeStart = null,
        timeEnd = null,
        displayLabel = 'Deliver now',
        timeRange = '',
        categoryName = '';

  final bool isNow;
  final String? dayKey;
  final int? superCategoryId;
  final String? timeStart;
  final String? timeEnd;
  final String displayLabel;
  final String timeRange;
  final String categoryName;

  bool get isScheduledComplete =>
      !isNow &&
      dayKey != null &&
      superCategoryId != null &&
      timeStart != null &&
      timeEnd != null;

  Map<String, dynamic> toApiPayload() {
    if (isNow) {
      return {'type': 'now'};
    }

    final day = dayKey!;
    final deliveryDate = dateForDeliveryDayKey(day);

    return {
      'type': 'scheduled',
      'day': day,
      'date': formatDeliveryDate(deliveryDate),
      'client_now': DateTime.now().toIso8601String(),
      'super_category_id': superCategoryId,
      'time_start': timeStart,
      'time_end': timeEnd,
    };
  }

  bool matchesScheduledSlot({
    required String dayKey,
    required int superCategoryId,
    required String timeStart,
    required String timeEnd,
  }) {
    return !isNow &&
        this.dayKey == dayKey &&
        this.superCategoryId == superCategoryId &&
        this.timeStart == timeStart &&
        this.timeEnd == timeEnd;
  }
}

/// A 30-minute delivery window inside a meal category.
class DeliveryHalfHourSlot {
  const DeliveryHalfHourSlot({
    required this.superCategoryId,
    required this.categoryName,
    required this.timeStart,
    required this.timeEnd,
    required this.label,
  });

  final int superCategoryId;
  final String categoryName;
  final String timeStart;
  final String timeEnd;
  final String label;
}

const deliverySlotDayDefs = [
  ('today', 'Today'),
  ('tomorrow', 'Tomorrow'),
  ('day_after', 'Day after'),
];

typedef DeliveryDayDef = (String key, String label);

/// Days that have at least one bookable 30-minute slot for [categories].
List<DeliveryDayDef> availableDeliveryDayDefs({
  required Iterable<DishMainCategory> categories,
  DateTime? now,
}) {
  final available = <DeliveryDayDef>[];
  for (final def in deliverySlotDayDefs) {
    if (buildHalfHourDeliverySlots(
      categories: categories,
      dayKey: def.$1,
      now: now,
    ).isNotEmpty) {
      available.add(def);
    }
  }
  return available;
}

/// First day key with slots, or null when none are bookable.
String? firstAvailableDeliveryDayKey({
  required Iterable<DishMainCategory> categories,
  DateTime? now,
}) {
  final days = availableDeliveryDayDefs(categories: categories, now: now);
  return days.isEmpty ? null : days.first.$1;
}

DateTime dateForDeliveryDayKey(String dayKey, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  return switch (dayKey) {
    'tomorrow' => today.add(const Duration(days: 1)),
    'day_after' => today.add(const Duration(days: 2)),
    _ => today,
  };
}

String formatDeliveryDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String deliveryDayLabel(String dayKey) {
  return switch (dayKey) {
    'tomorrow' => 'Tomorrow',
    'day_after' => 'Day after tomorrow',
    _ => 'Today',
  };
}

/// Short weekday + day number for the delivery day toggle (e.g. "Sun 7").
String deliveryDayShortDate(String dayKey, [DateTime? now]) {
  final date = dateForDeliveryDayKey(dayKey, now);
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${weekdays[date.weekday - 1]} ${date.day}';
}

/// Returns false when the slot is in the past or too soon to book for [dayKey].
bool isDeliveryHalfHourSlotAvailable({
  required String dayKey,
  required int slotStartMinutes,
  required int slotEndMinutes,
  DateTime? now,
}) {
  if (dayKey != 'today') return true;

  final clock = now ?? DateTime.now();
  final nowMinutes = _minutesFromDateTime(clock);

  if (slotEndMinutes <= nowMinutes) return false;
  if (slotStartMinutes < nowMinutes + 30) return false;

  return true;
}

/// Builds 30-minute slots for all [categories], skipping past/unavailable times on today.
List<DeliveryHalfHourSlot> buildHalfHourDeliverySlots({
  required Iterable<DishMainCategory> categories,
  required String dayKey,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();

  final slots = <DeliveryHalfHourSlot>[];
  final seen = <String>{};

  for (final category in categories) {
    if (!category.isValid) continue;

    final window = category.timeWindowMinutes;
    if (window == null) continue;

    var cursor = _ceilToHalfHour(window.$1);
    while (cursor + 30 <= window.$2) {
      if (!isDeliveryHalfHourSlotAvailable(
        dayKey: dayKey,
        slotStartMinutes: cursor,
        slotEndMinutes: cursor + 30,
        now: clock,
      )) {
        cursor += 30;
        continue;
      }

      final start = _minutesToApiTime(cursor);
      final end = _minutesToApiTime(cursor + 30);
      final key = '$start-$end-${category.id}';
      if (!seen.contains(key)) {
        seen.add(key);
        slots.add(
          DeliveryHalfHourSlot(
            superCategoryId: category.id,
            categoryName: category.name,
            timeStart: start,
            timeEnd: end,
            label: '${_minutesToDisplay(cursor)} – ${_minutesToDisplay(cursor + 30)}',
          ),
        );
      }
      cursor += 30;
    }
  }

  slots.sort((a, b) {
    final startCompare = a.timeStart.compareTo(b.timeStart);
    if (startCompare != 0) return startCompare;
    return a.categoryName.compareTo(b.categoryName);
  });

  return slots;
}

DeliverySlotSelection selectionForHalfHourSlot({
  required String dayKey,
  required DeliveryHalfHourSlot slot,
}) {
  final dayLabel = deliveryDayLabel(dayKey);

  return DeliverySlotSelection(
    isNow: false,
    dayKey: dayKey,
    superCategoryId: slot.superCategoryId,
    timeStart: slot.timeStart,
    timeEnd: slot.timeEnd,
    displayLabel: '$dayLabel · ${slot.label}',
    timeRange: slot.label,
    categoryName: slot.categoryName,
  );
}

int _ceilToHalfHour(int minutes) {
  final remainder = minutes % 30;
  return remainder == 0 ? minutes : minutes + (30 - remainder);
}

int _minutesFromDateTime(DateTime value) => value.hour * 60 + value.minute;

String _minutesToApiTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _minutesToDisplay(int minutes) {
  final hour24 = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}
