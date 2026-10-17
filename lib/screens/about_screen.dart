import 'package:flutter/material.dart';

import '../content/app_info_content.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/profile_info_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileInfoScaffold(
      title: 'About Made by Maa',
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: AppColors.brandPurple.withValues(alpha: 0.25),
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(
                    'assets/images/made_by_maa_logo.png',
                    height: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppInfoContent.appName,
                  style: AppFonts.style(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppInfoContent.appTagline,
                  textAlign: TextAlign.center,
                  style: AppFonts.style(
                    context,
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          InfoDocumentCard(body: AppInfoContent.aboutBody),
          const SizedBox(height: 20),
          _ValueTile(
            icon: Icons.restaurant_rounded,
            title: 'Home kitchens',
            subtitle: 'Discover cooks and regional dishes near you.',
          ),
          const SizedBox(height: 10),
          _ValueTile(
            icon: Icons.delivery_dining_rounded,
            title: 'Order with ease',
            subtitle: 'Browse, cart, checkout, and track — all in one app.',
          ),
          const SizedBox(height: 10),
          _ValueTile(
            icon: Icons.favorite_rounded,
            title: 'Support local',
            subtitle: 'Every order helps home food entrepreneurs grow.',
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Customer app · Version 1.0.0',
              style: AppFonts.style(
                context,
                fontSize: 12,
                color: AppColors.deepGreen.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amberGlow.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.terracotta),
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
                    color: AppColors.deepGreen.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
