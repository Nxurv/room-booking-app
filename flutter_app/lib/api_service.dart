import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Change this if your backend runs elsewhere.
/// - Android emulator -> use 10.0.2.2 instead of localhost
/// - Real phone on same WiFi -> use your computer's LAN IP, e.g. 192.168.1.20
const String baseUrl = 'http://10.0.2.2:3000';

class ApiService {
  static Future<void> saveSession(String token, String role, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('name', name);
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('token'),
      'role': prefs.getString('role'),
      'name': prefs.getString('name'),
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(null),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 201) throw Exception(body['error'] ?? 'Registration failed');
    return body;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Login failed');
    return body; // { token, role, name }
  }

  static Future<List<dynamic>> getRooms(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/rooms'), headers: _headers(token));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Failed to load rooms');
    return body;
  }

  static Future<void> addRoom(String token, String name, double price) async {
    final res = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'price': price}),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Failed to add room');
    }
  }

  static Future<void> editRoom(String token, int id, String name, double price, String status) async {
    final res = await http.put(
      Uri.parse('$baseUrl/rooms/$id'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'price': price, 'status': status}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Failed to update room');
    }
  }

  static Future<void> bookRoom(String token, int roomId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _headers(token),
      body: jsonEncode({'room_id': roomId}),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Booking failed');
    }
  }
}
