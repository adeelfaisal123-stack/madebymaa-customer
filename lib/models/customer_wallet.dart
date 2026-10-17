class CustomerWalletBalance {
  const CustomerWalletBalance({
    required this.balance,
    required this.totalCredited,
    required this.totalDebited,
  });

  final double balance;
  final double totalCredited;
  final double totalDebited;

  String get balanceLabel => '₹${balance.toStringAsFixed(0)}';

  factory CustomerWalletBalance.fromJson(Map<String, dynamic> json) {
    return CustomerWalletBalance(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      totalCredited: (json['total_credited'] as num?)?.toDouble() ?? 0,
      totalDebited: (json['total_debited'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WalletRefundOrderItem {
  const WalletRefundOrderItem({
    required this.dishName,
    required this.kitchenName,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
  });

  final String dishName;
  final String kitchenName;
  final int quantity;
  final double lineTotal;
  final String? imageUrl;

  String get lineTotalLabel => '₹${lineTotal.toStringAsFixed(0)}';

  factory WalletRefundOrderItem.fromJson(Map<String, dynamic> json) {
    return WalletRefundOrderItem(
      dishName: json['dish_name'] as String? ?? 'Dish',
      kitchenName: json['kitchen_name'] as String? ?? 'Kitchen',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class WalletRefundOrderDetail {
  const WalletRefundOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.statusLabel,
    required this.paymentLabel,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.refundStatusLabel,
    this.refundedAmount,
    this.refundNote,
    this.placedAtHuman,
    this.items = const [],
  });

  final int id;
  final String orderNumber;
  final String statusLabel;
  final String paymentLabel;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String refundStatusLabel;
  final double? refundedAmount;
  final String? refundNote;
  final String? placedAtHuman;
  final List<WalletRefundOrderItem> items;

  String get subtotalLabel => '₹${subtotal.toStringAsFixed(0)}';

  String get deliveryFeeLabel => '₹${deliveryFee.toStringAsFixed(0)}';

  String get totalLabel => '₹${total.toStringAsFixed(0)}';

  String get refundedAmountLabel =>
      '₹${(refundedAmount ?? total).toStringAsFixed(0)}';

  factory WalletRefundOrderDetail.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return WalletRefundOrderDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: json['order_number'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      paymentLabel: json['payment_label'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      refundStatusLabel: json['refund_status_label'] as String? ?? '',
      refundedAmount: (json['refunded_amount'] as num?)?.toDouble(),
      refundNote: json['refund_note'] as String?,
      placedAtHuman: json['placed_at_human'] as String?,
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map<String, dynamic>>()
              .map(WalletRefundOrderItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class CustomerWalletTransaction {
  const CustomerWalletTransaction({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.direction,
    required this.amount,
    required this.balanceAfter,
    this.orderNumber,
    this.note,
    this.createdAtHuman,
    this.order,
  });

  final int id;
  final String type;
  final String typeLabel;
  final String direction;
  final double amount;
  final double balanceAfter;
  final String? orderNumber;
  final String? note;
  final String? createdAtHuman;
  final WalletRefundOrderDetail? order;

  bool get isCredit => direction == 'credit';

  bool get isOrderRefund => type == 'order_refund';

  String get amountLabel {
    final prefix = isCredit ? '+' : '-';
    return '$prefix₹${amount.toStringAsFixed(0)}';
  }

  factory CustomerWalletTransaction.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['order'];
    return CustomerWalletTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      typeLabel: json['type_label'] as String? ?? '',
      direction: json['direction'] as String? ?? 'credit',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
      orderNumber: json['order_number'] as String?,
      note: json['note'] as String?,
      createdAtHuman: json['created_at_human'] as String?,
      order: orderRaw is Map<String, dynamic>
          ? WalletRefundOrderDetail.fromJson(orderRaw)
          : null,
    );
  }
}

class CustomerWalletSnapshot {
  const CustomerWalletSnapshot({
    required this.wallet,
    required this.transactions,
  });

  final CustomerWalletBalance wallet;
  final List<CustomerWalletTransaction> transactions;

  factory CustomerWalletSnapshot.fromJson(Map<String, dynamic> json) {
    final walletRaw = json['wallet'];
    final txRaw = json['transactions'];
    return CustomerWalletSnapshot(
      wallet: walletRaw is Map<String, dynamic>
          ? CustomerWalletBalance.fromJson(walletRaw)
          : const CustomerWalletBalance(
              balance: 0,
              totalCredited: 0,
              totalDebited: 0,
            ),
      transactions: txRaw is List
          ? txRaw
              .whereType<Map<String, dynamic>>()
              .map(CustomerWalletTransaction.fromJson)
              .toList()
          : const [],
    );
  }
}
