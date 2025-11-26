import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _storage = const FlutterSecureStorage();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session != null) {
        await _storage.write(key: 'jwt_token', value: response.session!.accessToken);
      }
      
      return response;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw 'E-posta veya şifre hatalı.';
      }
      if (e.message.contains('Email not confirmed')) {
        throw 'Lütfen e-posta adresinize gelen onay linkine tıklayın.';
      }
      throw 'Giriş yapılamadı: ${e.message}';
    } catch (e) {
      throw 'Bir hata oluştu: $e';
    }
  }

  Future<AuthResponse> register(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.session != null) {
        await _storage.write(key: 'jwt_token', value: response.session!.accessToken);
      }
      
      return response;
    } on AuthException catch (e) {
      if (e.message.contains('User already registered')) {
        throw 'Bu e-posta adresi zaten kayıtlı.';
      }
      throw 'Kayıt olunamadı: ${e.message}';
    } catch (e) {
      throw 'Bir hata oluştu: $e';
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> signInWithProvider(OAuthProvider provider) async {
    try {
      final bool res = await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: 'medicalai://login-callback',
      );
      return res;
    } catch (e) {
      print("Social Login Error: $e");
      throw 'Giriş yapılamadı: $e';
    }
  }

  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }
  
  User? get currentUser => _supabase.auth.currentUser;

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: data),
      );
      return response.user != null;
    } catch (e) {
      print("Profile Update Error: $e");
      return false;
    }
  }
}
