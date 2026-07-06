import 'package:flutter/material.dart';
import '../../../clinics/presentation/screens/clinics_screen.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../animals/presentation/screens/animals_screen.dart';
import '../../../messaging/presentation/screens/messages_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../shared/widgets/messages_nav_icon.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ClinicsScreen(),
    AppointmentsScreen(),
    AnimalsScreen(),
    MessagesListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital),
            label: 'Klinikler',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Randevular',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Hayvanlarım',
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

