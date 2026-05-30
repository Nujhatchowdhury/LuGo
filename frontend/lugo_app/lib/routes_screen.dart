import 'package:flutter/material.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF16324F),
        title: const Text('Active Routes'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _RouteCard(
                routeNo: 'Route 1',
                title: 'Tilagor',
                buses: 'Up to 4 buses',
                schedule:
                    'Start from Tilagor: 8:00, 9:00, 10:00, 11:00, 12:20\n'
                    'Return from Leading University: 11:20, 12:25, 1:30, 3:05, 4:10',
                stops:
                    'Tilagor, Baluchar, Amanullah, TB Gate, Raynogor, Eidgah, Electric Supply, Cristal Rose, Amberkhana, Dorshondewry, Jalalabad, Subidbazar, Londony Road, Pathantula, Modina Market, Mount Adora Hospital, Surma Gate, Topuban, SUST Gate, Lesson Plan Madrasa, Temukhi Point, Cement Godown, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
              ),
              SizedBox(height: 14),
              _RouteCard(
                routeNo: 'Route 2',
                title: 'Surma Tower',
                buses: 'Up to 5 buses',
                schedule:
                    'Start from Surma Tower: 8:00, 9:00, 10:00, 11:00, 12:20\n'
                    'Return from Leading University: 11:20, 12:25, 1:30, 3:05, 4:10',
                stops:
                    'Surma Tower, Parkview Pt, Ptitumiar Pt, Kurarpar Point, Lamabazar, Rikabibazar, Radio Office, Subidbazar, Londony Road, Pathantula, Modina Market, Mount Adora Hospital, Surma Gate, Topuban, SUST Gate, Lesson Plan Madrasa, Temukhi Point, Cement Godown, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
              ),
              SizedBox(height: 14),
              _RouteCard(
                routeNo: 'Route 3',
                title: 'Lakkatura',
                buses: '1 bus',
                schedule:
                    'Start from Lakkatura: 8:00, 9:00, 10:00, 11:00, 12:20\n'
                    'Return from Leading University: 11:20, 12:25, 1:30, 3:05, 4:10',
                stops:
                    'Lakkatura, Chowkidekhi Pt, Amanah, Khashdobir, Lichubagan, Mazumdarir Fulkoli, Hotel Polash, Amberkhana, Dorshondewry, Jalalabad, Subidbazar, Londony Road, Pathantula, Modina Market, Mount Adora Hospital, Surma Gate, Topuban, SUST Gate, Lesson Plan Madrasa, Temukhi Point, Cement Godown, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
              ),
              SizedBox(height: 14),
              _RouteCard(
                routeNo: 'Route 4',
                title: 'Tilagor',
                buses: 'Up to 5 buses',
                schedule:
                    'Start from Tilagor: 8:00, 9:00, 10:00, 11:00, 12:20\n'
                    'Return from Leading University: 11:20, 12:25, 1:30, 3:05, 4:10',
                stops:
                    'Tilagor, Hatim Ali Majar, Shibgonj Pt, Dadapir Majar, Mirabazar, Naiorpul, Subhanighat Pt, Police Box, Rose View Pt, Humayun Rashid Chattar, Chandrulp, Bypass, Lotifpur, Rail Crossing, Lokkhibasha, Kamal Bazar, Ragib Nagar.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.routeNo,
    required this.title,
    required this.buses,
    required this.schedule,
    required this.stops,
  });

  final String routeNo;
  final String title;
  final String buses;
  final String schedule;
  final String stops;

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
          Text(
            routeNo,
            style: const TextStyle(
              color: Color(0xFF1F7A8C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            buses,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE07A24),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Schedule',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            schedule,
            style: const TextStyle(
              color: Color(0xFF5B6572),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Main stops',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stops,
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
