import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

class CustomerRoomListScreen extends StatefulWidget {
  const CustomerRoomListScreen({super.key});
  @override
  State<CustomerRoomListScreen> createState() => _CustomerRoomListScreenState();
}

class _CustomerRoomListScreenState extends State<CustomerRoomListScreen> {
  List<dynamic> rooms = [];
  bool loading = true;
  String? error;
  String? token;
  int? bookingInProgressId;

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

  Future<void> _book(int roomId) async {
    setState(() => bookingInProgressId = roomId);
    try {
      await ApiService.bookRoom(token!, roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!'), backgroundColor: Colors.green),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      _load(); // refresh so the badge reflects reality if someone else booked it first
    } finally {
      if (mounted) setState(() => bookingInProgressId = null);
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
        title: const Text('Available Rooms'),
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
                      final isBooking = bookingInProgressId == room['id'];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(room['name']),
                          subtitle: Text('Price: \$${room['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(room['status']),
                                backgroundColor:
                                    isAvailable ? Colors.green[100] : Colors.red[100],
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: (isAvailable && !isBooking)
                                    ? () => _book(room['id'])
                                    : null,
                                child: isBooking
                                    ? const SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Book'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
