import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'admin_room_list_screen.dart';
import 'customer_room_list_screen.dart';

void main() {
  runApp(const RoomBookingApp());
}

class RoomBookingApp extends StatelessWidget {
  const RoomBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Booking',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const SplashRouter(),
    );
  }
}

/// Checks if a session already exists (saved token) and routes straight
/// to the right screen; otherwise shows the login screen.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final session = await ApiService.getSession();
    if (!mounted) return;
    if (session['token'] == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else if (session['role'] == 'admin') {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const AdminRoomListScreen()));
    } else {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const CustomerRoomListScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
