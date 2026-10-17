import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_startup_popup.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Launch announcement from Optica2 admin (title + body).
class StartupPopupDialog extends StatelessWidget {
  const StartupPopupDialog({super.key, required this.popup});

  final CustomerStartupPopup popup;

  static Future<void> showIfNeeded(
    BuildContext context,
    CustomerStartupPopup popup,
  ) {
    if (!popup.enabled || popup.title.isEmpty) {
      return Future.value();
    }
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, _) => StartupPopupDialog(popup: popup),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _close(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.brandPurple.withValues(alpha: 0.08),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(title: popup.title),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _HighlightIconsRow(),
                          if (popup.content.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: AppColors.brandPurple
                                      .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    popup.content,
                                    style: AppFonts.style(
                                      context,
                                      fontSize: 15,
                                      height: 1.55,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.deepGreen
                                          .withValues(alpha: 0.78),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _CloseButton(
                  tooltip: l10n.startupPopupClose,
                  onTap: () => _close(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.close_rounded,
              size: 22,
              color: AppColors.deepGreen.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightIconsRow extends StatelessWidget {
  const _HighlightIconsRow();

  static const _items = [
    (Icons.eco_rounded, AppColors.sage),
    (Icons.home_rounded, AppColors.terracotta),
    (Icons.storefront_rounded, AppColors.brandPurple),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (icon, color) in _items)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPurple,
            AppColors.brandPurpleDeep,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(
              context,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
