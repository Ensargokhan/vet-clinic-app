import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/clinic_register_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/home/presentation/screens/clinic_main_screen.dart';
import '../../features/home/presentation/screens/vet_main_screen.dart';
import '../../features/clinics/presentation/screens/clinic_detail_screen.dart';
import '../../features/animals/presentation/screens/animals_screen.dart';
import '../../features/animals/presentation/screens/add_animal_screen.dart';
import '../../features/animals/presentation/screens/animal_detail_screen.dart';
import '../../features/animals/presentation/screens/edit_animal_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/appointments/presentation/screens/create_appointment_screen.dart';
import '../../features/appointments/presentation/screens/appointment_detail_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/vaccines/presentation/screens/add_vaccine_screen.dart';
import '../../features/vaccines/presentation/screens/animal_vaccines_screen.dart';
import '../../features/vaccines/data/models/vaccine_model.dart';
import '../../features/messaging/presentation/screens/messages_list_screen.dart';
import '../../features/messaging/presentation/screens/chat_thread_screen.dart';
import '../../features/clinic_panel/presentation/screens/clinic_profile_edit_screen.dart';
import '../../features/clinic_panel/presentation/screens/clinic_announcements_screen.dart';
import '../../features/vet_panel/presentation/screens/vet_profile_edit_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register-clinic',
        builder: (context, state) => const ClinicRegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/clinic-home',
        builder: (context, state) => const ClinicMainScreen(),
      ),
      GoRoute(
        path: '/vet-home',
        builder: (context, state) => const VetMainScreen(),
      ),
      GoRoute(
        path: '/clinics/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ClinicDetailScreen(clinicId: id);
        },
      ),
      GoRoute(
        path: '/animals',
        builder: (context, state) => const AnimalsScreen(),
      ),
      GoRoute(
        path: '/animals/add',
        builder: (context, state) => const AddAnimalScreen(),
      ),
      GoRoute(
        path: '/animals/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AnimalDetailScreen(animalId: id);
        },
      ),
      GoRoute(
        path: '/animals/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditAnimalScreen(animalId: id);
        },
      ),
      GoRoute(
        path: '/animals/:id/vaccines',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra as Map<String, dynamic>?;
          return AnimalVaccinesScreen(
            animalId: id,
            animalName: extra?['animalName'],
          );
        },
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/appointments/create',
        builder: (context, state) {
          final vetIdStr = state.uri.queryParameters['vetId'];
          final clinicIdStr = state.uri.queryParameters['clinicId'];
          final vetId = int.tryParse(vetIdStr ?? '0') ?? 0;
          final clinicId = int.tryParse(clinicIdStr ?? '0') ?? 0;
          return CreateAppointmentScreen(vetId: vetId, clinicId: clinicId);
        },
      ),
      GoRoute(
        path: '/appointments/:id',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '0') ?? 0;
          return AppointmentDetailScreen(appointmentId: id);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesListScreen(),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatThreadScreen(conversationId: id, peerName: extra?['peerName']);
        },
      ),
      GoRoute(
        path: '/vaccines/add',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddVaccineScreen(
            animalId: extra?['animalId'] ?? 0,
            animalName: extra?['animalName'],
            vaccine: extra?['vaccine'] as VaccineModel?,
          );
        },
      ),
      GoRoute(
        path: '/clinic/profile/edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ClinicProfileEditScreen(profileData: extra);
        },
      ),
      GoRoute(
        path: '/clinic/announcements',
        builder: (context, state) => const ClinicAnnouncementsScreen(),
      ),
      GoRoute(
        path: '/vet/profile/edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VetProfileEditScreen(profileData: extra);
        },
      ),
    ],
  );
}

// Geçici bir sayfa
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - Yapım Aşamasında')),
    );
  }
}
