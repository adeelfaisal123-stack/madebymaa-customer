import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/country_dial_codes.dart';
import '../theme/app_colors.dart';

/// Searchable bottom sheet to pick a country dial code.
Future<CountryDialCode?> showCountryDialCodePicker(
  BuildContext context, {
  required CountryDialCode selected,
}) {
  return showModalBottomSheet<CountryDialCode>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CountryDialCodeSheet(selected: selected),
  );
}

class _CountryDialCodeSheet extends StatefulWidget {
  const _CountryDialCodeSheet({required this.selected});

  final CountryDialCode selected;

  @override
  State<_CountryDialCodeSheet> createState() => _CountryDialCodeSheetState();
}

class _CountryDialCodeSheetState extends State<_CountryDialCodeSheet> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryDialCode> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return CountryDialCodes.all;
    return CountryDialCodes.all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.dialCode.contains(q) ||
          c.isoCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Country code',
                        style: GoogleFonts.exo2(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.deepGreen),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.exo2(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepGreen,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search country or code',
                    hintStyle: GoogleFonts.exo2(
                      color: AppColors.deepGreen.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brandPurple),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.brandPurple.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final country = _filtered[i];
                    final isSelected = country.isoCode == widget.selected.isoCode;

                    return Material(
                      color: isSelected
                          ? AppColors.brandPurple.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(country),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Text(country.flagEmoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  country.name,
                                  style: GoogleFonts.exo2(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepGreen,
                                  ),
                                ),
                              ),
                              Text(
                                country.dialCode,
                                style: GoogleFonts.exo2(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandPurple,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.brandPurple,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
