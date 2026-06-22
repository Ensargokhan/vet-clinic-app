import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              label: 'Randevular',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group, color: AppTheme.primaryColor),
              label: 'Hekimler',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
              label: 'Klinik',
            ),
          ],
        ),
      ),
    );
  }
}
