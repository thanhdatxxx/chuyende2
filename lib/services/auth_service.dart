import 'package:flutter/material.dart';
import 'cache_service.dart';

class AuthService with ChangeNotifier {
  AuthService() {
    _loadUserFromCache();
  }

  bool _isLoggedIn = false;
  String _userName = ""; // user_name
  String _fullName = ""; // full_name
  String _userId = ""; // user_id/doc id
  double _balance = 0;
  double _depositedMoney = 0;
  bool _isAdmin = false;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get fullName => _fullName;
  String get userId => _userId;
  double get balance => _balance;
  double get depositedMoney => _depositedMoney;
  bool get isAdmin => _isAdmin;

  void _loadUserFromCache() {
    final userData = CacheService.getUser();
    if (userData != null) {
      _isLoggedIn = true;
      _userName = userData['userName'] ?? "";
      _fullName = userData['fullName'] ?? "";
      _userId = userData['userId'] ?? "";
      _balance = (userData['balance'] ?? 0).toDouble();
      _depositedMoney = (userData['depositedMoney'] ?? 0).toDouble();
      _isAdmin = userData['isAdmin'] ?? false;
      notifyListeners();
    }
  }

  void login({
    required String userName,
    String fullName = "",
    String userId = "",
    double balance = 0,
    double depositedMoney = 0,
    bool isAdmin = false,
  }) {
    _isLoggedIn = true;
    _userName = userName;
    _fullName = fullName;
    _userId = userId;
    _balance = balance;
    _depositedMoney = depositedMoney;
    _isAdmin = isAdmin || userName.toLowerCase() == 'admin'; // Auto admin if username is admin
    
    // Lưu vào Cache để tránh mất login khi Reload Web
    CacheService.saveUser({
      'userName': _userName,
      'fullName': _fullName,
      'userId': _userId,
      'balance': _balance,
      'depositedMoney': _depositedMoney,
      'isAdmin': _isAdmin,
    });
    
    notifyListeners();
  }

  void updateMoney({required double balance, double? depositedMoney}) {
    _balance = balance;
    if (depositedMoney != null) {
      _depositedMoney = depositedMoney;
    }
    
    // Cập nhật lại cache khi đổi số dư
    final userData = CacheService.getUser();
    if (userData != null) {
      userData['balance'] = _balance;
      if (depositedMoney != null) userData['depositedMoney'] = _depositedMoney;
      CacheService.saveUser(userData);
    }
    
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = "";
    _fullName = "";
    _userId = "";
    _balance = 0;
    _depositedMoney = 0;
    _isAdmin = false;
    
    CacheService.clearUser();
    notifyListeners();
  }
}
