import 'package:flutter/material.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  static const List<_RouteSchedule> _routes = [
    _RouteSchedule(
      routeNo: 'Route 1',
      title: 'Tilagor to Baluchor',
      stops: [
        'Tilagor',
        'Baluchor',
        'Amanullah',
        'TB Gate',
        'Raynogor Point',
        'Eidgah',
        'Electric Supply',
        'Cristal Rose',
        'Amberkhana',
        'Dorshondewry',
        'Jalalabad',
        'Subidbazar',
        'Londony Road',
        'Pathantula',
        'Modina Market',
        'Mount Adora Hospital',
        'Surma Gate',
        'Topuban',
        'SUST Gate',
        'Lesson Plan Madrasa',
        'Temukhi Point',
        'Cement Godown',
        'Rail Crossing',
        'Lokkhibasha',
        'Kamal Bazar',
        'Ragib Nagar',
      ],
    ),
    _RouteSchedule(
      routeNo: 'Route 2',
      title: 'Surma Tower to Ragib Nagar',
      stops: [
        'Surma Tower',
        'Parkview Point',
        'Ptitumiar Point',
        'Kurarpar Point',
        'Lamabazar',
        'Rikabibazar',
        'Radio Office',
        'Subidbazar',
        'Londony Road',
        'Pathantula',
        'Modina Market',
        'Mount Adora Hospital',
        'Surma Gate',
        'Topuban',
        'SUST Gate',
        'Lesson Plan Madrasa',
        'Temukhi Point',
        'Cement Godown',
        'Rail Crossing',
        'Lokkhibasha',
        'Kamal Bazar',
        'Ragib Nagar',
      ],
    ),
    _RouteSchedule(
      routeNo: 'Route 3',
      title: 'Lakkatura to Ragib Nagar',
      stops: [
        'Lakkatura',
        'Chowkidekhi Point',
        'Amanah',
        'Khashdobir',
        'Lichubagan',
        'Mazumdarir Fulkoli',
        'Hotel Polash',
        'Amberkhana',
        'Dorshondewry',
        'Jalalabad',
        'Subidbazar',
        'Londony Road',
        'Pathantula',
        'Modina Market',
        'Mount Adora Hospital',
        'Surma Gate',
        'Topuban',
        'SUST Gate',
        'Lesson Plan Madrasa',
        'Temukhi Point',
        'Cement Godown',
        'Rail Crossing',
        'Lokkhibasha',
        'Kamal Bazar',
        'Ragib Nagar',
      ],
    ),
    _RouteSchedule(
      routeNo: 'Route 4',
      title: 'Tilagor to Ragib Nagar',
      stops: [
        'Tilagor',
        'Hatim Ali Majar',
        'Shibgonj Point',
        'Dadapir Majar',
        'Mirabazar',
        'Naiorpul',
        'Subhanighat',
        'Police Box',
        'Rose View Point',
        'Humayun Rashid Chattar',
        'Chandrulp',
        'Bypass',
        'Lotifpur',
        'Rail Crossing',
        'Lokkhibasha',
        'Kamal Bazar',
        'Ragib Nagar',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Bus Schedule'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          itemBuilder: (context, index) => _RouteCard(route: _routes[index]),
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemCount: _routes.length,
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final _RouteSchedule route;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F7A8C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  route.routeNo,
                  style: const TextStyle(
                    color: Color(0xFF1F7A8C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.route_rounded, color: Color(0xFFE07A24)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            route.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Locations',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final stop in route.stops) _LocationChip(label: stop),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6EE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF16324F),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RouteSchedule {
  const _RouteSchedule({
    required this.routeNo,
    required this.title,
    required this.stops,
  });

  final String routeNo;
  final String title;
  final List<String> stops;
}
