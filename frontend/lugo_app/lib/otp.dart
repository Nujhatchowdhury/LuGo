import 'package:flutter/material.dart';

import 'service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final otp = TextEditingController();
  late final AnimationController _animationController;
  String? previewOtp;
  String email = '';
  bool emailDelivered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      email = args['email']?.toString() ?? '';
      previewOtp = args['otp']?.toString();
      emailDelivered = args['emailDelivered'] == true;
    } else if (args is String) {
      email = args;
      previewOtp = null;
      emailDelivered = false;
    }

    if (previewOtp != null && otp.text.isEmpty) {
      otp.text = previewOtp!;
    }
  }

  void verify(String email) async {
    final res = await ApiService.verifyOtp(email, otp.text);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'])),
    );

    if (res['message'].toString().toLowerCase().contains('success')) {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final lift = (_animationController.value - 0.5) * 20;
            return Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -30,
                  child: _glow(
                    size: 180,
                    color: const Color(0xFF8ECAE6).withValues(alpha: 0.4),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: -60,
                  child: _glow(
                    size: 190,
                    color: const Color(0xFFE9C46A).withValues(alpha: 0.26),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF16324F),
                              Color(0xFF2A6F97),
                              Color(0xFF89C2D9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 28,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 24,
                              left: 24,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Text(
                                  emailDelivered
                                      ? 'Your code is on the way.'
                                      : 'Use the fallback code below.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 29,
                                    height: 1.06,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 114,
                              left: 24,
                              right: 120,
                              child: Text(
                                emailDelivered
                                    ? 'Check your inbox and spam folder for the 6-digit OTP.'
                                    : 'SMTP delivery is unavailable, so a temporary OTP is shown in-app.',
                                style: const TextStyle(
                                  color: Color(0xFFE0FBFC),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 22,
                              bottom: 22 + lift,
                              child: Transform.rotate(
                                angle: 0.08,
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.mark_email_read_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x16000000),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emailDelivered
                                  ? 'OTP sent to $email'
                                  : 'Temporary OTP ready for $email',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16324F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your 6-digit code below to continue.',
                              style: TextStyle(
                                color: Color(0xFF5B6572),
                                height: 1.4,
                              ),
                            ),
                            if (!emailDelivered && previewOtp != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4D6),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFFFD166),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Temporary OTP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF7A4B00),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      previewOtp!,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 6,
                                        color: Color(0xFF16324F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            TextField(
                              controller: otp,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'OTP',
                                prefixIcon: const Icon(
                                  Icons.password_rounded,
                                  color: Color(0xFF2A6F97),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF7FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD6E1E8),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2A6F97),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => verify(email),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16324F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _glow({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
