import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/api_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  User? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;

  UserProvider() {
    _init();
  }

  void _init() {
    // Check initial session immediately
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _isAuthenticated = true;
      _user = session.user;
    } else {
      _isAuthenticated = false;
      _user = null;
    }
    _isLoading = false;
    notifyListeners();

    // Listen for future changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      
      if (session != null) {
        _isAuthenticated = true;
        _user = session.user;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // checkAuthStatus is no longer needed as the listener handles it
  Future<void> checkAuthStatus() async {
    // Kept for compatibility if called from main, but does nothing now
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _authService.login(email, password);
      
      // Force update state
      if (response.session != null) {
        _isAuthenticated = true;
        _user = response.session!.user;
      } else {
        // Should usually throw if failed, but just in case
        _isAuthenticated = false;
        _user = null;
      }
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      print("Login Error: $e");
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> socialLogin(OAuthProvider provider) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithProvider(provider);
      // The auth state listener will handle the rest when the app re-opens via deep link
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _authService.register(email, password);
      
      if (response.session != null) {
        _isAuthenticated = true;
        _user = response.session!.user;
      }
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      print("Register Error: $e");
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    // Use ApiService to update backend DB
    final success = await _apiService.updateProfile(data);
    
    // We could also update Supabase metadata if we wanted to keep them in sync, 
    // but for now Backend DB is the source of truth for ML.
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    return await _apiService.getUserProfile();
  }
  
  // Profile updates are now handled via Supabase directly or backend
  // For now, we can skip updateProfile or implement it using Supabase
  
  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
