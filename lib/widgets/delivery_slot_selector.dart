import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/delivery_slot.dart';
import '../models/dish_main_category.dart';
import '../theme/app_colors.dart';

class DeliverySlotSelector extends StatefulWidget {
  const DeliverySlotSelector({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.allowDeliverNow = true,
  });

  final List<DishMainCategory> categories;
  final DeliverySlotSelection selected;
  final ValueChanged<DeliverySlotSelection> onSelected;
  final bool allowDeliverNow;

  @override
  State<DeliverySlotSelector> createState() => _DeliverySlotSelectorState();
}

class _DeliverySlotSelectorState extends State<DeliverySlotSelector> {
  late String _dayKey;
  var _scheduleExpanded = false;

  List<DeliveryDayDef> get _availableDays =>
      availableDeliveryDayDefs(categories: widget.categories);

  String? get _firstAvailableDayKey =>
      _availableDays.isEmpty ? null : _availableDays.first.$1;

  bool get _selectedDayHasSlots =>
      _availableDays.any((day) => day.$1 == _dayKey);

  @override
  void initState() {
    super.initState();
    _dayKey = _resolveInitialDayKey();
    _scheduleExpanded =
        !widget.allowDeliverNow || !widget.selected.isNow;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDayWithParent());
  }

  @override
  void didUpdateWidget(DeliverySlotSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.allowDeliverNow && widget.selected.isNow) {
      setState(() => _scheduleExpanded = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.allowDeliverNow || !widget.selected.isNow) {
          return;
        }
        final dayKey = _firstAvailableDayKey ?? _dayKey;
        if (_firstAvailableDayKey != null) {
          _dayKey = dayKey;
        }
        widget.onSelected(
          DeliverySlotSelection(
            isNow: false,
            dayKey: dayKey,
            displayLabel: deliveryDayLabel(dayKey),
          ),
        );
      });
      return;
    }

    if (oldWidget.categories != widget.categories) {
      final resolved = _resolveInitialDayKey();
      if (resolved != _dayKey) {
        setState(() => _dayKey = resolved);
        _syncDayWithParent();
      }
    } else if (!_selectedDayHasSlots && _firstAvailableDayKey != null) {
      setState(() => _dayKey = _firstAvailableDayKey!);
      _syncDayWithParent();
    }

    if (widget.selected.isNow) {
      if (!oldWidget.selected.isNow) {
        _scheduleExpanded = false;
      }
      return;
    }

    final selectedDay = widget.selected.dayKey;
    if (selectedDay != null &&
        selectedDay != _dayKey &&
        _availableDays.any((day) => day.$1 == selectedDay)) {
      _dayKey = selectedDay;
    }
    if (widget.selected.isScheduledComplete) {
      _scheduleExpanded = true;
    }
  }

  String _resolveInitialDayKey() {
    final preferred = widget.selected.dayKey;
    if (preferred != null &&
        _availableDays.any((day) => day.$1 == preferred)) {
      return preferred;
    }
    return _firstAvailableDayKey ?? deliverySlotDayDefs.first.$1;
  }

  void _syncDayWithParent() {
    if (!mounted || widget.selected.isNow || _firstAvailableDayKey == null) {
      return;
    }

    if (!_selectedDayHasSlots || widget.selected.dayKey != _dayKey) {
      widget.onSelected(
        DeliverySlotSelection(
          isNow: false,
          dayKey: _dayKey,
          displayLabel: deliveryDayLabel(_dayKey),
        ),
      );
    }
  }

  List<DeliveryHalfHourSlot> get _timeSlots => buildHalfHourDeliverySlots(
        categories: widget.categories,
        dayKey: _dayKey,
      );

  void _selectNow() {
    setState(() => _scheduleExpanded = false);
    widget.onSelected(const DeliverySlotSelection.now());
  }

  void _toggleSchedule() {
    setState(() {
      _scheduleExpanded = !_scheduleExpanded;
    });

    if (_scheduleExpanded && widget.selected.isNow) {
      final dayKey = _firstAvailableDayKey ?? _dayKey;
      if (_firstAvailableDayKey != null) {
        _dayKey = dayKey;
      }
      widget.onSelected(
        DeliverySlotSelection(
          isNow: false,
          dayKey: dayKey,
          displayLabel: deliveryDayLabel(dayKey),
        ),
      );
    }
  }

  void _onDayChanged(String day) {
    setState(() {
      _dayKey = day;
      _scheduleExpanded = true;
    });
    widget.onSelected(
      DeliverySlotSelection(
        isNow: false,
        dayKey: day,
        displayLabel: deliveryDayLabel(day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDays = _availableDays;

    return Column(
      children: [
        if (widget.allowDeliverNow) ...[
          _NowCard(
            selected: widget.selected.isNow,
            onTap: _selectNow,
          ),
          const SizedBox(height: 12),
        ],
        _ScheduleCard(
          expanded: _scheduleExpanded,
          dayKey: _dayKey,
          categories: widget.categories,
          availableDays: availableDays,
          timeSlots: _timeSlots,
          selected: widget.selected,
          onHeaderTap: _toggleSchedule,
          onDayChanged: _onDayChanged,
          onSlotSelected: (slot) {
            setState(() => _scheduleExpanded = true);
            widget.onSelected(
              selectionForHalfHourSlot(dayKey: _dayKey, slot: slot),
            );
          },
        ),
      ],
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableShell(
      selected: selected,
      accent: AppColors.terracotta,
      onTap: onTap,
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.bolt_rounded,
            accent: AppColors.terracotta,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deliver now',
                  style: GoogleFonts.exo2(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'As soon as the kitchen can send it',
                  style: GoogleFonts.exo2(
                    fontSize: 12,
                    color: AppColors.deepGreen.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          _SelectionMark(selected: selected, accent: AppColors.terracotta),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.expanded,
    required this.dayKey,
    required this.categories,
    required this.availableDays,
    required this.timeSlots,
    required this.selected,
    required this.onHeaderTap,
    required this.onDayChanged,
    required this.onSlotSelected,
  });

  final bool expanded;
  final String dayKey;
  final List<DishMainCategory> categories;
  final List<DeliveryDayDef> availableDays;
  final List<DeliveryHalfHourSlot> timeSlots;
  final DeliverySlotSelection selected;
  final VoidCallback onHeaderTap;
  final ValueChanged<String> onDayChanged;
  final ValueChanged<DeliveryHalfHourSlot> onSlotSelected;

  bool get _scheduleSelected => !selected.isNow;

  bool get _showDayToggle => availableDays.length > 1;

  String get _collapsedSubtitle {
    if (selected.isScheduledComplete) {
      return selected.displayLabel;
    }
    if (!selected.isNow && selected.dayKey != null) {
      return '${deliveryDayLabel(selected.dayKey!)} · pick a time';
    }
    return categories.length == 1
        ? '${categories.first.name} · ${categories.first.timeRange}'
        : 'Pick a day and 30-minute slot';
  }

  @override
  Widget build(BuildContext context) {
    return _SelectableShell(
      selected: _scheduleSelected,
      accent: AppColors.brandPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHeaderTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    _IconBadge(
                      icon: Icons.event_available_rounded,
                      accent: AppColors.brandPurple,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule delivery',
                            style: GoogleFonts.exo2(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _collapsedSubtitle,
                            maxLines: expanded ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.deepGreen.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: _scheduleSelected
                            ? AppColors.brandPurple
                            : AppColors.deepGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _SelectionMark(
                      selected: _scheduleSelected,
                      accent: AppColors.brandPurple,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showDayToggle) ...[
                    Text(
                      'Choose day',
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DayToggleBar(
                      availableDays: availableDays,
                      selectedDayKey: dayKey,
                      onDayChanged: onDayChanged,
                    ),
                    const SizedBox(height: 16),
                  ] else if (availableDays.length == 1) ...[
                    _SingleDayBadge(
                      title: availableDays.first.$2,
                      subtitle: deliveryDayShortDate(availableDays.first.$1),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Choose 30-min slot',
                    style: GoogleFonts.exo2(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (categories.isEmpty)
                    Text(
                      'Add dishes with a meal category to see time slots.',
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        color: AppColors.deepGreen.withValues(alpha: 0.5),
                      ),
                    )
                  else if (availableDays.isEmpty)
                    Text(
                      'No delivery slots in the next 3 days. Try again later or choose different dishes.',
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.deepGreen.withValues(alpha: 0.5),
                      ),
                    )
                  else if (timeSlots.isEmpty)
                    Text(
                      'No slots left for ${deliveryDayLabel(dayKey).toLowerCase()}.',
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        color: AppColors.deepGreen.withValues(alpha: 0.5),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final slot in timeSlots)
                          _TimeSlotChip(
                            label: slot.label,
                            selected: selected.matchesScheduledSlot(
                              dayKey: dayKey,
                              superCategoryId: slot.superCategoryId,
                              timeStart: slot.timeStart,
                              timeEnd: slot.timeEnd,
                            ),
                            onTap: () => onSlotSelected(slot),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleDayBadge extends StatelessWidget {
  const _SingleDayBadge({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.brandPurple.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.deepGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: GoogleFonts.exo2(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayToggleBar extends StatelessWidget {
  const _DayToggleBar({
    required this.availableDays,
    required this.selectedDayKey,
    required this.onDayChanged,
  });

  final List<DeliveryDayDef> availableDays;
  final String selectedDayKey;
  final ValueChanged<String> onDayChanged;

  @override
  Widget build(BuildContext context) {
    if (availableDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        const horizontalPadding = 5.0;
        const verticalPadding = 5.0;
        final innerWidth = constraints.maxWidth - horizontalPadding * 2;
        final segmentWidth = availableDays.length == 1
            ? innerWidth
            : (innerWidth - gap * (availableDays.length - 1)) /
                availableDays.length;
        final selectedIndex = availableDays.indexWhere(
          (def) => def.$1 == selectedDayKey,
        );
        final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 4),
                color: AppColors.brandPurple.withValues(alpha: 0.06),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: safeIndex * (segmentWidth + gap),
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.brandPurple,
                          AppColors.brandPurpleDeep,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                          color: AppColors.brandPurple.withValues(alpha: 0.28),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < availableDays.length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      Expanded(
                        child: _DayToggleSegment(
                          title: availableDays[i].$2,
                          subtitle: deliveryDayShortDate(availableDays[i].$1),
                          selected: selectedDayKey == availableDays[i].$1,
                          onTap: () => onDayChanged(availableDays[i].$1),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayToggleSegment extends StatelessWidget {
  const _DayToggleSegment({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: selected
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.brandPurple.withValues(alpha: 0.08),
        highlightColor: selected
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.brandPurple.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.exo2(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white
                      : AppColors.deepGreen.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.deepGreen.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandPurple : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.brandPurple
                  : AppColors.brandPurple.withValues(alpha: 0.16),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.exo2(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.deepGreen,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableShell extends StatelessWidget {
  const _SelectableShell({
    required this.selected,
    required this.accent,
    required this.child,
    this.onTap,
  });

  final bool selected;
  final Color accent;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: selected ? 2 : 1,
          color: selected
              ? accent
              : AppColors.brandPurple.withValues(alpha: 0.12),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  color: accent.withValues(alpha: 0.12),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: accent, size: 26),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Icon(
      selected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      color: selected ? accent : AppColors.deepGreen.withValues(alpha: 0.25),
      size: 26,
    );
  }
}
