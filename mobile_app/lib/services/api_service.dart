import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Cloudflare Tunnel URL - Works on ALL devices (iOS, Android, Mac, Windows)
  static String get baseUrl {
    return 'https://restoration-entrepreneurs-sky-monster.trycloudflare.com';
  } 

  Future<Map<String, dynamic>> diagnose(String text) async {
    final url = Uri.parse('$baseUrl/diagnosis');
    
    // Get token from Supabase directly (handles refresh automatically)
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw Exception('UNAUTHORIZED');
    }

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
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

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

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/users/me');
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) return false;

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("API Profile Update Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final url = Uri.parse('$baseUrl/users/me');
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print("API Get Profile Error: $e");
      return null;
    }
  }
}
