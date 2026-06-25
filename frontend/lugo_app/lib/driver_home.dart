import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'service.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final _driverEmail = TextEditingController();
  final _routeName = TextEditingController(text: 'Route 1 - Tilagor');
  bool _sharingLocation = false;

  @override
  void dispose() {
    _driverEmail.dispose();
    _routeName.dispose();
    super.dispose();
  }

  Future<Position?> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Turn on phone location/GPS first.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Location permission is needed to share bus GPS.');
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Allow location permission from phone settings.');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _shareLocation() async {
    final email = _driverEmail.text.trim().toLowerCase();
    final route = _routeName.text.trim();

    if (!ApiService.driverEmailPattern.hasMatch(email)) {
      _showMessage('Enter driver email like name@lus.ac.bd first.');
      return;
    }

    if (route.isEmpty) {
      _showMessage('Enter assigned route first.');
      return;
    }

    setState(() => _sharingLocation = true);
    final position = await _currentPosition();
    if (position == null) {
      if (mounted) {
        setState(() => _sharingLocation = false);
      }
      return;
    }

    final response = await ApiService.updateDriverLocation(
      driverEmail: email,
      routeName: route,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );

    if (!mounted) {
      return;
    }

    setState(() => _sharingLocation = false);
    _showMessage(response['message'].toString());
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
                _DriverCard(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Driver Assignments',
                  description:
                      'Check the bus assignments sent by admin for the selected RSVP date.',
                  onTap: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
                const SizedBox(height: 14),
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
                _DriverCard(
                  icon: Icons.pin_drop_rounded,
                  title: 'Live Location Support',
                  description: _sharingLocation
                      ? 'Sharing GPS with students...'
                      : 'Tap to share this phone GPS as the live bus location.',
                  onTap: _sharingLocation ? null : _shareLocation,
                ),
                const SizedBox(height: 14),
                _DriverLocationForm(
                  driverEmail: _driverEmail,
                  routeName: _routeName,
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
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
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFF16324F),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverLocationForm extends StatelessWidget {
  const _DriverLocationForm({
    required this.driverEmail,
    required this.routeName,
  });

  final TextEditingController driverEmail;
  final TextEditingController routeName;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GPS sharing details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: driverEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              'Driver email',
              Icons.email_outlined,
              'name@lus.ac.bd',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: routeName,
            decoration: _inputDecoration(
              'Assigned route',
              Icons.route_rounded,
              'Route 1 - Tilagor',
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1F7A8C)),
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
}
