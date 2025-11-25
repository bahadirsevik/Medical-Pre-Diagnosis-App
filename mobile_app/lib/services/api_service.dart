import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Cloudflare Tunnel URL - Works on ALL devices (iOS, Android, Mac, Windows)
  static String get baseUrl {
    return 'https://restoration-entrepreneurs-sky-monster.trycloudflare.com';
  } 

  Future<Map<String, dynamic>> diagnose(String text) async {
    final url = Uri.parse('$baseUrl/diagnosis');
    
    // Get token
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        // Decode UTF-8 explicitly to handle Turkish characters correctly
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        throw Exception('UNAUTHORIZED');
      } else {
        throw Exception('Failed to load diagnosis: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('UNAUTHORIZED')) rethrow;
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<List<dynamic>> getHistory() async {
    final url = Uri.parse('$baseUrl/history');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      return []; // Return empty list on error
    }
  }
}
