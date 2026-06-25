import 'package:flutter/material.dart';

import 'service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static final RegExp _studentEmailPattern = RegExp(
    r'^[a-z]+_018\d{13}@lus\.ac\.bd$',
  );
  static final RegExp _driverEmailPattern = RegExp(
    r'^[a-z][a-z0-9._%+-]*@lus\.ac\.bd$',
  );
  static final RegExp _studentIdPattern = RegExp(r'^018\d{13}$');
  static final RegExp _driverIdPattern = RegExp(r'^4\d{4}$');

  final identifier = TextEditingController();
  final password = TextEditingController();
  late final AnimationController _animationController;
  bool loading = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  Future<void> login() async {
    final normalizedIdentifier = identifier.text.trim().toLowerCase();

    if (normalizedIdentifier.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email or ID and password first.'),
        ),
      );
      return;
    }

    final isValidIdentifier =
        _studentEmailPattern.hasMatch(normalizedIdentifier) ||
        _driverEmailPattern.hasMatch(normalizedIdentifier) ||
        _studentIdPattern.hasMatch(normalizedIdentifier) ||
        _driverIdPattern.hasMatch(normalizedIdentifier);

    if (!isValidIdentifier) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email or ID.')),
      );
      return;
    }

    setState(() => loading = true);
    final res = await ApiService.login(normalizedIdentifier, password.text);
    if (!mounted) {
      return;
    }
    setState(() => loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'].toString())));

    final role = res['role']?.toString();
    if (role == 'driver') {
      Navigator.pushReplacementNamed(context, '/driverHome');
      return;
    }
    if (res['message'].toString().toLowerCase().contains('success')) {
      Navigator.pushReplacementNamed(context, '/studentHome');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    identifier.dispose();
    password.dispose();
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
            return Stack(
              children: [
                Positioned(
                  top: -90,
                  left: -40,
                  child: _orb(
                    size: 220,
                    color: const Color(0xFF8ECAE6).withValues(alpha: 0.55),
                  ),
                ),
                Positioned(
                  top: 110,
                  right: -30,
                  child: _orb(
                    size: 170,
                    color: const Color(0xFFFFB703).withValues(alpha: 0.28),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: 20,
                  child: _orb(
                    size: 180,
                    color: const Color(0xFF1F7A8C).withValues(alpha: 0.18),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 248,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF16324F),
                              Color(0xFF1F7A8C),
                              Color(0xFF8ECAE6),
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
                              top: 22,
                              left: 24,
                              right: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LuBadge(),
                                  SizedBox(height: 14),
                                  Text(
                                    'Precision. Efficiency. Mobility.',
                                    style: TextStyle(
                                      color: Color(0xFFE0FBFC),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 230),
                                    child: Text(
                                      'Smarter campus mobility for every ride.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        height: 1.08,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 18,
                              child: SizedBox(
                                height: 68,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: 20,
                                      right: 20,
                                      bottom: 8,
                                      child: Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0F2437,
                                          ).withValues(alpha: 0.40),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 18,
                                      bottom: 8,
                                      child: Transform.rotate(
                                        angle: -0.03,
                                        child: _busCard(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x16000000),
                              blurRadius: 26,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            TextField(
                              controller: identifier,
                              keyboardType: TextInputType.text,
                              decoration: _inputDecoration(
                                'Email / ID',
                                Icons.person_outline_rounded,
                                hintText:
                                    'dept_018xxxxxxxxxxxxxx@lus.ac.bd / name@lus.ac.bd',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: password,
                              obscureText: obscurePassword,
                              decoration: _inputDecoration(
                                'Password',
                                Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF5B6572),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: loading ? null : login,
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
                                child: Text(
                                  loading ? 'Signing you in...' : 'Login',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/forgotPassword',
                                  );
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Color(0xFF5B6572)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                                  child: const Text('Sign up'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/adminLogin');
                                },
                                icon: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 18,
                                ),
                                label: const Text('Admin panel'),
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

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF1F7A8C)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD6E1E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF1F7A8C), width: 1.6),
      ),
    );
  }

  Widget _orb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  Widget _busCard() {
    return Container(
      width: 108,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF4A261),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (_) => Container(
                  width: 15,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFE8F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 30,
            child: Container(
              width: 16,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 30,
            child: Container(
              width: 16,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(left: 12, bottom: 2, child: _wheel()),
          Positioned(right: 12, bottom: 2, child: _wheel()),
        ],
      ),
    );
  }
}

class _LuBadge extends StatelessWidget {
  const _LuBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Center(
            child: Text(
              'LU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leading University',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'LUGo',
              style: TextStyle(
                color: Color(0xFFE0FBFC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
