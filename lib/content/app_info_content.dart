/// Static copy for profile info screens (terms, privacy, help, about).
abstract final class AppInfoContent {
  static const appName = 'Made by Maa';
  static const appTagline = 'Home-cooked meals from kitchens you can trust.';
  static const supportEmail = 'support@madebymaa.online';
  static const supportPhone = '+91 98765 43210';
  static const supportHours = 'Mon–Sat, 9:00 AM – 7:00 PM IST';
  static const websiteUrl = 'https://madebymaa.online';

  static const termsTitle = 'Terms & Conditions';
  static const termsBody = '''
These Terms & Conditions ("Terms") govern your use of the Made by Maa customer application and related ordering services ("Service"). By using the app, you agree to these Terms.

1. Using the app
You must provide accurate contact and delivery information. You are responsible for activity on your account and for keeping your phone number secure.

2. Orders
When you place an order, you agree to pay the listed price, applicable delivery fees, and taxes shown at checkout. Orders are subject to acceptance by the kitchen.

3. Delivery
Delivery times are estimates. You agree to be available at the delivery address you provide and to share any access instructions needed for a successful delivery.

4. Cancellations & refunds
Cancellation and refund rules may vary by kitchen and order status. Contact support if you need help with a specific order.

5. Conduct
You must not misuse the Service, harass kitchens or delivery partners, or attempt fraud. We may suspend accounts that violate these Terms or applicable law.

6. Limitation of liability
The Service is provided on an "as is" basis. To the extent permitted by law, Made by Maa is not liable for indirect or consequential losses arising from use of the Service.

7. Changes
We may update these Terms. Continued use of the Service after changes constitutes acceptance of the updated Terms.

8. Contact
For questions about these Terms, email $supportEmail.
''';

  static const privacyTitle = 'Privacy Policy';
  static const privacyBody = '''
This Privacy Policy explains how Made by Maa ("we", "us") collects and uses information when you use the customer application ("App").

1. Information we collect
• Account details: name and phone number when you sign in.
• Delivery information: saved addresses and location you choose for browsing and orders.
• Order history: items ordered, kitchens, payment method, and delivery notes.
• Device data: basic identifiers needed for notifications and app performance.

2. How we use information
We use your information to operate the App, process orders, provide support, improve our services, and comply with legal obligations.

3. Sharing
We may share information with partner kitchens, payment and delivery providers, and authorities when required by law or to protect users and the platform.

4. Retention
We retain information while your account is active and as needed for legal, tax, and dispute-resolution purposes.

5. Security
We use reasonable technical and organisational measures to protect your information. Please protect your device and account credentials.

6. Your choices
You may update delivery addresses in the App. You may contact us to request access or correction of your personal data where applicable law provides such rights.

7. Children
The App is not directed at children under 13.

8. Changes
We may update this Privacy Policy. Material changes will be reflected in the App where appropriate.

9. Contact
For privacy-related questions, email $supportEmail.
''';

  static const aboutBody = '''
Made by Maa connects you with home kitchens and passionate cooks in your area. Discover regional dishes, support local food entrepreneurs, and enjoy meals prepared with care — not from a factory line.

Whether you are craving comfort food from home or exploring new cuisines, Made by Maa helps you browse kitchens, place orders, and track deliveries in one place.

Thank you for being part of our community.
''';

  static const faqs = <({String question, String answer})>[
    (
      question: 'How do I place an order?',
      answer:
          'Browse kitchens and dishes on Explore, add items to your cart, set your delivery address, and confirm checkout with cash on delivery.',
    ),
    (
      question: 'How do I change my delivery address?',
      answer:
          'Go to Profile → Delivery locations. Signed-in users can save multiple addresses and switch between them at checkout or from the Explore tab.',
    ),
    (
      question: 'What payment methods are accepted?',
      answer:
          'Cash on delivery is always available. When enabled by admin, you can also pay online via Razorpay (UPI, cards, and wallets) at checkout.',
    ),
    (
      question: 'Can I cancel an order?',
      answer:
          'Contact support as soon as possible with your order details. Cancellation depends on whether the kitchen has already started preparing your order.',
    ),
    (
      question: 'My OTP is not arriving',
      answer:
          'Check your phone number, signal, and SMS inbox. Wait a minute and tap Resend. If the problem continues, email us at $supportEmail.',
    ),
    (
      question: 'How do I delete my account?',
      answer:
          'Email $supportEmail from the phone number linked to your account and we will assist you with account removal.',
    ),
  ];
}
