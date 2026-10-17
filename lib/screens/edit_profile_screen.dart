import 'package:flutter/material.dart';

import '../customer_session_prefs.dart';
import '../models/customer_auth.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/app_toast.dart';
import '../widgets/profile_info_scaffold.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.session});

  final CustomerAuth session;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _api = Optica2Api();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _emailController = TextEditingController(text: widget.session.email ?? '');
    _loadProfile();
  }

  @override
  void dispose() {
    _api.close();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    try {
      final customer = await _api.fetchCustomerProfile(
        customerId: widget.session.id,
        customerPhone: widget.session.phone,
      );
      if (!mounted) return;
      _nameController.text = customer.name;
      _emailController.text = customer.email ?? '';
      setState(() => _loading = false);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load profile.';
      });
    }
  }

  Future<void> _refresh() => _loadProfile(showLoading: false);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = await _api.updateCustomerProfile(
        customerId: widget.session.id,
        customerPhone: widget.session.phone,
        name: _nameController.text,
        email: _emailController.text,
      );
      await CustomerSessionPrefs.save(updated);
      if (!mounted) return;
      AppToast.success(context, 'Profile updated');
      Navigator.of(context).pop(updated);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, 'Could not update profile.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileInfoScaffold(
      title: 'Edit profile',
      onRefresh: _loading ? null : _refresh,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPurple),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: AppFonts.style(
                        context,
                        fontSize: 13,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Update your account details. Phone number is linked to sign-in and cannot be changed here.',
                  style: AppFonts.style(
                    context,
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.deepGreen.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _ProfileField(
                        controller: _nameController,
                        label: 'Full name',
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) return null;
                          final emailPattern = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );
                          if (!emailPattern.hasMatch(trimmed)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        initialValue: widget.session.phone,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPurple,
                      disabledBackgroundColor:
                          AppColors.brandPurple.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save changes',
                            style: AppFonts.style(
                              context,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    this.controller,
    this.initialValue,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: AppFonts.style(
        context,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: readOnly
            ? AppColors.deepGreen.withValues(alpha: 0.55)
            : AppColors.deepGreen,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.brandPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.brandPurple.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.brandPurple.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandPurple, width: 2),
        ),
        labelStyle: AppFonts.style(
          context,
          color: AppColors.deepGreen.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
