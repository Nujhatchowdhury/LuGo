import 'package:flutter/material.dart';

import 'service.dart';

class BusAvailabilityScreen extends StatefulWidget {
  const BusAvailabilityScreen({super.key});

  @override
  State<BusAvailabilityScreen> createState() => _BusAvailabilityScreenState();
}

class _BusAvailabilityScreenState extends State<BusAvailabilityScreen> {
  final emailController = TextEditingController();
  final pickupController = TextEditingController();
  late String rideDate;
  String selectedRoute = 'Route 1 - Tilagor';
  String selectedTime = '8:00';
  bool saving = false;
  bool rsvpConfirmed = false;

  static const routes = [
    'Route 1 - Tilagor',
    'Route 2 - Surma Tower',
    'Route 3 - Lakkatura',
    'Route 4 - Tilagor',
  ];

  static const times = [
    '8:00',
    '9:00',
    '10:00',
    '11:00',
    '12:20',
    '11:20 return',
    '12:25 return',
    '1:30 return',
    '3:05 return',
    '4:10 return',
  ];

  @override
  void initState() {
    super.initState();
    rideDate = _formatDate(DateTime.now().add(const Duration(days: 1)));
  }

  @override
  void dispose() {
    emailController.dispose();
    pickupController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _saveRsvp() async {
    final email = emailController.text.trim().toLowerCase();
    final pickup = pickupController.text.trim();

    if (!ApiService.studentEmailPattern.hasMatch(email)) {
      _showMessage('Use student email: dept_018xxxxxxxxxxxxx@lus.ac.bd');
      return;
    }
    if (pickup.isEmpty) {
      _showMessage('Write your pickup location.');
      return;
    }

    setState(() => saving = true);
    final response = await ApiService.saveBusRsvp(
      studentEmail: email,
      routeName: selectedRoute,
      pickupLocation: pickup,
      rideTime: selectedTime,
      rideDate: rideDate,
    );
    if (!mounted) {
      return;
    }
    setState(() => saving = false);

    _showMessage(response['message'].toString());
    if (response['success'] == true) {
      setState(() => rsvpConfirmed = true);
    }
  }

  Future<void> _pickRideDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(rideDate) ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      rideDate = _formatDate(selected);
      rsvpConfirmed = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Bus RSVP'),
      ),
      body: SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _HeaderCard(
                rideDate: rideDate,
                confirmed: rsvpConfirmed,
              ),
              const SizedBox(height: 14),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reserve tomorrow bus',
                      style: TextStyle(
                        color: Color(0xFF16324F),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DateField(
                      label: 'Booking Date',
                      value: rideDate,
                      icon: Icons.calendar_month_rounded,
                      onTap: _pickRideDate,
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: emailController,
                      label: 'Student Email',
                      hint: 'dept_018xxxxxxxxxxxxx@lus.ac.bd',
                      icon: Icons.mail_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _SelectField(
                      label: 'Route',
                      value: selectedRoute,
                      items: routes,
                      icon: Icons.alt_route_rounded,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRoute = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: pickupController,
                      label: 'Pickup Location',
                      hint: 'Example: Modina Market',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    _SelectField(
                      label: 'Time',
                      value: selectedTime,
                      items: times,
                      icon: Icons.schedule_rounded,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedTime = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (rsvpConfirmed) ...[
                      const _ConfirmationBox(),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : _saveRsvp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16324F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          saving ? 'Saving...' : 'RSVP for Bus',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
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
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final emailController = TextEditingController();
  bool loading = false;
  List<Map<String, dynamic>> notifications = [];

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final email = emailController.text.trim().toLowerCase();
    if (!ApiService.campusEmailPattern.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your LuGo email first.')),
      );
      return;
    }

    setState(() => loading = true);
    final response = await ApiService.loadNotifications(email);
    if (!mounted) {
      return;
    }
    final items = response['items'];
    setState(() {
      notifications = items is List
          ? items.map((item) => Map<String, dynamic>.from(item as Map)).toList()
          : [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Driver Assignments'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _Panel(
              child: Column(
                children: [
                  _InputField(
                    controller: emailController,
                    label: 'LuGo Email',
                    hint: 'name@lus.ac.bd',
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _loadNotifications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16324F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(loading ? 'Loading...' : 'Check Assignments'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (notifications.isEmpty)
              const Text(
                'No assignments loaded yet.',
                style: TextStyle(color: Color(0xFF5B6572)),
              )
            else
              for (final item in notifications) _NotificationTile(item),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.rideDate,
    required this.confirmed,
  });

  final String rideDate;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF16324F),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seat RSVP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Date: $rideDate',
            style: const TextStyle(
              color: Color(0xFFE0FBFC),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            confirmed
                ? 'Your RSVP is confirmed for $rideDate.'
                : 'Choose your date, route, pickup point, and time.',
            style: const TextStyle(
              color: Color(0xFFE0FBFC),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bus assignment will be handled by admin and drivers.',
            style: TextStyle(color: Color(0xFFE0FBFC)),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1F7A8C)),
          filled: true,
          fillColor: const Color(0xFFF7FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDCE6EE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDCE6EE)),
          ),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF16324F),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ConfirmationBox extends StatelessWidget {
  const _ConfirmationBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F7A8C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F7A8C)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF1F7A8C)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your seat RSVP was confirmed.',
              style: TextStyle(
                color: Color(0xFF16324F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1F7A8C)),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE6EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE6EE)),
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1F7A8C)),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE6EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE6EE)),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Text(
            item['title'].toString(),
            style: const TextStyle(
              color: Color(0xFF16324F),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['message'].toString(),
            style: const TextStyle(color: Color(0xFF5B6572), height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            item['createdAt'].toString(),
            style: const TextStyle(
              color: Color(0xFFE07A24),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
