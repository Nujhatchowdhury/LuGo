import 'package:flutter/material.dart';

import 'service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  static final RegExp _campusEmailPattern = RegExp(
    r'^(?:[a-z]+_018\d{13}|[a-z][a-z0-9._%+-]*)@lus\.ac\.bd$',
  );
  static final RegExp _studentEmailPattern = RegExp(r'^[a-z]+_018\d{13}@lus\.ac\.bd$');
  static final RegExp _driverEmailPattern = RegExp(
    r'^[a-z][a-z0-9._%+-]*@lus\.ac\.bd$',
  );
  static final RegExp _studentIdPattern = RegExp(r'^018\d{13}$');
  static final RegExp _driverIdPattern = RegExp(r'^4\d{4}$');
  static final RegExp _phonePattern = RegExp(r'^\+880\d{10}$');

  final name = TextEditingController();
  final email = TextEditingController();
  final studentId = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  late final AnimationController _animationController;
  bool loading = false;
  String selectedRole = 'student';
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  Future<void> register() async {
    final validationMessage = _validateForm();
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    setState(() => loading = true);

    try {
      final res = await ApiService.registerUser({
        'name': name.text.trim(),
        'email': email.text.trim(),
        'student_id': studentId.text.trim(),
        'phone': phone.text.trim(),
        'password': password.text,
        'role': selectedRole,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Request completed')),
      );

      if (res['success'] != false &&
          res['message'].toString().toLowerCase().contains('success')) {
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {
            'email': email.text.trim(),
            'otp': res['otp']?.toString(),
            'emailDelivered': res['emailDelivered'] == true,
          },
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String? _validateForm() {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        studentId.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        password.text.isEmpty) {
      return 'Please complete all fields before continuing.';
    }

    final normalizedEmail = email.text.trim().toLowerCase();
    final normalizedId = studentId.text.trim();

    if (!_campusEmailPattern.hasMatch(normalizedEmail)) {
      return 'Use a student email like dept_018xxxxxxxxxxxxx@lus.ac.bd or a driver email like name@lus.ac.bd.';
    }

    if (selectedRole == 'driver') {
      if (!_driverEmailPattern.hasMatch(normalizedEmail)) {
        return 'Driver email must look like name@lus.ac.bd.';
      }
      if (!_driverIdPattern.hasMatch(normalizedId)) {
        return 'Driver ID must be 5 digits and start with 4.';
      }
    } else {
      if (!_studentEmailPattern.hasMatch(normalizedEmail)) {
        return 'Student email must look like dept_018xxxxxxxxxxxxx@lus.ac.bd.';
      }
      if (!_studentIdPattern.hasMatch(normalizedId)) {
        return 'Student ID must start with 018 and be exactly 16 digits.';
      }
    }

    if (!_phonePattern.hasMatch(phone.text.trim())) {
      return 'Phone number must be in +880XXXXXXXXXX format.';
    }

    if (password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    name.dispose();
    email.dispose();
    studentId.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedBusBanner(controller: _animationController),
              const SizedBox(height: 20),
              const Text(
                'Join LuGo',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectedRole == 'driver'
                    ? 'Register as a driver and keep your route moving.'
                    : 'Register as a student and track your ride.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF536471),
                ),
              ),
              const SizedBox(height: 20),
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
                    const Text(
                      'Choose your role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16324F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            label: 'Student',
                            icon: Icons.school_rounded,
                            accent: const Color(0xFF1F7A8C),
                            active: selectedRole == 'student',
                            onTap: () {
                              setState(() => selectedRole = 'student');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            label: 'Driver',
                            icon: Icons.badge_rounded,
                            accent: const Color(0xFFE07A24),
                            active: selectedRole == 'driver',
                            onTap: () {
                              setState(() => selectedRole = 'driver');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: name,
                      decoration: _inputDecoration('Full Name', Icons.person),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        selectedRole == 'driver'
                            ? 'Email (rasel@lus.ac.bd)'
                            : 'Email (law_0182320012101136@lus.ac.bd)',
                        Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: studentId,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        selectedRole == 'driver'
                            ? 'Driver ID (41234)'
                            : 'Student ID (0182320012101136)',
                        selectedRole == 'driver'
                            ? Icons.credit_card
                            : Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        'Phone Number (+880XXXXXXXXXX)',
                        Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16324F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          loading
                              ? 'Preparing your ride...'
                              : 'Continue as ${selectedRole == 'driver' ? 'Driver' : 'Student'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Color(0xFF5B6572)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Login'),
                        ),
                      ],
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
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.14) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? accent : const Color(0xFFD9E2EC),
              width: active ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: accent, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? accent : const Color(0xFF334E68),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBusBanner extends StatelessWidget {
  const _AnimatedBusBanner({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF16324F), Color(0xFF1F7A8C), Color(0xFF8ECae6)],
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
              final cloudOffset = 24 * (0.5 - controller.value).abs();

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 26 + cloudOffset,
                    left: 26,
                    child: _cloud(width: 74),
                  ),
                  Positioned(
                    top: 48,
                    right: 34,
                    child: _cloud(width: 52),
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
                    left: 0,
                    right: 0,
                    bottom: 42,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        8,
                        (_) => Container(
                          width: 22,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8D35E),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 28,
                    left: 24,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your ride path',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE0FBFC),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Student or driver, the bus is ready.',
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
                  ),
                  Positioned(
                    bottom: 42,
                    left: busX,
                    child: Transform.rotate(
                      angle: 0.01,
                      child: const _BusIllustration(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _cloud({required double width}) {
    return Container(
      width: width,
      height: width * 0.42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _BusIllustration extends StatelessWidget {
  const _BusIllustration();

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
          Positioned(
            left: 10,
            top: 30,
            child: Container(
              width: 18,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 30,
            child: Container(
              width: 18,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 0,
            child: _wheel(),
          ),
          Positioned(
            right: 18,
            bottom: 0,
            child: _wheel(),
          ),
        ],
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
