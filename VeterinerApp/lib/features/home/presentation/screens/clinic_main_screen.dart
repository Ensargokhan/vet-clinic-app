import 'package:flutter/material.dart';
import '../../../clinic_panel/presentation/screens/clinic_dashboard_screen.dart';
import '../../../clinic_panel/presentation/screens/clinic_appointments_screen.dart';
import '../../../clinic_panel/presentation/screens/clinic_vets_screen.dart';
import '../../../clinic_panel/presentation/screens/clinic_profile_screen.dart';

class ClinicMainScreen extends StatefulWidget {
  const ClinicMainScreen({super.key});

  @override
  State<ClinicMainScreen> createState() => _ClinicMainScreenState();
}

class _ClinicMainScreenState extends State<ClinicMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ClinicDashboardScreen(),
    ClinicAppointmentsScreen(),
    ClinicVetsScreen(),
    ClinicProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Randevular',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Hekimler',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Klinik',
          ),
        ],
      ),
    );
  }
}
