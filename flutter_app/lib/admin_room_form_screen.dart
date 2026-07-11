import 'package:flutter/material.dart';
import 'api_service.dart';

class AdminRoomFormScreen extends StatefulWidget {
  final Map<String, dynamic>? room; // null = add mode, non-null = edit mode
  const AdminRoomFormScreen({super.key, required this.room});

  @override
  State<AdminRoomFormScreen> createState() => _AdminRoomFormScreenState();
}

class _AdminRoomFormScreenState extends State<AdminRoomFormScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  String status = 'available';
  bool loading = false;
  String? error;

  bool get isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.room?['name'] ?? '');
    priceCtrl = TextEditingController(text: widget.room != null ? '${widget.room!['price']}' : '');
    status = widget.room?['status'] ?? 'available';
  }

  Future<void> _save() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final session = await ApiService.getSession();
      final token = session['token']!;
      final price = double.tryParse(priceCtrl.text) ?? 0;

      if (isEdit) {
        await ApiService.editRoom(token, widget.room!['id'], nameCtrl.text.trim(), price, status);
      } else {
        await ApiService.addRoom(token, nameCtrl.text.trim(), price);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Room' : 'Add Room')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Room name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            if (isEdit) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'available'),
              ),
            ],
            const SizedBox(height: 20),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _save,
                child: loading
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Save Changes' : 'Add Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
