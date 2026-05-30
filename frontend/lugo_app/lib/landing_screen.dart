import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

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
            final wave = Curves.easeInOut.transform(
              (_animationController.value * 2) % 1,
            );
            final rise = (wave - 0.5) * 18;
            final pulse = 1 + (wave * 0.035);
            final cloudDrift = (wave - 0.5) * 22;

            return Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -40,
                  child: _orb(
                    size: 180,
                    color: const Color(0xFF8ECAE6).withValues(alpha: 0.38),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: 80,
                  child: _orb(
                    size: 120,
                    color: const Color(0xFFE9C46A).withValues(alpha: 0.24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Transform.translate(
                        offset: Offset(0, rise),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16324F),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 24,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'LU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Transform.translate(
                        offset: Offset(0, rise * 0.6),
                        child: const Text(
                          'LUGo',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16324F),
                            height: 0.95,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Precision. Efficiency. Mobility.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F7A8C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        height: 164,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF16324F),
                              Color(0xFF1F7A8C),
                              Color(0xFF8ECAE6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final busX =
                                (constraints.maxWidth + 120) *
                                        _animationController.value -
                                    120;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: 18 + cloudDrift,
                                  left: 28,
                                  child: _cloud(width: 58),
                                ),
                                Positioned(
                                  top: 42,
                                  right: 34 - cloudDrift,
                                  child: _cloud(width: 42),
                                ),
                                Positioned(
                                  bottom: 28,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F2437),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 32,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      7,
                                      (_) => Container(
                                        width: 18,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8D35E),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 42,
                                  left: busX,
                                  child: Transform.translate(
                                    offset: Offset(0, rise * 0.7),
                                    child: const _BusHero(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      Transform.scale(
                        scale: pulse,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16324F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
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

  Widget _orb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _cloud({required double width}) {
    return Container(
      width: width,
      height: width * 0.42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

class _BusHero extends StatelessWidget {
  const _BusHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 10,
            right: 10,
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A259),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 28,
            child: _window(),
          ),
          Positioned(
            top: 12,
            left: 66,
            child: _window(),
          ),
          Positioned(
            top: 12,
            left: 104,
            child: _window(),
          ),
          Positioned(
            top: 12,
            left: 142,
            child: _window(),
          ),
          Positioned(
            top: 40,
            left: 26,
            child: Container(
              width: 18,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 26,
            child: Container(
              width: 18,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 34,
            child: _wheel(),
          ),
          Positioned(
            bottom: 0,
            right: 34,
            child: _wheel(),
          ),
        ],
      ),
    );
  }

  Widget _window() {
    return Container(
      width: 20,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFD8EEF8),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  Widget _wheel() {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFF243B5A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F3E7),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
