import '../models/customer_order.dart';

const _cancelWindow = Duration(hours: 2);
const _nowDeliveryEstimate = Duration(minutes: 45);

/// Estimated or scheduled delivery time for an order.
DateTime? orderDeliveryDateTime(CustomerOrder order) {
  if (order.isCancelled || order.isDelivered) return null;

  if (order.deliverySlotType == 'scheduled' && order.deliveryDate != null) {
    final start = order.deliveryTimeStart?.trim();
    if (start != null && RegExp(r'^\d{2}:\d{2}$').hasMatch(start)) {
      final parts = start.split(':');
      final year = int.parse(order.deliveryDate!.substring(0, 4));
      final month = int.parse(order.deliveryDate!.substring(5, 7));
      final day = int.parse(order.deliveryDate!.substring(8, 10));
      return DateTime(
        year,
        month,
        day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    final label = order.deliveryTimeLabel?.trim();
    if (label != null && label.isNotEmpty) {
      final match = RegExp(r'^(\d{1,2}:\d{2}\s*(?:AM|PM))', caseSensitive: false)
          .firstMatch(label);
      if (match != null) {
        final parsed = DateTime.tryParse('${order.deliveryDate} ${match.group(1)}');
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  return order.placedAt.add(_nowDeliveryEstimate);
}

Duration? timeUntilOrderDelivery(CustomerOrder order) {
  final deliveryAt = orderDeliveryDateTime(order);
  if (deliveryAt == null) return null;
  return deliveryAt.difference(DateTime.now());
}

bool orderCanBeCancelled(CustomerOrder order) {
  if (!order.isPending) return false;
  final remaining = timeUntilOrderDelivery(order);
  if (remaining == null) return false;
  return remaining > _cancelWindow;
}

bool orderShouldShowDeliveryTimer(CustomerOrder order) {
  if (!order.isPending) return false;
  final remaining = timeUntilOrderDelivery(order);
  if (remaining == null) return false;
  return remaining.inSeconds > 0 && remaining <= _cancelWindow;
}

String formatDeliveryCountdown(Duration remaining) {
  if (remaining.inSeconds <= 0) return '00:00:00';

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  final seconds = remaining.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
