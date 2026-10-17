import 'cart_line_item.dart';
import 'customer_review.dart';

/// A placed customer order from the API or checkout.
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    this.dbId,
    required this.placedAt,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    this.gstAmount = 0,
    required this.total,
    this.advanceAmount,
    this.codBalance,
    required this.paymentMethod,
    required this.deliveryAddress,
    this.paymentReference,
    this.paymentStatus,
    this.refundStatus = 'none',
    this.refundStatusLabel,
    this.refundedAmount,
    this.refundNote,
    this.refundRequestDescription,
    this.refundRequestImageUrl,
    this.refundRequestedAt,
    this.canRequestRefund = false,
    this.notes,
    this.status = 'pending',
    this.deliverySlotLabel,
    this.deliverySlotType = 'now',
    this.deliveryDate,
    this.deliveryTimeLabel,
    this.deliveryTimeStart,
    this.deliveryTimeEnd,
    this.review = const CustomerOrderReviewInfo.ineligible(),
  });

  static const statusLabels = <String, String>{
    'pending': 'Pending',
    'ready_to_pick_up': 'Ready to pick up',
    'picked_up': 'Picked up',
    'on_way': 'On the way',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
    'placed': 'Pending',
  };

  static const statusFlow = <String>[
    'pending',
    'ready_to_pick_up',
    'picked_up',
    'on_way',
    'delivered',
  ];

  final String id;
  final int? dbId;
  final DateTime placedAt;
  final List<CartLineItem> lines;
  final double subtotal;
  final double deliveryFee;
  final double gstAmount;
  final double total;
  final double? advanceAmount;
  final double? codBalance;
  final String paymentMethod;
  final String deliveryAddress;
  final String? paymentReference;
  final String? paymentStatus;
  final String refundStatus;
  final String? refundStatusLabel;
  final double? refundedAmount;
  final String? refundNote;
  final String? refundRequestDescription;
  final String? refundRequestImageUrl;
  final DateTime? refundRequestedAt;
  final bool canRequestRefund;
  final String? notes;
  final String status;
  final String? deliverySlotLabel;
  final String deliverySlotType;
  final String? deliveryDate;
  final String? deliveryTimeLabel;
  final String? deliveryTimeStart;
  final String? deliveryTimeEnd;
  final CustomerOrderReviewInfo review;

  String get deliverySlotDisplay {
    final label = deliverySlotLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    if (deliverySlotType == 'now') return 'Deliver now';
    return 'Scheduled delivery';
  }

  String get totalLabel => '₹${total.toStringAsFixed(0)}';

  String get subtotalLabel => '₹${subtotal.toStringAsFixed(0)}';

  String get deliveryFeeLabel => '₹${deliveryFee.toStringAsFixed(0)}';

  String get gstAmountLabel => '₹${gstAmount.toStringAsFixed(0)}';

  bool get isCod => paymentMethod == 'cod';

  bool get isRazorpay => paymentMethod == 'razorpay';

  bool get isStripe => paymentMethod == 'stripe';

  bool get isCashfree => paymentMethod == 'cashfree';

  bool get isWallet => paymentMethod == 'wallet';

  bool get isPartialPayment =>
      paymentStatus == 'partial' || (codBalance != null && codBalance! > 0.009);

  String get paymentLabel {
    if (isPartialPayment) {
      final paid = '₹${(advanceAmount ?? 0).toStringAsFixed(0)}';
      final due = '₹${(codBalance ?? 0).toStringAsFixed(0)}';
      if (isRazorpay) return '$paid paid (Razorpay) · $due COD';
      if (isStripe) return '$paid paid (Stripe) · $due COD';
      if (isCashfree) return '$paid paid (Cashfree) · $due COD';
      if (isWallet) return '$paid paid (Wallet) · $due COD';
      return '$paid paid · $due COD';
    }
    if (isCod) return 'Cash on delivery';
    if (isRazorpay) return 'Paid online (Razorpay)';
    if (isStripe) return 'Paid online (Stripe)';
    if (isCashfree) return 'Paid online (Cashfree)';
    if (isWallet) return 'Paid with wallet';
    return paymentMethod;
  }

  static const refundStatusLabels = <String, String>{
    'none': 'No refund',
    'pending': 'Refund pending',
    'completed': 'Refunded',
    'failed': 'Refund failed',
  };

  String get refundLabel =>
      refundStatusLabel ??
      refundStatusLabels[refundStatus] ??
      refundStatus;

  bool get hasRefund => refundStatus == 'completed';

  bool get refundPending => refundStatus == 'pending';

  bool get canApplyForRefund => isDelivered && refundStatus == 'none';

  String get refundAmountLabel =>
      refundedAmount == null ? '—' : '₹${refundedAmount!.toStringAsFixed(0)}';

  String get paymentStatusLabel {
    final value = paymentStatus?.trim();
    if (value == null || value.isEmpty) return isCod ? 'Pay on delivery' : 'Paid';
    return value
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get statusLabel {
    return statusLabels[status] ??
        status
            .split('_')
            .map((part) =>
                part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
  }

  bool get isDelivered => status == 'delivered';

  bool get isCancelled => status == 'cancelled';

  bool get isPending => status == 'pending';

  bool get isInProgress => !isDelivered && !isCancelled;

  bool get isActiveDelivery =>
      status == 'picked_up' || status == 'on_way';

  String get trackingTitle {
    if (isCancelled) return 'Order cancelled';
    if (isDelivered) return 'Delivered';
    return switch (status) {
      'pending' => 'Order pending',
      'ready_to_pick_up' => 'Ready to pick up',
      'picked_up' => 'Order picked up',
      'on_way' => 'On the way',
      _ => 'Order ${statusLabel.toLowerCase()}',
    };
  }

  String get trackingMessage {
    return switch (status) {
      'cancelled' =>
        'This order was cancelled. You will not be charged for cancelled COD orders.',
      'pending' =>
        'We received your order and the kitchen will confirm it shortly.',
      'ready_to_pick_up' =>
        'Your order is ready. A delivery partner will pick it up soon.',
      'picked_up' => 'Your order has been picked up and is being prepared for delivery.',
      'on_way' => 'Your order is on the way. It should reach you shortly.',
      'delivered' => 'Your order has been delivered. Enjoy your meal!',
      _ => 'Track your order progress below.',
    };
  }

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  List<String> get kitchenNames {
    final names = <String>{};
    for (final line in lines) {
      names.add(line.kitchenName);
    }
    return names.toList();
  }

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final lines = <CartLineItem>[];
    if (items is List) {
      for (final raw in items) {
        if (raw is Map<String, dynamic>) {
          lines.add(CartLineItem(
            dishId: (raw['dish_id'] as num?)?.toInt() ?? 0,
            dishName: raw['dish_name'] as String? ?? 'Dish',
            kitchenId: (raw['kitchen_id'] as num?)?.toInt() ??
                (raw['restaurant_id'] as num?)?.toInt() ??
                0,
            kitchenName: raw['kitchen_name'] as String? ?? 'Kitchen',
            unitPrice: (raw['unit_price'] as num?)?.toDouble() ?? 0,
            quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
            imageUrl: raw['image_url'] as String?,
            isVeg: raw['is_veg'] as bool? ?? true,
          ));
        }
      }
    }

    final placedRaw = json['placed_at'] as String?;
    final placedAt = placedRaw != null
        ? DateTime.tryParse(placedRaw) ?? DateTime.now()
        : DateTime.now();

    final slotRaw = json['delivery_slot'];
    String? slotLabel;
    var slotType = 'now';
    String? slotDate;
    String? slotTimeLabel;
    String? slotTimeStart;
    String? slotTimeEnd;
    if (slotRaw is Map<String, dynamic>) {
      slotLabel = slotRaw['label'] as String?;
      slotType = slotRaw['type'] as String? ?? 'now';
      slotDate = slotRaw['date'] as String?;
      slotTimeLabel = slotRaw['time_label'] as String?;
      slotTimeStart = slotRaw['time_start'] as String?;
      slotTimeEnd = slotRaw['time_end'] as String?;
    }

    return CustomerOrder(
      id: json['order_number'] as String? ?? '${json['id'] ?? ''}',
      dbId: (json['id'] as num?)?.toInt(),
      placedAt: placedAt,
      lines: lines,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['gst_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble(),
      codBalance: (json['cod_balance'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      paymentReference: json['payment_reference'] as String?,
      paymentStatus: json['payment_status'] as String?,
      refundStatus: json['refund_status'] as String? ?? 'none',
      refundStatusLabel: json['refund_status_label'] as String?,
      refundedAmount: (json['refunded_amount'] as num?)?.toDouble(),
      refundNote: json['refund_note'] as String?,
      refundRequestDescription: json['refund_request_description'] as String?,
      refundRequestImageUrl: json['refund_request_image_url'] as String?,
      refundRequestedAt: _parseDateTime(json['refund_requested_at']),
      canRequestRefund: json['can_request_refund'] as bool? ?? false,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      deliverySlotLabel: slotLabel,
      deliverySlotType: slotType,
      deliveryDate: slotDate,
      deliveryTimeLabel: slotTimeLabel,
      deliveryTimeStart: slotTimeStart,
      deliveryTimeEnd: slotTimeEnd,
      review: CustomerOrderReviewInfo.fromJson(json['review']),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
