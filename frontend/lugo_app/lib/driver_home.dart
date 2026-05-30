import 'package:flutter/material.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0, 1), child: child),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF16324F),
                        Color(0xFF335C67),
                        Color(0xFFE09F3E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 24,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver mode',
                        style: TextStyle(
                          color: Color(0xFFF7F7FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Monitor route movement, bus timing, and service coverage from one mobile dashboard.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _DriverCard(
                  icon: Icons.route_rounded,
                  title: 'Assigned Route Overview',
                  description:
                      'Stay aware of current route coverage and the number of active buses on each route.',
                ),
                const SizedBox(height: 14),
                const _DriverCard(
                  icon: Icons.schedule_rounded,
                  title: 'Arrival Awareness',
                  description:
                      'Keep timing aligned and understand expected arrival windows at upcoming stops.',
                ),
                const SizedBox(height: 14),
                const _DriverCard(
                  icon: Icons.pin_drop_rounded,
                  title: 'Live Location Support',
                  description:
                      'Use location-aware information to keep the service visible for students in the app.',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16324F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Logout',
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
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE07A24).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFE07A24), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16324F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF5B6572),
                    height: 1.4,
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
