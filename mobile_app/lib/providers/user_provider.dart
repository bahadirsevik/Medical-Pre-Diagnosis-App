import 'package:flutter/foundation.dart';
import 'package:mobile_app/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  Future<void> checkAuthStatus() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _isAuthenticated = true;
        _user = await _authService.getUser();
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      print("Auth Check Error: $e");
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final error = await _authService.login(email, password);
    if (error == null) {
      _isAuthenticated = true;
      _user = await _authService.getUser();
    }
    _isLoading = false;
    notifyListeners();
    return error;
  }

  Future<String?> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final error = await _authService.register(email, password);
    _isLoading = false;
    notifyListeners();
    return error;
  }
  
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.updateProfile(data);
    if (success) {
      _user = await _authService.getUser(); // Refresh user data
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
