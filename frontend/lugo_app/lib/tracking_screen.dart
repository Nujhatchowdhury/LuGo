import 'dart:async';

import 'package:flutter/material.dart';

import 'service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _timer;
  Timer? _gpsTimer;
  double _progress = 0.18;
  bool _loadingGps = true;
  Map<String, dynamic>? _liveLocation;
  String? _gpsMessage;

  static const List<String> _stops = [
    'Tilagor',
    'Amberkhana',
    'Subidbazar',
    'Modina Market',
    'Surma Gate',
    'Leading University',
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveLocation();
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadLiveLocation();
    });
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      setState(() {
        _progress += 0.035;
        if (_progress > 0.96) {
          _progress = 0.18;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLiveLocation() async {
    final response = await ApiService.loadBusLocation();
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingGps = false;
      _liveLocation = response['item'] is Map
          ? Map<String, dynamic>.from(response['item'] as Map)
          : null;
      _gpsMessage = response['message']?.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nextStopIndex = ((_progress * (_stops.length - 1)).ceil()).clamp(
      1,
      _stops.length - 1,
    );
    final etaMinutes = ((1 - _progress) * 32).ceil().clamp(2, 32);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Live Bus Tracking'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF16324F),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route 1 bus is moving',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Next stop: ${_stops[nextStopIndex]}',
                      style: const TextStyle(
                        color: Color(0xFFE0FBFC),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TrackingMap(progress: _progress, stops: _stops),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.timer_rounded,
                      title: '$etaMinutes min',
                      label: 'Estimated arrival',
                      color: const Color(0xFFE07A24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _StatusCard(
                      icon: Icons.directions_bus_filled_rounded,
                      title: 'Bus 01',
                      label: 'Active vehicle',
                      color: Color(0xFF1F7A8C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _LiveGpsCard(
                loading: _loadingGps,
                location: _liveLocation,
                message: _gpsMessage,
                onRefresh: _loadLiveLocation,
              ),
              const SizedBox(height: 16),
              Container(
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
                      'Route stops',
                      style: TextStyle(
                        color: Color(0xFF16324F),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _stops.length; i++)
                      _StopRow(
                        stop: _stops[i],
                        isPassed: i < nextStopIndex,
                        isNext: i == nextStopIndex,
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

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.progress, required this.stops});

  final double progress;
  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final busLeft = (width - 64) * progress;
          final busTop = height * (0.46 + 0.12 * (progress - 0.5));

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RouteMapPainter(progress: progress),
                ),
              ),
              Positioned(left: busLeft, top: busTop, child: const _MiniBus()),
            ],
          );
        },
      ),
    );
  }
}

class _LiveGpsCard extends StatelessWidget {
  const _LiveGpsCard({
    required this.loading,
    required this.location,
    required this.message,
    required this.onRefresh,
  });

  final bool loading;
  final Map<String, dynamic>? location;
  final String? message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final latitude = double.tryParse(location?['latitude'].toString() ?? '');
    final longitude = double.tryParse(location?['longitude'].toString() ?? '');
    final accuracy = double.tryParse(location?['accuracy'].toString() ?? '');
    final updatedAt = location?['updatedAt']?.toString() ?? '';
    final routeName = location?['routeName']?.toString() ?? 'Route 1 - Tilagor';

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Live GPS',
                  style: TextStyle(
                    color: Color(0xFF16324F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh GPS',
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF1F7A8C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const LinearProgressIndicator()
          else if (latitude == null || longitude == null)
            Text(
              message ?? 'No live bus GPS has been shared yet.',
              style: const TextStyle(
                color: Color(0xFF5B6572),
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Text(
              routeName,
              style: const TextStyle(
                color: Color(0xFFE07A24),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Latitude: ${latitude.toStringAsFixed(6)}',
              style: const TextStyle(color: Color(0xFF5B6572)),
            ),
            Text(
              'Longitude: ${longitude.toStringAsFixed(6)}',
              style: const TextStyle(color: Color(0xFF5B6572)),
            ),
            if (accuracy != null)
              Text(
                'Accuracy: ${accuracy.toStringAsFixed(1)} m',
                style: const TextStyle(color: Color(0xFF5B6572)),
              ),
            if (updatedAt.isNotEmpty)
              Text(
                'Updated: $updatedAt',
                style: const TextStyle(color: Color(0xFF5B6572)),
              ),
          ],
        ],
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF335C67)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = const Color(0xFFE09F3E)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final stopPaint = Paint()..color = Colors.white;
    final activeStopPaint = Paint()..color = const Color(0xFFE09F3E);

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.45,
        size.height * 0.82,
        size.width * 0.62,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.25,
        size.width * 0.86,
        size.height * 0.38,
        size.width * 0.94,
        size.height * 0.22,
      );

    canvas.drawPath(path, roadPaint);

    final metric = path.computeMetrics().first;
    final activePath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(activePath, activePaint);

    const stopFractions = [0.08, 0.25, 0.45, 0.62, 0.78, 0.94];
    for (final fraction in stopFractions) {
      final tangent = metric.getTangentForOffset(metric.length * fraction);
      if (tangent == null) {
        continue;
      }
      canvas.drawCircle(tangent.position, 8, stopPaint);
      canvas.drawCircle(
        tangent.position,
        4.5,
        fraction <= progress ? activeStopPaint : roadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MiniBus extends StatelessWidget {
  const _MiniBus();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB35C),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(left: 9, top: 9, child: _Window()),
          Positioned(left: 30, top: 9, child: _Window()),
          Positioned(left: 50, top: 9, child: _Window(width: 9)),
          const Positioned(left: 9, bottom: 4, child: _Wheel()),
          const Positioned(right: 9, bottom: 4, child: _Wheel()),
        ],
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({this.width = 15});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFE0FBFC),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: const Color(0xFF16324F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF16324F),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5B6572),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isPassed,
    required this.isNext,
  });

  final String stop;
  final bool isPassed;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final color = isNext
        ? const Color(0xFFE07A24)
        : isPassed
        ? const Color(0xFF1F7A8C)
        : const Color(0xFFB7C3CE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stop,
              style: TextStyle(
                color: isNext
                    ? const Color(0xFF16324F)
                    : const Color(0xFF5B6572),
                fontWeight: isNext ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          if (isNext)
            const Text(
              'Next',
              style: TextStyle(
                color: Color(0xFFE07A24),
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}
