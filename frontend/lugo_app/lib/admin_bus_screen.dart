import 'package:flutter/material.dart';

import 'service.dart';

class AdminBusScreen extends StatefulWidget {
  const AdminBusScreen({super.key});

  @override
  State<AdminBusScreen> createState() => _AdminBusScreenState();
}

class _AdminBusScreenState extends State<AdminBusScreen> {
  late String rideDate;
  bool loading = true;
  bool publishing = false;
  List<Map<String, dynamic>> availability = [];
  String? loadMessage;

  @override
  void initState() {
    super.initState();
    rideDate = _formatDate(DateTime.now().add(const Duration(days: 1)));
    _loadAvailability();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickRideDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(rideDate) ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (selected == null) {
      return;
    }
    setState(() => rideDate = _formatDate(selected));
    await _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      loading = true;
      loadMessage = null;
    });
    try {
      final response = await ApiService.loadBusAvailability(rideDate);
      if (!mounted) {
        return;
      }

      final items = response['items'];
      setState(() {
        availability = response['success'] == true && items is List
            ? items
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        loadMessage = response['success'] == true
            ? null
            : response['message']?.toString() ?? 'Could not load RSVPs.';
        loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        availability = [];
        loadMessage = 'Could not reach admin backend. Please try again.';
        loading = false;
      });
    }
  }

  Future<void> _publish() async {
    setState(() => publishing = true);
    try {
      final response = await ApiService.publishBusAvailability(rideDate);
      if (!mounted) {
        return;
      }
      setState(() => publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ?? 'Request finished.'),
        ),
      );
      if (response['success'] == true) {
        await _loadAvailability();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach admin backend. Please try again.'),
        ),
      );
    }
  }

  int get totalRsvps => availability.fold<int>(
    0,
    (sum, item) => sum + (int.tryParse(item['rsvpCount'].toString()) ?? 0),
  );

  int get largeBuses => availability.fold<int>(
    0,
    (sum, item) => sum + (int.tryParse(item['largeBuses'].toString()) ?? 0),
  );

  int get smallBuses => availability.fold<int>(
    0,
    (sum, item) => sum + (int.tryParse(item['smallBuses'].toString()) ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'Admin logout',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/adminLogin');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAvailability,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
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
                      'RSVP count and bus allocation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rideDate,
                      style: const TextStyle(
                        color: Color(0xFFE0FBFC),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickRideDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Change Date'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE0FBFC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _Metric(label: 'RSVPs', value: '$totalRsvps'),
                        const SizedBox(width: 10),
                        _Metric(label: 'Large', value: '$largeBuses'),
                        const SizedBox(width: 10),
                        _Metric(label: 'Small', value: '$smallBuses'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: publishing || availability.isEmpty
                      ? null
                      : _publish,
                  icon: const Icon(Icons.campaign_rounded),
                  label: Text(
                    publishing ? 'Sending...' : 'Send Assignment to Drivers',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE07A24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (loadMessage != null)
                _AdminMessageCard(
                  message: loadMessage!,
                  onRetry: _loadAvailability,
                )
              else if (availability.isEmpty)
                const Text(
                  'No student RSVPs yet for tomorrow.',
                  style: TextStyle(color: Color(0xFF5B6572)),
                )
              else
                for (final item in availability) _AdminAvailabilityTile(item),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMessageCard extends StatelessWidget {
  const _AdminMessageCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8C4B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF5B6572),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE0FBFC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAvailabilityTile extends StatelessWidget {
  const _AdminAvailabilityTile(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final rsvps = item['rsvps'] is List
        ? (item['rsvps'] as List)
              .map((email) => email.toString())
              .where((email) => email.isNotEmpty)
              .toList()
        : <String>[];

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
            '${item['route']}  |  ${item['rideTime']}',
            style: const TextStyle(
              color: Color(0xFF16324F),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['pickupLocation'].toString(),
            style: const TextStyle(color: Color(0xFF5B6572)),
          ),
          const SizedBox(height: 10),
          Text(
            '${item['rsvpCount']} students -> ${item['largeBuses']} large bus(es), ${item['smallBuses']} small bus(es)',
            style: const TextStyle(
              color: Color(0xFFE07A24),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item['totalSeats']} seats assigned',
            style: const TextStyle(color: Color(0xFF5B6572)),
          ),
          if (rsvps.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'RSVPs',
              style: TextStyle(
                color: Color(0xFF16324F),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final email in rsvps)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F0E8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFD6E1E8)),
                    ),
                    child: Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF5B6572),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
