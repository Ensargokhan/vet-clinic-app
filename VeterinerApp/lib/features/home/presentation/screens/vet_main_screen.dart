import 'package:flutter/material.dart';
import '../../../vet_panel/presentation/screens/vet_dashboard_screen.dart';
import '../../../vet_panel/presentation/screens/vet_appointments_screen.dart';
import '../../../vet_panel/presentation/screens/vet_schedule_screen.dart';
import '../../../vet_panel/presentation/screens/vet_profile_screen.dart';
import '../../../messaging/presentation/screens/messages_list_screen.dart';
import '../../../../shared/widgets/messages_nav_icon.dart';

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
    MessagesListScreen(),
    VetProfileScreen(),
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
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Programım',
          ),
          NavigationDestination(
            icon: MessagesNavIcon(),
            label: 'Mesajlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
