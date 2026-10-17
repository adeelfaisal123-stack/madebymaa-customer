class CustomerAuth {
  const CustomerAuth({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  final int id;
  final String name;
  final String phone;
  final String? email;

  factory CustomerAuth.fromJson(Map<String, dynamic> json) {
    final emailRaw = json['email'];
    return CustomerAuth(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Customer',
      phone: json['phone'] as String? ?? '',
      email: emailRaw is String && emailRaw.trim().isNotEmpty
          ? emailRaw.trim()
          : null,
    );
  }
}

class CustomerPhoneCheckResult {
  const CustomerPhoneCheckResult({
    required this.exists,
    required this.canLogin,
    required this.isBlocked,
    required this.message,
    this.customer,
  });

  final bool exists;
  final bool canLogin;
  final bool isBlocked;
  final String message;
  final CustomerAuth? customer;

  bool get isNewCustomer => !exists;

  factory CustomerPhoneCheckResult.fromJson(Map<String, dynamic> json) {
    final customerRaw = json['customer'];
    return CustomerPhoneCheckResult(
      exists: json['exists'] as bool? ?? false,
      canLogin: json['can_login'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      customer: customerRaw is Map<String, dynamic>
          ? CustomerAuth.fromJson(customerRaw)
          : null,
    );
  }
}

class CustomerLoginResult {
  const CustomerLoginResult({
    required this.customer,
    required this.registered,
    required this.message,
  });

  final CustomerAuth customer;
  final bool registered;
  final String message;

  factory CustomerLoginResult.fromJson(Map<String, dynamic> json) {
    final customerRaw = json['customer'];
    if (customerRaw is! Map<String, dynamic>) {
      throw FormatException('Missing customer in login response');
    }
    return CustomerLoginResult(
      customer: CustomerAuth.fromJson(customerRaw),
      registered: json['registered'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
