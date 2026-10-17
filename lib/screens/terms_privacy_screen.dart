import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/profile_info_scaffold.dart';
import 'legal_document_screen.dart';

/// Hub for terms and privacy documents.
class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  void _open(BuildContext context, String key) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(documentKey: key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileInfoScaffold(
      title: 'Terms & privacy',
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Read how Made by Maa handles your account, orders, and personal data.',
            style: AppFonts.style(
              context,
              fontSize: 14,
              height: 1.45,
              color: AppColors.deepGreen.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          _LegalLinkCard(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Rules for using the customer app',
            onTap: () => _open(context, 'terms'),
          ),
          const SizedBox(height: 12),
          _LegalLinkCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we collect and use your data',
            onTap: () => _open(context, 'privacy'),
          ),
        ],
      ),
    );
  }
}

class _LegalLinkCard extends StatelessWidget {
  const _LegalLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: AppColors.brandPurple.withValues(alpha: 0.06),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.brandPurple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.style(
                        context,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.style(
                        context,
                        fontSize: 13,
                        color: AppColors.deepGreen.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.deepGreen.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
