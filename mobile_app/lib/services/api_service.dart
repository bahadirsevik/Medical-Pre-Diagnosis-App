import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' as io;

class ApiService {
  // For Android Emulator, use 10.0.2.2. For physical device, use your PC's IP.
  // We will assume emulator for now or update later.
  static String get baseUrl {
    // Cloudflare Tunnel URL - Works on ALL devices (iOS, Android, Mac, Windows)
    return 'https://answering-isolated-victory-friday.trycloudflare.com';
  } 

  Future<Map<String, dynamic>> diagnose(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/diagnosis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load diagnosis: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}
