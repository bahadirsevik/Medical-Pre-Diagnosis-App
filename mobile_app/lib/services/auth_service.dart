import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('${ApiService.baseUrl}/auth/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      await _storage.write(key: 'jwt_token', value: token);
      return null; // Success
    } else {
      return 'Giriş başarısız: ${response.body}';
    }
  }

  Future<String?> register(String email, String password) async {
    final url = Uri.parse('${ApiService.baseUrl}/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return null; // Success
    } else {
      try {
        final data = jsonDecode(response.body);
        return data['detail'] ?? 'Kayıt başarısız';
      } catch (e) {
        return 'Sunucu hatası: ${response.statusCode}';
      }
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('${ApiService.baseUrl}/users/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('${ApiService.baseUrl}/users/me');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }
}
