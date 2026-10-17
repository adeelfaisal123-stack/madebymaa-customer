import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Rounded search field used on discover, kitchens, and dishes screens.
class CustomerSearchField extends StatefulWidget {
  const CustomerSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.primary = AppColors.brandPurple,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final Color primary;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CustomerSearchField> createState() => _CustomerSearchFieldState();
}

class _CustomerSearchFieldState extends State<CustomerSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CustomerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    widget.onChanged?.call(widget.controller.text);
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: (value) {
        setState(() {});
        widget.onChanged?.call(value);
      },
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      style: AppFonts.style(context, color: AppColors.deepGreen),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: widget.hint,
        hintStyle: AppFonts.style(
          context,
          color: AppColors.deepGreen.withValues(alpha: 0.45),
        ),
        prefixIcon: Icon(Icons.search_rounded, color: widget.primary),
        suffixIcon: widget.controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.deepGreen.withValues(alpha: 0.45),
                ),
                onPressed: _clear,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
