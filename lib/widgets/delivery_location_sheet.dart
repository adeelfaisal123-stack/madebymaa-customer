import 'package:flutter/material.dart';

import '../customer_location_prefs.dart';
import '../customer_session_prefs.dart';
import '../models/customer_delivery_location.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import 'app_toast.dart';
import '../screens/delivery_locations_screen.dart';
import '../screens/location_picker_screen.dart';

/// Quick picker for switching active delivery address.
abstract final class DeliveryLocationSheet {
  static Future<bool> show(BuildContext context) async {
    final session = await CustomerSessionPrefs.load();
    if (session == null) {
      if (!context.mounted) return false;
      final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LocationPickerScreen(popOnSave: true),
        ),
      );
      return changed == true;
    }

    await CustomerLocationPrefs.migrateLegacyToCustomer(session.id);
    final locations = await CustomerLocationPrefs.listForCustomer(session.id);
    final activeId = await CustomerLocationPrefs.activeLocationId();

    if (!context.mounted) return false;

    if (locations.isEmpty) {
      final added = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            customerId: session.id,
            popOnSave: true,
          ),
        ),
      );
      return added == true;
    }

    if (locations.length == 1) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.cream,
        builder: (ctx) => _SingleLocationActions(
          location: locations.first,
          customerId: session.id,
        ),
      );
      return result == true;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      builder: (ctx) => _LocationListSheet(
        locations: locations,
        activeId: activeId,
        customerId: session.id,
      ),
    );
    return changed == true;
  }
}

class _SingleLocationActions extends StatelessWidget {
  const _SingleLocationActions({
    required this.location,
    required this.customerId,
  });

  final CustomerDeliveryLocation location;
  final int customerId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              location.displayLabel,
              style: AppFonts.style(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.deepGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              location.address,
              style: AppFonts.style(
                context,
                fontSize: 13,
                color: AppColors.deepGreen.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => LocationPickerScreen(
                      customerId: customerId,
                      editLocation: location,
                      popOnSave: true,
                    ),
                  ),
                );
                if (context.mounted) Navigator.pop(context, ok == true);
              },
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Edit address'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => LocationPickerScreen(
                      customerId: customerId,
                      popOnSave: true,
                    ),
                  ),
                );
                if (context.mounted) Navigator.pop(context, ok == true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add another address'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationListSheet extends StatelessWidget {
  const _LocationListSheet({
    required this.locations,
    required this.activeId,
    required this.customerId,
  });

  final List<CustomerDeliveryLocation> locations;
  final String? activeId;
  final int customerId;

  Future<void> _select(BuildContext context, CustomerDeliveryLocation loc) async {
    await CustomerLocationPrefs.setActiveForCustomer(customerId, loc.id);
    if (context.mounted) {
      AppToast.success(context, 'Delivering to ${loc.displayLabel}');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delivery location',
              style: AppFonts.style(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.deepGreen,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: locations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  final isActive = loc.id == activeId;
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isActive
                              ? AppColors.brandPurple.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      leading: Icon(
                        isActive
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isActive ? AppColors.brandPurple : AppColors.sage,
                      ),
                      title: Text(
                        loc.displayLabel,
                        style: AppFonts.style(
                          context,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepGreen,
                        ),
                      ),
                      subtitle: Text(
                        loc.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          context,
                          fontSize: 12,
                          color: AppColors.deepGreen.withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () => _select(context, loc),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const DeliveryLocationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Manage addresses'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => LocationPickerScreen(
                      customerId: customerId,
                      popOnSave: true,
                    ),
                  ),
                );
                if (context.mounted) Navigator.pop(context, ok == true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add new address'),
            ),
          ],
        ),
      ),
    );
  }
}
