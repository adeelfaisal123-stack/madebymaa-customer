import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:pinput/pinput.dart';

import '../config/optica2_config.dart';
import '../customer_location_prefs.dart';
import '../customer_session_prefs.dart';
import '../firebase_bootstrap.dart';
import '../models/customer_auth.dart';
import '../models/otp_config.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_navigation.dart';
import '../utils/app_system_ui.dart';
import '../widgets/app_toast.dart';
import '../widgets/locale_phone_field.dart';

enum _AuthStep { phone, verify, profile }

/// Phone OTP login — Firebase or MSG91 per admin SMS Gateway.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _api = Optica2Api();

  late final AnimationController _heroAnim;

  PhoneNumber? _phone;
  OtpConfig? _otpConfig;
  CustomerPhoneCheckResult? _phoneCheck;
  bool _firebaseReady = false;
  bool _msg91Ready = false;
  String? _bootstrapError;

  _AuthStep _step = _AuthStep.phone;

  bool get _useMsg91 => _otpConfig?.isMsg91 ?? false;
  bool get _authReady => _useMsg91 ? _msg91Ready : _firebaseReady;
  bool get _isNewCustomer => _phoneCheck?.isNewCustomer ?? true;
  int get _stepCount => _isNewCustomer ? 3 : 2;

  bool _sending = false;
  bool _verifying = false;
  String? _sentPhoneE164;
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmation;

  int _resendSeconds = 0;
  Timer? _resendTimer;
  Timer? _sendOtpWatchdog;

  static const _otpLength = 6;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _bootstrapError = null;
        _firebaseReady = false;
        _msg91Ready = false;
        _otpConfig = null;
      });
    }

    try {
      await Optica2Config.refresh();
      final config = await _api.fetchOtpConfig();
      if (!mounted) return;

      setState(() => _otpConfig = config);

      if (config.isMsg91) {
        if (!config.configured) {
          setState(() {
            _bootstrapError =
                'MSG91 is selected but the Auth Key is missing on the server at ${Optica2Config.baseUrl}. '
                'Open Admin → API Management → OTP, enter the Auth Key, and save.';
          });
          return;
        }
        setState(() => _msg91Ready = true);
      } else {
        await ensureFirebaseInitialized();
        if (!mounted) return;
        setState(() => _firebaseReady = true);
      }
    } catch (e, st) {
      debugPrint('Login bootstrap failed: $e\n$st');
      if (mounted) {
        setState(() {
          _bootstrapError = _useMsg91
              ? 'Could not reach the API. Check your connection and try again.'
              : firebaseBootstrapErrorMessage(e);
          _firebaseReady = false;
          _msg91Ready = false;
        });
      }
    }
  }

  void _cancelSendOtpWatchdog() {
    _sendOtpWatchdog?.cancel();
    _sendOtpWatchdog = null;
  }

  void _startSendOtpWatchdog() {
    _cancelSendOtpWatchdog();
    _sendOtpWatchdog = Timer(const Duration(seconds: 95), () {
      if (!mounted) return;
      if (!_sending || _step != _AuthStep.verify) return;
      setState(() => _sending = false);
      _showMessage(
        'SMS is taking longer than usual. Tap resend to try again.',
        isError: false,
      );
    });
  }

  void _goToVerify(String phoneE164, {bool resent = false}) {
    _cancelSendOtpWatchdog();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _step = _AuthStep.verify;
      _sentPhoneE164 = phoneE164;
    });
    if (!resent) {
      _showMessage('Code sent to $phoneE164', isError: false);
    }
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _resendTimer?.cancel();
    _cancelSendOtpWatchdog();
    _api.close();
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _pinFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String _e164(PhoneNumber phone) {
    final raw = phone.completeNumber;
    if (raw.startsWith('+')) return raw;
    return '+$raw';
  }

  String _phoneE164ForSession() {
    if (_sentPhoneE164 != null && _sentPhoneE164!.isNotEmpty) {
      return _sentPhoneE164!;
    }
    if (!_useMsg91 && _firebaseReady) {
      final firebasePhone = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (firebasePhone != null && firebasePhone.isNotEmpty) {
        return firebasePhone;
      }
    }
    final phone = _phone;
    if (phone != null) return _e164(phone);
    return '';
  }

  String _maskedPhone() {
    final p = _phoneE164ForSession();
    if (p.length < 8) return p;
    return '${p.substring(0, p.length - 4)} ••••';
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _showMessage(String text, {required bool isError}) {
    if (!mounted) return;
    if (isError) {
      AppToast.error(context, text);
    } else {
      AppToast.success(context, text);
    }
  }

  Future<void> _sendOtp({bool resend = false}) async {
    if (!_authReady || _bootstrapError != null) return;

    if (!resend) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      _formKey.currentState!.save();
    }

    final phone = _phone;
    if (!resend && (phone == null || phone.number.trim().isEmpty)) {
      _showMessage('Enter a valid phone number.', isError: true);
      return;
    }

    final full = resend && _sentPhoneE164 != null && _sentPhoneE164!.isNotEmpty
        ? _sentPhoneE164!
        : _e164(phone!);

    setState(() {
      _sending = true;
      if (resend) _pinController.clear();
    });
    _startSendOtpWatchdog();

    if (!resend) {
      try {
        final check = await _api.checkCustomerPhone(full);
        if (!mounted) return;

        if (!check.canLogin) {
          _cancelSendOtpWatchdog();
          setState(() => _sending = false);
          _showMessage(
            check.message.isNotEmpty
                ? check.message
                : 'This number cannot sign in.',
            isError: true,
          );
          return;
        }

        setState(() {
          _phoneCheck = check;
          final existingName = check.customer?.name.trim();
          if (existingName != null &&
              existingName.isNotEmpty &&
              existingName != 'Customer') {
            _nameController.text = existingName;
          }
        });
      } on Optica2ApiException catch (e) {
        if (!mounted) return;
        _cancelSendOtpWatchdog();
        setState(() => _sending = false);
        _showMessage(_friendlyApiError(e.message), isError: true);
        return;
      }
    }

    try {
      if (_useMsg91) {
        if (kDebugMode) {
          debugPrint('LoginScreen MSG91 send → $full (${Optica2Config.baseUrl})');
        }
        await _api.sendOtp(full);
        if (!mounted) return;
        _goToVerify(full, resent: resend);
        _startResendCooldown();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _pinFocus.requestFocus(),
        );
        return;
      }

      if (kIsWeb) {
        _webConfirmation =
            await FirebaseAuth.instance.signInWithPhoneNumber(full);
        if (!mounted) return;
        _goToVerify(full);
        _startResendCooldown();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _pinFocus.requestFocus(),
        );
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: full,
        timeout: const Duration(seconds: 90),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _cancelSendOtpWatchdog();
          if (mounted) setState(() => _sending = false);
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) await _afterOtpVerified();
          } catch (e) {
            if (!mounted) return;
            _showMessage('$e', isError: true);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          _cancelSendOtpWatchdog();
          setState(() => _sending = false);
          _showMessage(e.message ?? 'Verification failed', isError: true);
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = forceResendingToken;
          });
          _goToVerify(full);
          _startResendCooldown();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _pinFocus.requestFocus(),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          setState(() => _verificationId = verificationId);
          _goToVerify(full);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _pinFocus.requestFocus(),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _cancelSendOtpWatchdog();
      setState(() => _sending = false);
      _showMessage('$e', isError: true);
    }
  }

  Future<void> _verifyOtp(String pin) async {
    if (pin.length != _otpLength || _verifying) return;
    if (!_authReady) return;

    setState(() => _verifying = true);

    try {
      if (_useMsg91) {
        final phone = _phoneE164ForSession();
        if (phone.isEmpty) {
          throw StateError('Enter your phone number again.');
        }
        await _api.verifyOtp(phone, pin);
        if (!mounted) return;
        await _afterOtpVerified();
        return;
      }

      if (kIsWeb) {
        final conf = _webConfirmation;
        if (conf == null) {
          throw StateError('No web confirmation. Send OTP again.');
        }
        await conf.confirm(pin);
      } else {
        final vid = _verificationId;
        if (vid == null) {
          throw StateError('Missing verification id. Send OTP again.');
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: vid,
          smsCode: pin,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (mounted) await _afterOtpVerified();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message ?? 'Invalid code', isError: true);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyApiError(e.message), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('$e', isError: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _afterOtpVerified() async {
    if (_isNewCustomer) {
      setState(() => _step = _AuthStep.profile);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _nameFocus.requestFocus(),
      );
      return;
    }
    await _completeSessionAndLogin();
  }

  Future<void> _completeProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter your full name.', isError: true);
      return;
    }
    setState(() => _verifying = true);
    try {
      await _completeSessionAndLogin(name: name);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyApiError(e.message), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('$e', isError: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _completeSessionAndLogin({String? name}) async {
    final phone = _phoneE164ForSession();
    if (phone.isEmpty) {
      _showMessage('Could not read phone number.', isError: true);
      return;
    }

    final resolvedName = name ?? _nameController.text.trim();
    final result = await _api.completeCustomerSession(
      phoneE164: phone,
      name: resolvedName.isEmpty ? null : resolvedName,
    );
    await _finishLogin(result);
  }

  String _friendlyApiError(String message) {
    if (message.contains('OTP login requires MSG91') ||
        message.contains('Server OTP is set to Firebase')) {
      return 'This API uses Firebase OTP, not MSG91. Contact admin to switch provider.';
    }
    if (message.contains('OTP is handled by Firebase')) {
      return 'This API uses Firebase OTP. Enable MSG91 in admin if needed.';
    }
    return message;
  }

  Future<void> _finishLogin(CustomerLoginResult result) async {
    await CustomerSessionPrefs.save(result.customer);
    await CustomerLocationPrefs.migrateLegacyToCustomer(result.customer.id);
    if (!mounted) return;
    await AppNavigation.afterLoginCompleted(context);
  }

  void _backStep() {
    if (_step == _AuthStep.profile) return;
    if (_step == _AuthStep.verify) {
      _cancelSendOtpWatchdog();
      setState(() {
        _step = _AuthStep.phone;
        _sentPhoneE164 = null;
        _verificationId = null;
        _webConfirmation = null;
        _pinController.clear();
        _sending = false;
      });
      _resendTimer?.cancel();
      setState(() => _resendSeconds = 0);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  TextStyle _titleStyle(BuildContext context, {double size = 28}) =>
      AppFonts.style(
        context,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: AppColors.deepGreen,
        letterSpacing: -0.6,
        height: 1.15,
      );

  TextStyle _bodyStyle(BuildContext context) => AppFonts.style(
        context,
        fontSize: 15,
        height: 1.5,
        color: AppColors.deepGreen.withValues(alpha: 0.68),
      );

  PinTheme _pinTheme(Color border, {Color? fill}) {
    return PinTheme(
      width: 48,
      height: 56,
      textStyle: GoogleFonts.exo2(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.deepGreen,
      ),
      decoration: BoxDecoration(
        color: fill ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.brandPurple.withValues(alpha: 0.7))
          : null,
      hintStyle: GoogleFonts.exo2(
        color: AppColors.deepGreen.withValues(alpha: 0.35),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.brandPurple.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.brandPurple, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapError != null) {
      return _buildBootstrapError();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Stack(
          children: [
            _AuthBackdrop(animation: _heroAnim),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),
                  _StepIndicator(
                    step: _step,
                    stepCount: _stepCount,
                    isNewCustomer: _isNewCustomer,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) {
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            );
                          },
                          child: _buildStepContent(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    return switch (_step) {
      _AuthStep.phone => _buildPhoneStep(context),
      _AuthStep.verify => _buildVerifyStep(context),
      _AuthStep.profile => _buildProfileStep(context),
    };
  }

  Widget _buildTopBar(BuildContext context) {
    final showBack = _step != _AuthStep.phone || Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: _backStep,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.deepGreen,
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              switch (_step) {
                _AuthStep.phone => 'Welcome',
                _AuthStep.verify => 'Verify code',
                _AuthStep.profile => 'Your profile',
              },
              style: AppFonts.style(
                context,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep(BuildContext context) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(
          icon: Icons.soup_kitchen_rounded,
          accent: AppColors.amberGlow,
          title: 'Homemade,\ndelivered warm',
          subtitle: 'Sign in with your mobile number to order from local kitchens.',
        ),
        const SizedBox(height: 28),
        Text('Mobile number', style: _labelStyle(context)),
        const SizedBox(height: 10),
        LocalePhoneField(
          controller: _phoneController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onSaved: (PhoneNumber? phone) => _phone = phone,
          onChanged: (PhoneNumber phone) => _phone = phone,
          decoration: _phoneFieldDecoration(),
          dropdownTextStyle: GoogleFonts.exo2(
            fontWeight: FontWeight.w600,
            color: AppColors.deepGreen,
          ),
          style: GoogleFonts.exo2(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.deepGreen,
          ),
          flagsButtonPadding: const EdgeInsets.only(left: 8),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          label: _authReady ? 'Continue' : 'Connecting…',
          loading: _sending,
          onPressed: (!_authReady || _sending) ? null : () => _sendOtp(),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ll send a one-time code via SMS. Standard rates may apply.',
          textAlign: TextAlign.center,
          style: _bodyStyle(context).copyWith(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildVerifyStep(BuildContext context) {
    final border = AppColors.brandPurple.withValues(alpha: 0.25);
    final focused = AppColors.brandPurple;

    return Column(
      key: const ValueKey('verify'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(
          icon: Icons.mark_chat_unread_rounded,
          accent: AppColors.sage,
          title: 'Check your\nmessages',
          subtitle: 'Enter the 6-digit code we sent to ${_maskedPhone()}.',
        ),
        const SizedBox(height: 32),
        Center(
          child: Pinput(
            length: _otpLength,
            controller: _pinController,
            focusNode: _pinFocus,
            autofocus: true,
            defaultPinTheme: _pinTheme(border),
            focusedPinTheme: _pinTheme(focused, fill: AppColors.brandPurple.withValues(alpha: 0.04)),
            submittedPinTheme: _pinTheme(focused),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onCompleted: _verifyOtp,
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: 'Verify & continue',
          loading: _verifying,
          onPressed: _verifying ? null : () => _verifyOtp(_pinController.text),
        ),
        if (_useMsg91) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: (_sending || _resendSeconds > 0)
                  ? null
                  : () => _sendOtp(resend: true),
              child: Text(
                _resendSeconds > 0
                    ? 'Resend code in ${_resendSeconds}s'
                    : 'Resend code',
                style: GoogleFonts.exo2(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPurple,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileStep(BuildContext context) {
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(
          icon: Icons.waving_hand_rounded,
          accent: AppColors.terracotta,
          title: 'Almost\nthere!',
          subtitle: 'Tell us your name so kitchens know who\'s ordering.',
        ),
        const SizedBox(height: 28),
        Text('Full name', style: _labelStyle(context)),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.exo2(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.deepGreen,
          ),
          decoration: _fieldDecoration('e.g. Ayesha Khan', icon: Icons.badge_outlined),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandPurple.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 20,
                color: AppColors.brandPurple.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _phoneE164ForSession(),
                  style: GoogleFonts.exo2(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Complete profile',
          loading: _verifying,
          onPressed: _verifying ? null : _completeProfile,
        ),
      ],
    );
  }

  TextStyle _labelStyle(BuildContext context) => AppFonts.style(
        context,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.deepGreen.withValues(alpha: 0.72),
      );

  InputDecoration _phoneFieldDecoration() {
    return InputDecoration(
      hintText: 'Mobile number',
      hintStyle: GoogleFonts.exo2(
        color: AppColors.deepGreen.withValues(alpha: 0.35),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.brandPurple.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.brandPurple.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.brandPurple, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _buildBootstrapError() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Setup needed', style: _titleStyle(context)),
              const SizedBox(height: 12),
              Text(_bootstrapError!, style: _bodyStyle(context)),
              const SizedBox(height: 24),
              _PrimaryButton(label: 'Try again', onPressed: _bootstrap),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Decorative widgets ─────────────────────────────────────────────────────

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + t * 24,
              right: -60,
              child: _orb(180, AppColors.brandPurple.withValues(alpha: 0.14)),
            ),
            Positioned(
              top: 120 - t * 18,
              left: -70,
              child: _orb(140, AppColors.amberGlow.withValues(alpha: 0.22)),
            ),
            Positioned(
              bottom: 60 + t * 20,
              right: -40,
              child: _orb(120, AppColors.sage.withValues(alpha: 0.12)),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.stepCount,
    required this.isNewCustomer,
  });

  final _AuthStep step;
  final int stepCount;
  final bool isNewCustomer;

  int get _activeIndex => switch (step) {
        _AuthStep.phone => 0,
        _AuthStep.verify => 1,
        _AuthStep.profile => 2,
      };

  @override
  Widget build(BuildContext context) {
    final labels = isNewCustomer
        ? ['Phone', 'Code', 'Profile']
        : ['Phone', 'Code'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= _activeIndex
                        ? AppColors.brandPurple
                        : AppColors.brandPurple.withValues(alpha: 0.15),
                  ),
                ),
              ),
            _stepDot(context, i, labels[i]),
          ],
        ],
      ),
    );
  }

  Widget _stepDot(BuildContext context, int i, String label) {
    final done = i < _activeIndex;
    final active = i == _activeIndex;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: active ? 32 : 28,
          height: active ? 32 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active || done
                ? const LinearGradient(
                    colors: [
                      AppColors.brandPurple,
                      AppColors.brandPurpleDeep,
                    ],
                  )
                : null,
            color: active || done
                ? null
                : AppColors.brandPurple.withValues(alpha: 0.08),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '${i + 1}',
                    style: GoogleFonts.exo2(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: active
                          ? Colors.white
                          : AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.exo2(
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active
                ? AppColors.brandPurple
                : AppColors.deepGreen.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.brandPurple.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withValues(alpha: 0.65)],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.style(
                    context,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                    height: 1.12,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: AppFonts.style(
                    context,
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.deepGreen.withValues(alpha: 0.62),
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: onPressed != null
            ? const LinearGradient(
                colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
              )
            : null,
        color: onPressed == null ? AppColors.brandPurple.withValues(alpha: 0.35) : null,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.exo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
