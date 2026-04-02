import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  bool _isLoggedIn = false;
  String _userName = ""; // user_name
  String _fullName = ""; // full_name
  String _userId = ""; // user_id/doc id
  double _balance = 0;
  double _depositedMoney = 0;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get fullName => _fullName;
  String get userId => _userId;
  double get balance => _balance;
  double get depositedMoney => _depositedMoney;

  void login({
    required String userName,
    String fullName = "",
    String userId = "",
    double balance = 0,
    double depositedMoney = 0,
  }) {
    _isLoggedIn = true;
    _userName = userName;
    _fullName = fullName;
    _userId = userId;
    _balance = balance;
    _depositedMoney = depositedMoney;
    notifyListeners();
  }

  void updateMoney({required double balance, double? depositedMoney}) {
    _balance = balance;
    if (depositedMoney != null) {
      _depositedMoney = depositedMoney;
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
    notifyListeners();
  }
}

