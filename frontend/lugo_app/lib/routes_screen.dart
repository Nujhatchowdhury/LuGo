import 'package:flutter/material.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  static const List<_RouteSchedule> _routes = [
    _RouteSchedule(
      routeNo: 'Route 1',
      title: 'Tilagor',
      maxBuses: 'Up to 4 buses',
      startFrom: 'Tilagor',
      stops:
          'Tilagor, Baluchar, Amanullah, TB Gate, Raynogor Point, Eidgah, Electric Supply, Cristal Rose, Amberkhana, Dorshondewry, Jalalabad, Subidbazar, Londony Road, Pathantula, Modina Market, Mount Adora Hospital, Surma Gate, Topuban, SUST Gate, Lesson Plan Madrasa, Temukhi Point, Cement Godown, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
      starting: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('8:00', 3),
          _TimeBus('9:00', 2),
          _TimeBus('10:00', 2),
          _TimeBus('11:00', 2),
          _TimeBus('12:20', 2),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('8:00', 2),
          _TimeBus('9:00', 1),
          _TimeBus('10:00', 1),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('8:00', 2),
          _TimeBus('9:00', 2),
          _TimeBus('10:00', 2),
          _TimeBus('11:00', 2),
        ]),
      ],
      returning: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('11:20', 1),
          _TimeBus('12:25', 2),
          _TimeBus('1:30', 2),
          _TimeBus('3:05', 1),
          _TimeBus('4:10', 4),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('11:20', 2),
          _TimeBus('3:05', 2),
          _TimeBus('4:10', 2),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('12:25', 2),
          _TimeBus('3:05', 2),
          _TimeBus('4:10', 2),
        ]),
      ],
    ),
    _RouteSchedule(
      routeNo: 'Route 2',
      title: 'Surma Tower',
      maxBuses: 'Up to 5 buses',
      startFrom: 'Surma Tower',
      stops:
          'Surma Tower, Parkview Point, Ptitumiar Point, Kurarpar Point, Lamabazar, Rikabibazar, Radio Office, Subidbazar, Londony Road, Pathantula, Modina Market, Mount Adora Hospital, Surma Gate, Topuban, SUST Gate, Lesson Plan Madrasa, Temukhi Point, Cement Godown, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
      starting: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('8:00', 5),
          _TimeBus('9:00', 2),
          _TimeBus('10:00', 2),
          _TimeBus('11:00', 2),
          _TimeBus('12:20', 2),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('8:00', 2),
          _TimeBus('9:00', 1),
          _TimeBus('10:00', 1),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('8:00', 2),
          _TimeBus('9:00', 2),
          _TimeBus('10:00', 2),
          _TimeBus('11:00', 2),
        ]),
      ],
      returning: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('11:20', 1),
          _TimeBus('12:25', 3),
          _TimeBus('1:30', 2),
          _TimeBus('3:05', 1),
          _TimeBus('4:10', 5),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('11:20', 4),
          _TimeBus('3:05', 4),
          _TimeBus('4:10', 4),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('12:25', 4),
          _TimeBus('3:05', 4),
          _TimeBus('4:10', 4),
        ]),
      ],
    ),
    _RouteSchedule(
      routeNo: 'Route 3',
      title: 'Lakkatura',
      maxBuses: '1 bus',
      startFrom: 'Lakkatura',
      stops:
          'Lakkatura, Chowkidekhi Point, Amanah, Khashdobir, Lichubagan, Mazumdarir Fulkoli, Hotel Polash, Amberkhana, Dorshondewry, Jalalabad, Subidbazar, Londony Road, Pathantula, Modina Market, Mount Adora Hospital, Surma Gate, Topuban, SUST Gate, Lesson Plan Madrasa, Temukhi Point, Cement Godown, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
      starting: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('8:00', 1),
          _TimeBus('9:00', 1),
          _TimeBus('10:00', 1),
          _TimeBus('11:00', 1),
          _TimeBus('12:20', 1),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('8:00', 1),
          _TimeBus('9:00', 1),
          _TimeBus('10:00', 1),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('8:00', 1),
          _TimeBus('9:00', 1),
          _TimeBus('10:00', 1),
          _TimeBus('11:00', 1),
        ]),
      ],
      returning: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('11:20', 1),
          _TimeBus('12:25', 1),
          _TimeBus('1:30', 1),
          _TimeBus('3:05', 1),
          _TimeBus('4:10', 1),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('11:20', 0),
          _TimeBus('3:05', 1),
          _TimeBus('4:10', 1),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('12:25', 1),
          _TimeBus('3:05', 1),
          _TimeBus('4:10', 1),
        ]),
      ],
    ),
    _RouteSchedule(
      routeNo: 'Route 4',
      title: 'Tilagor',
      maxBuses: 'Up to 5 buses',
      startFrom: 'Tilagor',
      stops:
          'Tilagor, Hatim Ali Majar, Shibgonj Point, Dadapir Majar, Mirabazar, Naiorpul, Subhanighat, Police Box, Rose View Point, Humayun Rashid Chattar, Chandrulp, Bypass, Lotifpur, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
      starting: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('8:00', 5),
          _TimeBus('9:00', 2),
          _TimeBus('10:00', 2),
          _TimeBus('11:00', 2),
          _TimeBus('12:20', 2),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('8:00', 2),
          _TimeBus('9:00', 1),
          _TimeBus('10:00', 1),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('8:00', 2),
          _TimeBus('9:00', 1),
          _TimeBus('10:00', 1),
          _TimeBus('11:00', 2),
        ]),
      ],
      returning: [
        _DaySchedule('Sunday to Thursday', [
          _TimeBus('11:20', 1),
          _TimeBus('12:25', 2),
          _TimeBus('1:30', 2),
          _TimeBus('3:05', 1),
          _TimeBus('4:10', 5),
        ]),
        _DaySchedule('Friday', [
          _TimeBus('11:20', 4),
          _TimeBus('3:05', 4),
          _TimeBus('4:10', 4),
        ]),
        _DaySchedule('Saturday', [
          _TimeBus('12:25', 4),
          _TimeBus('3:05', 4),
          _TimeBus('4:10', 4),
        ]),
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
              Text(
                route.maxBuses,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE07A24),
                ),
              ),
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
          const SizedBox(height: 4),
          Text(
            'Starting location: ${route.startFrom}',
            style: const TextStyle(
              color: Color(0xFF5B6572),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _ScheduleSection(
            title: 'Starting time and buses',
            schedules: route.starting,
          ),
          const SizedBox(height: 14),
          _ScheduleSection(
            title: 'Return from Leading University',
            schedules: route.returning,
          ),
          const SizedBox(height: 14),
          const Text(
            'Bus stoppage points',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            route.stops,
            style: const TextStyle(
              color: Color(0xFF5B6572),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.title,
    required this.schedules,
  });

  final String title;
  final List<_DaySchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF16324F),
          ),
        ),
        const SizedBox(height: 8),
        for (final schedule in schedules) ...[
          Text(
            schedule.day,
            style: const TextStyle(
              color: Color(0xFF5B6572),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in schedule.items)
                _TimeBusChip(timeBus: item),
            ],
          ),
          if (schedule != schedules.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TimeBusChip extends StatelessWidget {
  const _TimeBusChip({required this.timeBus});

  final _TimeBus timeBus;

  @override
  Widget build(BuildContext context) {
    final busText = timeBus.buses == 1 ? '1 bus' : '${timeBus.buses} buses';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6EE)),
      ),
      child: Text(
        '${timeBus.time}  |  $busText',
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
    required this.maxBuses,
    required this.startFrom,
    required this.starting,
    required this.returning,
    required this.stops,
  });

  final String routeNo;
  final String title;
  final String maxBuses;
  final String startFrom;
  final List<_DaySchedule> starting;
  final List<_DaySchedule> returning;
  final String stops;
}

class _DaySchedule {
  const _DaySchedule(this.day, this.items);

  final String day;
  final List<_TimeBus> items;
}

class _TimeBus {
  const _TimeBus(this.time, this.buses);

  final String time;
  final int buses;
}
