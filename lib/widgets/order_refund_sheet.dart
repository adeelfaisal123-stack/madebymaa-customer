import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer_order.dart';
import '../services/customer_orders_store.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/optica2_asset_url.dart';
import '../widgets/app_toast.dart';

class OrderRefundSheet extends StatefulWidget {
  const OrderRefundSheet({
    super.key,
    required this.order,
    this.api,
  });

  final CustomerOrder order;
  final Optica2Api? api;

  static Future<void> show(
    BuildContext context, {
    required CustomerOrder order,
    Optica2Api? api,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderRefundSheet(order: order, api: api),
    );
  }

  @override
  State<OrderRefundSheet> createState() => _OrderRefundSheetState();
}

class _OrderRefundSheetState extends State<OrderRefundSheet> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _image;
  var _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (!mounted || picked == null) return;
    setState(() => _image = picked);
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.length < 10) {
      AppToast.warning(context, 'Please describe the issue (at least 10 characters).');
      return;
    }

    setState(() => _submitting = true);
    try {
      await CustomerOrdersStore.instance.requestRefund(
        api: widget.api,
        order: widget.order,
        description: description,
        imagePath: _image?.path,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(context, 'Refund request submitted.');
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not submit refund request.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Apply for refund',
                  style: GoogleFonts.exo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tell us what went wrong with order ${widget.order.id}. Our team will review your request.',
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.deepGreen.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 2000,
                  style: GoogleFonts.exo2(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue…',
                    hintStyle: GoogleFonts.exo2(
                      color: AppColors.deepGreen.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterStyle: GoogleFonts.exo2(
                      fontSize: 11,
                      color: AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
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
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Photo (optional)',
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                if (_image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_image!.path),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(
                        'Camera',
                        style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandPurple,
                        side: BorderSide(
                          color: AppColors.brandPurple.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        'Gallery',
                        style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandPurple,
                        side: BorderSide(
                          color: AppColors.brandPurple.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    if (_image != null) ...[
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove photo',
                        onPressed: _submitting ? null : () => setState(() => _image = null),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.terracotta.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit refund request',
                          style: GoogleFonts.exo2(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RefundPendingBanner extends StatelessWidget {
  const RefundPendingBanner({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveOptica2AssetUrl(order.refundRequestImageUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberGlow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amberGlow.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.amberGlow.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Refund request under review',
                  style: GoogleFonts.exo2(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
            ],
          ),
          if (order.refundRequestDescription != null &&
              order.refundRequestDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              order.refundRequestDescription!,
              style: GoogleFonts.exo2(
                fontSize: 13,
                height: 1.45,
                color: AppColors.deepGreen.withValues(alpha: 0.68),
              ),
            ),
          ],
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
