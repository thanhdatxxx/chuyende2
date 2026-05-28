import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UiSettingsService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _subscription;

  // Local defaults
  static const List<String> _defaultBanners = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  static const List<String> _defaultMusicTracks = [
    'assets/audio/bai1.mp3',
    'assets/audio/bai2.ogg',
    'assets/audio/bai3.ogg',
  ];

  static const String _defaultFooterDescription =
      "Hệ thống bán tài khoản Liên Quân Mobile uy tín, chất lượng hàng đầu Việt Nam. Giao dịch tự động 24/7.";
  static const String _defaultFooterPhone = "0987.654.321";
  static const String _defaultFooterEmail = "support@lienquanshop.vn";
  static const String _defaultFooterLocation = "Hà Nội, Việt Nam";
  static const String _defaultFooterCopyright =
      "© 2024 LIENQUAN SHOP VN - All Rights Reserved.";
  static const String _defaultBackgroundImage =
      "assets/images/anh-lien-quan-4k-thu-nguyen-ve-than-66.jpg";

  // Active configurations
  List<String> _banners = List.from(_defaultBanners);
  List<String> _musicTracks = List.from(_defaultMusicTracks);
  String _backgroundImage = _defaultBackgroundImage;
  String _footerDescription = _defaultFooterDescription;
  String _footerPhone = _defaultFooterPhone;
  String _footerEmail = _defaultFooterEmail;
  String _footerLocation = _defaultFooterLocation;
  String _footerCopyright = _defaultFooterCopyright;

  bool _isLoading = false;

  // Getters
  List<String> get banners => _banners;
  List<String> get musicTracks => _musicTracks;
  String get backgroundImage => _backgroundImage;
  String get footerDescription => _footerDescription;
  String get footerPhone => _footerPhone;
  String get footerEmail => _footerEmail;
  String get footerLocation => _footerLocation;
  String get footerCopyright => _footerCopyright;
  bool get isLoading => _isLoading;

  UiSettingsService() {
    _startListening();
  }

  void _startListening() {
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('system_settings')
        .doc('ui_settings')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['banners'] != null) {
          _banners = List<String>.from(data['banners']);
        }
        if (data['music'] != null) {
          _musicTracks = List<String>.from(data['music']);
        }
        if (data['backgroundImage'] != null) {
          _backgroundImage = data['backgroundImage'];
        }
        if (data['footer'] != null) {
          final footerData = Map<String, dynamic>.from(data['footer']);
          _footerDescription = footerData['description'] ?? _defaultFooterDescription;
          _footerPhone = footerData['phone'] ?? _defaultFooterPhone;
          _footerEmail = footerData['email'] ?? _defaultFooterEmail;
          _footerLocation = footerData['location'] ?? _defaultFooterLocation;
          _footerCopyright = footerData['copyright'] ?? _defaultFooterCopyright;
        }
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Lỗi lắng nghe cấu hình giao diện từ Firestore: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<bool> saveSettings({
    required List<String> banners,
    required List<String> music,
    required String backgroundImage,
    required String footerDescription,
    required String footerPhone,
    required String footerEmail,
    required String footerLocation,
    required String footerCopyright,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = {
        'banners': banners,
        'music': music,
        'backgroundImage': backgroundImage,
        'footer': {
          'description': footerDescription,
          'phone': footerPhone,
          'email': footerEmail,
          'location': footerLocation,
          'copyright': footerCopyright,
        },
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('system_settings').doc('ui_settings').set(data);

      _banners = banners;
      _musicTracks = music;
      _backgroundImage = backgroundImage;
      _footerDescription = footerDescription;
      _footerPhone = footerPhone;
      _footerEmail = footerEmail;
      _footerLocation = footerLocation;
      _footerCopyright = footerCopyright;

      return true;
    } catch (e) {
      debugPrint('Lỗi lưu cấu hình giao diện lên Firestore: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetToDefault() async {
    return saveSettings(
      banners: _defaultBanners,
      music: _defaultMusicTracks,
      backgroundImage: _defaultBackgroundImage,
      footerDescription: _defaultFooterDescription,
      footerPhone: _defaultFooterPhone,
      footerEmail: _defaultFooterEmail,
      footerLocation: _defaultFooterLocation,
      footerCopyright: _defaultFooterCopyright,
    );
  }
}
