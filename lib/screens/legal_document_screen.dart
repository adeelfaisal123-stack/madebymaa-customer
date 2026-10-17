import 'package:flutter/material.dart';

import '../content/app_info_content.dart';
import '../widgets/profile_info_scaffold.dart';

/// Displays terms or privacy policy text.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.documentKey,
  });

  /// `terms` or `privacy`.
  final String documentKey;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = documentKey == 'privacy';
    final title =
        isPrivacy ? AppInfoContent.privacyTitle : AppInfoContent.termsTitle;
    final body =
        isPrivacy ? AppInfoContent.privacyBody : AppInfoContent.termsBody;

    return ProfileInfoScaffold(
      title: title,
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [InfoDocumentCard(body: body)],
      ),
    );
  }
}
