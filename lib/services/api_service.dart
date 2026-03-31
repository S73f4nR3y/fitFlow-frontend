import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void _log(String message) {
  developer.log(message, name: 'ApiService');
}

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  String? _token;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isAuthenticated => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    // Check if response is successful
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Registration failed');
    }

    final data = jsonDecode(response.body);
    if (data['accessToken'] != null) {
      await setToken(data['accessToken']);
    }
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    // Check if response is successful
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Login failed');
    }

    final data = jsonDecode(response.body);
    if (data['accessToken'] != null) {
      await setToken(data['accessToken']);
      // Also save the role from the login response
      if (data['user']?['role'] != null) {
        await setUserRole(data['user']['role']);
      }
    }
    return data;
  }

  Future<void> logout() async {
    await clearToken();
  }

  // User profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    _log('getUserProfile status: ${response.statusCode}');
    if (response.statusCode >= 400) {
      _log('Error getting user profile: ${response.body}');
      return {};
    }
    return jsonDecode(response.body);
  }

  // Classes (public)
  Future<List<dynamic>> getClasses() async {
    final response = await http.get(Uri.parse('$baseUrl/classes/public'));
    return jsonDecode(response.body);
  }

  // Classes (auth required)
  Future<List<dynamic>> getMyClasses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/instructors/my-classes'),
      headers: _headers,
    );
    _log('getMyClasses status: ${response.statusCode}');
    if (response.statusCode >= 400) {
      _log('getMyClasses error: ${response.body}');
      return [];
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createClass(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateClass(
    String classId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/classes/$classId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<void> deleteClass(String classId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/classes/$classId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Error deleting class: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createSchedule({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
    String? location,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes/$classId/schedules'),
      headers: _headers,
      body: jsonEncode({
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
      }),
    );
    return jsonDecode(response.body);
  }

  // Bookings
  Future<Map<String, dynamic>> createBooking({
    required String scheduleId,
    double amount = 0,
    String? paymentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _headers,
      body: jsonEncode({
        'scheduleId': scheduleId,
        'amount': amount,
        'paymentId': paymentId,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMyBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/my-bookings'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Instructors
  Future<List<dynamic>> getInstructors() async {
    final response = await http.get(Uri.parse('$baseUrl/instructors'));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createInstructorProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/instructors'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateInstructorProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/instructors/me'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMyInstructorProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/instructors/my-profile'),
      headers: _headers,
    );
    _log('getMyInstructorProfile status: ${response.statusCode}');
    if (response.statusCode >= 400) {
      _log('getMyInstructorProfile error: ${response.body}');
      return {};
    }
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getInstructorBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/instructors/my-bookings'),
      headers: _headers,
    );
    _log('getInstructorBookings status: ${response.statusCode}');
    if (response.statusCode >= 400) {
      _log('getInstructorBookings error: ${response.body}');
      return [];
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    return [];
  }

  // Admin (only admin)
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getPendingInstructors() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/pending-instructors'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createUserAsAdmin(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> approveInstructor(String userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/approve-instructor/$userId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> suspendInstructor(String userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/suspend-instructor/$userId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createInstructorAsAdmin(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/instructors'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Instructor schedules
  Future<List<dynamic>> getInstructorSchedules({
    required String startDate,
    required String endDate,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/instructors/my-schedules?startDate=$startDate&endDate=$endDate',
      ),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      _log('Error loading schedules: ${response.body}');
      return [];
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    return [];
  }

  // Public upcoming schedules
  Future<List<dynamic>> getUpcomingClassSchedules({
    required String startDate,
    required String endDate,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/classes/public/upcoming?startDate=$startDate&endDate=$endDate',
      ),
    );
    if (response.statusCode >= 400) {
      _log('Error loading classes: ${response.body}');
      return [];
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    return [];
  }

  // User avatar upload
  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final uri = Uri.parse('$baseUrl/users/me/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }
}
