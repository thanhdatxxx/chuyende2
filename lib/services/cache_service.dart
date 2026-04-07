import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _accountsCacheBoxName = 'accounts_cache';
  static const String _cacheExpiryKey = 'cache_expiry';
  static const Duration _cacheExpiry = Duration(hours: 6);

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_accountsCacheBoxName);
  }

  static Future<void> cacheAccounts(List<Map<String, dynamic>> accounts) async {
    final box = Hive.box<dynamic>(_accountsCacheBoxName);
    try {
      await box.put('accounts', accounts);
      await box.put(_cacheExpiryKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Handle caching error silently
    }
  }

  static List<Map<String, dynamic>>? getCachedAccounts() {
    try {
      final box = Hive.box<dynamic>(_accountsCacheBoxName);
      final expiryTime = box.get(_cacheExpiryKey) as int?;

      if (expiryTime == null) return null;

      final now = DateTime.now();
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(expiryTime);
      final timeDifference = now.difference(cachedTime);

      if (timeDifference > _cacheExpiry) {
        clearCache();
        return null;
      }

      final cached = box.get('accounts') as List?;
      if (cached == null) return null;

      return List<Map<String, dynamic>>.from(
        cached.cast<Map<dynamic, dynamic>>().map((item) {
          final converted = <String, dynamic>{};
          item.forEach((key, value) {
            converted[key.toString()] = value;
          });
          return converted;
        }),
      );
    } catch (e) {
      // Handle retrieval error silently
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      final box = Hive.box<dynamic>(_accountsCacheBoxName);
      await box.clear();
    } catch (e) {
      // Handle clear error silently
    }
  }

  static bool isCacheExpired() {
    try {
      final box = Hive.box<dynamic>(_accountsCacheBoxName);
      final expiryTime = box.get(_cacheExpiryKey) as int?;
      if (expiryTime == null) return true;

      final now = DateTime.now();
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(expiryTime);
      final timeDifference = now.difference(cachedTime);

      return timeDifference > _cacheExpiry;
    } catch (e) {
      return true;
    }
  }
}




