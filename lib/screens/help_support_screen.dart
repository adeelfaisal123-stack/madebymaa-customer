import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/app_info_content.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/app_toast.dart';
import '../widgets/profile_info_scaffold.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launch(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Could not open link');
    }
  }

  Future<void> _email(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfoContent.supportEmail,
      query: 'subject=${Uri.encodeComponent('Made by Maa — Customer support')}',
    );
    try {
      await _launch(uri);
    } catch (_) {
      if (!context.mounted) return;
      await Clipboard.setData(
        ClipboardData(text: AppInfoContent.supportEmail),
      );
      if (!context.mounted) return;
      AppToast.success(context, 'Email copied: ${AppInfoContent.supportEmail}');
    }
  }

  Future<void> _call(BuildContext context) async {
    final digits = AppInfoContent.supportPhone.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      await _launch(Uri(scheme: 'tel', path: digits));
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, 'Could not open phone dialer.');
    }
  }

  Future<void> _openWebsite(BuildContext context) async {
    try {
      await _launch(Uri.parse(AppInfoContent.websiteUrl));
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, 'Could not open website.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileInfoScaffold(
      title: 'Help & support',
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
            'Need help with an order or your account? Reach out anytime during support hours.',
            style: AppFonts.style(
              context,
              fontSize: 14,
              height: 1.45,
              color: AppColors.deepGreen.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          _ContactCard(
            children: [
              _ContactTile(
                icon: Icons.email_outlined,
                title: 'Email us',
                subtitle: AppInfoContent.supportEmail,
                onTap: () => _email(context),
              ),
              const Divider(height: 1),
              _ContactTile(
                icon: Icons.phone_outlined,
                title: 'Call us',
                subtitle: AppInfoContent.supportPhone,
                onTap: () => _call(context),
              ),
              const Divider(height: 1),
              _ContactTile(
                icon: Icons.language_rounded,
                title: 'Visit website',
                subtitle: AppInfoContent.websiteUrl,
                onTap: () => _openWebsite(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: AppColors.sage.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Support hours: ${AppInfoContent.supportHours}',
                    style: AppFonts.style(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepGreen.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Frequently asked questions',
            style: AppFonts.style(
              context,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 12),
          ...AppInfoContent.faqs.map(
            (faq) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FaqTile(
                question: faq.question,
                answer: faq.answer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: AppColors.brandPurple.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.brandPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.brandPurple, size: 22),
      ),
      title: Text(
        title,
        style: AppFonts.style(
          context,
          fontWeight: FontWeight.w700,
          color: AppColors.deepGreen,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppFonts.style(
          context,
          fontSize: 12,
          color: AppColors.deepGreen.withValues(alpha: 0.6),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.deepGreen.withValues(alpha: 0.4),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.08),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.brandPurple,
          collapsedIconColor: AppColors.brandPurple,
          title: Text(
            question,
            style: AppFonts.style(
              context,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.deepGreen,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: AppFonts.style(
                  context,
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.deepGreen.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
