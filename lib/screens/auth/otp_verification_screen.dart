import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String identifier;
  final UserType userType;
  final bool isRegistration;
  final User? registrationUser;
  final bool isSecondFactor;

  const OTPVerificationScreen({
    super.key,
    required this.identifier,
    required this.userType,
    this.isRegistration = false,
    this.registrationUser,
    this.isSecondFactor = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.isSecondFactor ? '2-Step Verification' : 'OTP Verification',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1608),
              Color(0xFF8E4E17),
              Color(0xFF1D2C1B),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD7AA).withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              top: 220,
              left: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: 0.13),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 72,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  Icons.account_balance,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 18),
                    _buildOtpCard(),
                    const SizedBox(height: 18),
                    _buildVerifyButton(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive OTP?",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        TextButton(
                          onPressed: _resendOtp,
                          child: const Text('Resend'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB562), Color(0xFFE37612)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.saffron.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                color: Colors.white, size: 33),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isSecondFactor
                      ? 'Secure 2-Step Check'
                      : 'Verify Login OTP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isSecondFactor
                      ? 'Enter your second-factor OTP to continue'
                      : 'A 6-digit code was sent to ${widget.identifier}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                  ),
                ),
                if (widget.isSecondFactor) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Demo OTP: 123456',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter OTP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type each digit clearly. You can also paste full OTP.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final double available =
                  constraints.maxWidth - (5 * 8); // 6 boxes, 5 gaps
              final double boxSize = math.min(54, math.max(44, available / 6));
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: boxSize,
                    height: boxSize + 10,
                    child: _buildOtpField(index),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index) {
    final bool hasFocus = _focusNodes[index].hasFocus;
    final bool hasValue = _controllers[index].text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: hasFocus
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: hasFocus || hasValue
              ? const Color(0xFFFFBF78)
              : Colors.white.withValues(alpha: 0.22),
          width: hasFocus ? 1.8 : 1.2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          textInputAction: index == 5 ? TextInputAction.done : TextInputAction.next,
          cursorColor: AppColors.saffron,
          enableSuggestions: false,
          autocorrect: false,
          maxLength: 1,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: false,
          ),
          onChanged: (value) => _handleOtpChanged(index, value),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA646), Color(0xFFD96F12)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffron.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _verifyAndProceed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Verify & Proceed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _handleOtpChanged(int index, String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 1) {
      _fillOtpFromInput(digitsOnly);
      return;
    }

    if (digitsOnly != value) {
      _controllers[index].text = digitsOnly;
      _controllers[index].selection =
          TextSelection.collapsed(offset: digitsOnly.length);
    }

    if (digitsOnly.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else if (index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    setState(() {});
  }

  void _fillOtpFromInput(String value) {
    final chars = value.split('');
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = i < chars.length ? chars[i] : '';
    }

    if (chars.length >= 6) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).requestFocus(_focusNodes[chars.length]);
    }

    setState(() {});
  }

  void _resendOtp() {
    for (final controller in _controllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(_focusNodes.first);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP resent successfully'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _verifyAndProceed() async {
    final otp = _controllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.isSecondFactor) {
      if (otp != '123456') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _goToDashboard();
      return;
    }

    setState(() => _isVerifying = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.completeOtpAuth(
      identifier: widget.identifier,
      userType: widget.userType,
      isRegistration: widget.isRegistration,
      registrationUser: widget.registrationUser,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isVerifying = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'OTP verification failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _goToDashboard();
  }

  void _goToDashboard() {
    switch (widget.userType) {
      case UserType.citizen:
        Navigator.pushReplacementNamed(context, '/citizen-dashboard');
        break;
      case UserType.fpsDealer:
        Navigator.pushReplacementNamed(context, '/fps-dashboard');
        break;
      case UserType.admin:
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
        break;
    }
  }

  Future<void> _handleBack() async {
    if (!widget.isSecondFactor) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}
