import 'package:flutter/material.dart';

import '../customer_location_prefs.dart';
import '../customer_session_prefs.dart';
import '../models/customer_delivery_location.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_system_ui.dart';
import '../widgets/app_toast.dart';
import 'location_picker_screen.dart';

/// Manage saved delivery addresses for a signed-in customer.
class DeliveryLocationsScreen extends StatefulWidget {
  const DeliveryLocationsScreen({super.key});

  @override
  State<DeliveryLocationsScreen> createState() => _DeliveryLocationsScreenState();
}

class _DeliveryLocationsScreenState extends State<DeliveryLocationsScreen> {
  int? _customerId;
  List<CustomerDeliveryLocation> _locations = const [];
  String? _activeId;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await CustomerSessionPrefs.load();
    if (session == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    await CustomerLocationPrefs.migrateLegacyToCustomer(session.id);
    final locations = await CustomerLocationPrefs.listForCustomer(session.id);
    final activeId = await CustomerLocationPrefs.activeLocationId();

    if (!mounted) return;
    setState(() {
      _customerId = session.id;
      _locations = locations;
      _activeId = activeId ?? (locations.isNotEmpty ? locations.first.id : null);
      _loading = false;
    });
  }

  Future<void> _addLocation() async {
    final customerId = _customerId;
    if (customerId == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          customerId: customerId,
          popOnSave: true,
        ),
      ),
    );

    if (saved == true) await _load();
  }

  Future<void> _editLocation(CustomerDeliveryLocation location) async {
    final customerId = _customerId;
    if (customerId == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          customerId: customerId,
          editLocation: location,
          popOnSave: true,
        ),
      ),
    );

    if (saved == true) await _load();
  }

  Future<void> _setActive(CustomerDeliveryLocation location) async {
    final customerId = _customerId;
    if (customerId == null || _activeId == location.id) return;

    await CustomerLocationPrefs.setActiveForCustomer(customerId, location.id);
    await _load();
  }

  Future<void> _deleteLocation(CustomerDeliveryLocation location) async {
    final customerId = _customerId;
    if (customerId == null) return;

    if (_locations.length <= 1) {
      if (!mounted) return;
      AppToast.warning(context, 'Keep at least one delivery address.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove address?',
          style: AppFonts.style(ctx, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '“${location.displayLabel}” will be removed from your saved addresses.',
          style: AppFonts.style(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.terracotta),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await CustomerLocationPrefs.deleteForCustomer(
      customerId: customerId,
      locationId: location.id,
    );

    if (!ok && mounted) {
      AppToast.error(context, 'Could not remove this address.');
      return;
    }

    await _load();
    if (mounted) {
      AppToast.success(context, 'Address removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = AppSystemUi.topInset(context, 0);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Delivery locations',
          style: AppFonts.style(
            context,
            fontWeight: FontWeight.w800,
            color: AppColors.deepGreen,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _addLocation,
        backgroundColor: AppColors.brandPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(
          'Add address',
          style: AppFonts.style(context, fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPurple),
            )
          : RefreshIndicator(
              color: AppColors.brandPurple,
              onRefresh: _load,
              child: ListView(
              padding: EdgeInsets.fromLTRB(20, top, 20, 120),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                Text(
                  'Choose where orders should be delivered. You can save home, work, and other addresses.',
                  style: AppFonts.style(
                    context,
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.deepGreen.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 20),
                if (_locations.isEmpty)
                  _EmptyLocations(onAdd: _addLocation)
                else
                  ..._locations.map((loc) {
                    final isActive = loc.id == _activeId;
                    return _LocationCard(
                      location: loc,
                      isActive: isActive,
                      onSelect: () => _setActive(loc),
                      onEdit: () => _editLocation(loc),
                      onDelete: () => _deleteLocation(loc),
                    );
                  }),
              ],
            ),
            ),
    );
  }
}

class _EmptyLocations extends StatelessWidget {
  const _EmptyLocations({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: AppColors.brandPurple.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 48,
            color: AppColors.brandPurple.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No saved addresses yet',
            style: AppFonts.style(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address to get started.',
            textAlign: TextAlign.center,
            style: AppFonts.style(
              context,
              fontSize: 13,
              color: AppColors.deepGreen.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Add address',
              style: AppFonts.style(context, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomerDeliveryLocation location;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? AppColors.brandPurple.withValues(alpha: 0.45)
              : AppColors.brandPurple.withValues(alpha: 0.08),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: AppColors.brandPurple.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.brandPurple.withValues(alpha: 0.12)
                        : AppColors.sage.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.check_circle_rounded : Icons.place_outlined,
                    color: isActive ? AppColors.brandPurple : AppColors.sage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              location.displayLabel,
                              style: AppFonts.style(
                                context,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepGreen,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Active',
                                style: AppFonts.style(
                                  context,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandPurple,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location.address,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          context,
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.deepGreen.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.deepGreen.withValues(alpha: 0.5),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
