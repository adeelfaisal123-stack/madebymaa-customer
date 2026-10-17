import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Shared scaffold for profile info screens (help, legal, about).
class ProfileInfoScaffold extends StatelessWidget {
  const ProfileInfoScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onRefresh,
  });

  final String title;
  final Widget body;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppColors.deepGreen),
          title: Text(
            title,
            style: AppFonts.style(
              context,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
        ),
        body: onRefresh == null
            ? body
            : RefreshIndicator(
                color: AppColors.brandPurple,
                onRefresh: onRefresh!,
                child: body,
              ),
      ),
    );
  }
}

/// White card with selectable body text for legal documents.
class InfoDocumentCard extends StatelessWidget {
  const InfoDocumentCard({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: SelectableText(
        body.trim(),
        style: AppFonts.style(
          context,
          fontSize: 14,
          height: 1.55,
          color: AppColors.deepGreen.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
