import 'package:flutter/material.dart';

import 'service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  static final RegExp _campusEmailPattern = RegExp(
    r'^(?:[a-z]+_018\d{13}|[a-z][a-z0-9._%+-]*)@lus\.ac\.bd$',
  );

  final email = TextEditingController();
  late final AnimationController _animationController;
  bool requesting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final normalizedEmail = email.text.trim().toLowerCase();
    if (!_campusEmailPattern.hasMatch(normalizedEmail)) {
      _showMessage(
        'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.',
      );
      return;
    }

    setState(() => requesting = true);
    try {
      final res = await ApiService.requestPasswordReset(normalizedEmail);
      if (!mounted) {
        return;
      }

      _showMessage(res['message']?.toString() ?? 'Request completed.');
      if (res['success'] == true) {
        Navigator.pushNamed(
          context,
          '/verifyResetOtp',
          arguments: {
            'email': normalizedEmail,
            'otp': res['otp']?.toString(),
            'emailDelivered': res['emailDelivered'] == true,
            'sentTo': res['sentTo']?.toString(),
          },
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Could not send reset OTP: $error');
      }
    } finally {
      if (mounted) {
        setState(() => requesting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedResetBanner(controller: _animationController),
              const SizedBox(height: 22),
              const Text(
                'Reset your password',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your LuGo email first. If email delivery is unavailable, LuGo will show a secure reset OTP in the app.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF536471),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        'Email (law_0182320012101136@lus.ac.bd / rasel@lus.ac.bd)',
                        Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: requesting ? null : _requestOtp,
                        style: _buttonStyle(),
                        child: Text(
                          requesting ? 'Preparing OTP...' : 'Get reset OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back to login'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyResetOtpScreen extends StatefulWidget {
  const VerifyResetOtpScreen({super.key});

  @override
  State<VerifyResetOtpScreen> createState() => _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends State<VerifyResetOtpScreen> {
  final otp = TextEditingController();
  bool verifying = false;
  bool initialized = false;
  String email = '';
  String? sentTo;
  String? devOtp;
  bool emailDelivered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) {
      return;
    }
    initialized = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    email = args['email']?.toString() ?? '';
    sentTo = args['sentTo']?.toString();
    devOtp = args['otp']?.toString();
    emailDelivered = args['emailDelivered'] == true;
    if (devOtp != null && devOtp!.isNotEmpty) {
      otp.text = devOtp!;
    }
  }

  @override
  void dispose() {
    otp.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (otp.text.trim().length != 6) {
      _showMessage('Enter the 6-digit OTP.');
      return;
    }

    setState(() => verifying = true);
    try {
      final res = await ApiService.verifyResetOtp(
        email: email,
        otp: otp.text.trim(),
      );
      if (!mounted) {
        return;
      }

      _showMessage(res['message']?.toString() ?? 'OTP checked.');
      if (res['success'] == true) {
        Navigator.pushNamed(
          context,
          '/resetPassword',
          arguments: {
            'email': email,
            'otp': otp.text.trim(),
          },
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('OTP verification failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => verifying = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Verify reset OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emailDelivered
                    ? 'We sent the reset OTP to ${sentTo ?? 'your registered email'}.'
                    : 'Email delivery is unavailable right now. Use the reset OTP below to continue.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF536471),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!emailDelivered && devOtp != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4D6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF4C95D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reset OTP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF925C00),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Use this code to verify your password reset.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                color: Color(0xFF925C00),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              devOtp!,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16324F),
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: otp,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        'OTP',
                        Icons.verified_user_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: verifying ? null : _verifyOtp,
                        style: _buttonStyle(),
                        child: Text(
                          verifying ? 'Checking OTP...' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  bool resetting = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;
  bool initialized = false;
  String email = '';
  String otp = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) {
      return;
    }
    initialized = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    email = args['email']?.toString() ?? '';
    otp = args['otp']?.toString() ?? '';
  }

  @override
  void dispose() {
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (newPassword.text.length < 6) {
      _showMessage('New password must be at least 6 characters.');
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => resetting = true);
    try {
      final res = await ApiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword.text,
      );
      if (!mounted) {
        return;
      }

      _showMessage(res['message']?.toString() ?? 'Password reset completed.');
      if (res['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Password reset failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => resetting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Set new password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your new password below.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF536471),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: newPassword,
                      obscureText: obscureNewPassword,
                      decoration: _inputDecoration(
                        'New Password',
                        Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF5B6572),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassword,
                      obscureText: obscureConfirmPassword,
                      decoration: _inputDecoration(
                        'Confirm Password',
                        Icons.lock_reset_rounded,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF5B6572),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: resetting ? null : _resetPassword,
                        style: _buttonStyle(),
                        child: Text(
                          resetting ? 'Updating password...' : 'Reset password',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

InputDecoration _inputDecoration(
  String label,
  IconData icon, {
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF1F7A8C)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE4EAF0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF1F7A8C), width: 1.5),
    ),
  );
}

ButtonStyle _buttonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF16324F),
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _AnimatedResetBanner extends StatelessWidget {
  const _AnimatedResetBanner({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF16324F), Color(0xFF1F7A8C), Color(0xFF8ECAE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final busX = (constraints.maxWidth + 90) * controller.value - 90;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 24,
                    left: 24,
                    right: 24,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE0FBFC),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Let the bus bring your account back.',
                          style: TextStyle(
                            fontSize: 25,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 30,
                    child: Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F2437),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 42,
                    left: busX,
                    child: const _ResetBusIllustration(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ResetBusIllustration extends StatelessWidget {
  const _ResetBusIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A261),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (_) => Container(
                  width: 22,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFE8F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 10, top: 30, child: _light()),
          Positioned(right: 10, top: 30, child: _light()),
          Positioned(left: 18, bottom: 0, child: _wheel()),
          Positioned(right: 18, bottom: 0, child: _wheel()),
        ],
      ),
    );
  }

  Widget _light() {
    return Container(
      width: 18,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD166),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _wheel() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF1D3557),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFE0E1DD),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
