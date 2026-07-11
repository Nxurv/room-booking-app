import 'package:flutter/material.dart';
import 'api_service.dart';
import 'admin_room_form_screen.dart';
import 'login_screen.dart';

class AdminRoomListScreen extends StatefulWidget {
  const AdminRoomListScreen({super.key});
  @override
  State<AdminRoomListScreen> createState() => _AdminRoomListScreenState();
}

class _AdminRoomListScreenState extends State<AdminRoomListScreen> {
  List<dynamic> rooms = [];
  bool loading = true;
  String? error;
  String? token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final session = await ApiService.getSession();
      token = session['token'];
      final data = await ApiService.getRooms(token!);
      setState(() => rooms = data);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Rooms'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                : ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final isAvailable = room['status'] == 'available';
                      return ListTile(
                        title: Text(room['name']),
                        subtitle: Text('Price: \$${room['price']}'),
                        trailing: Chip(
                          label: Text(room['status']),
                          backgroundColor: isAvailable ? Colors.green[100] : Colors.red[100],
                        ),
                        onTap: () async {
                          final updated = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AdminRoomFormScreen(room: room)),
                          );
                          if (updated == true) _load();
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminRoomFormScreen(room: null)),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
