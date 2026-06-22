import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vet_panel/presentation/screens/vet_dashboard_screen.dart';
import '../../../vet_panel/presentation/screens/vet_appointments_screen.dart';
import '../../../vet_panel/presentation/screens/vet_schedule_screen.dart';
import '../../../vet_panel/presentation/screens/vet_profile_screen.dart';

class VetMainScreen extends StatefulWidget {
  const VetMainScreen({super.key});

  @override
  State<VetMainScreen> createState() => _VetMainScreenState();
}

class _VetMainScreenState extends State<VetMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    VetDashboardScreen(),
    VetAppointmentsScreen(),
    VetScheduleScreen(),
    VetProfileScreen(),
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
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule, color: AppTheme.primaryColor),
              label: 'Programım',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
