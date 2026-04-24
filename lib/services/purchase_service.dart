import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class PurchaseResult {
  const PurchaseResult({
    required this.newBalance,
    required this.transactionCode,
    required this.historyId,
  });

  final double newBalance;
  final int transactionCode;
  final String historyId;
}

class PurchaseService {
  PurchaseService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final String baseUrl = "https://script.google.com/macros/s/AKfycbxNEwSZvXUFMTQxb4sl95P18Uqqd_bv9T4ZdB2qVp94nhXSVWaHqGDeGbXUHeMOW8ufMw/exec";

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isSoldStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized.contains('da ban') || normalized.contains('đã bán');
  }

  // # Hàm tạo link: Cập nhật trỏ về link Web App mới từ Google Apps Script
  Future<Map<String, dynamic>> createPayOSLink({
    required int orderCode,
    required int amount,
    required String accountCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'text/plain'}, // Dùng text/plain để tránh CORS preflight trên Web
        body: jsonEncode({
          'action': 'create_link', // Quan trọng: Để Apps Script biết là tạo link
          'orderCode': orderCode,
          'amount': amount,
          'accountCode': accountCode,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Lỗi server: ${response.body}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến Apps Script: $e');
    }
  }

  Future<PurchaseResult> purchaseAccount({
    required String userName,
    required String accountId,
    required int accountCode,
    required double price,
  }) async {
    final userQuery = await _firestore
        .collection('user')
        .where('user_name', isEqualTo: userName)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw StateError('USER_NOT_FOUND');
    }

    final userRef = userQuery.docs.first.reference;
    final accountRef = _firestore.collection('accounts').doc(accountId);
    final counterRef = _firestore.collection('meta').doc('history_counter');
    final historyRef = _firestore.collection('history').doc();

    return _firestore.runTransaction<PurchaseResult>((transaction) async {
      final userSnap = await transaction.get(userRef);
      final accountSnap = await transaction.get(accountRef);
      final counterSnap = await transaction.get(counterRef);

      if (!accountSnap.exists) {
        throw StateError('ACCOUNT_NOT_FOUND');
      }

      final currentBalance = _asDouble(userSnap.data()?['balance']);
      final accountData = accountSnap.data() ?? <String, dynamic>{};
      final status = (accountData['status'] ?? '').toString();

      if (currentBalance < price) {
        throw StateError('INSUFFICIENT_BALANCE');
      }
      if (_isSoldStatus(status)) {
        throw StateError('ACCOUNT_SOLD');
      }

      final updatedBalance = currentBalance - price;
      final lastCode = (counterSnap.data()?['last_code'] as num?)?.toInt() ?? 300000;
      final transactionCode = lastCode + 1;

      transaction.update(userRef, {
        'balance': updatedBalance,
        'updated_at': FieldValue.serverTimestamp(),
      });
      transaction.update(accountRef, {
        'status': 'Đã bán',
        'sold_to': userName,
        'sold_at': FieldValue.serverTimestamp(),
      });
      transaction.set(counterRef, {
        'last_code': transactionCode,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(historyRef, {
        'type': 'purchase',
        'user_name': userName,
        'account_id': accountId,
        'account_code': accountCode,
        'transaction_code': transactionCode,
        'amount': price,
        'balance_after': updatedBalance,
        'created_at': FieldValue.serverTimestamp(),
      });

      return PurchaseResult(
        newBalance: updatedBalance,
        transactionCode: transactionCode,
        historyId: historyRef.id,
      );
    });
  }

  Future<Map<String, String>> getTransactionCredentials({
    required String historyId,
    required String currentUserName,
  }) async {
    final detail = await getPurchasedAccountDetail(
      historyId: historyId,
      currentUserName: currentUserName,
    );

    return {
      'taikhoan': (detail['taikhoan'] ?? '').toString(),
      'matkhau': (detail['matkhau'] ?? '').toString(),
    };
  }

  Future<Map<String, dynamic>> getPurchasedAccountDetail({
    required String historyId,
    required String currentUserName,
  }) async {
    final historySnap = await _firestore.collection('history').doc(historyId).get();
    if (!historySnap.exists) {
      throw StateError('TRANSACTION_NOT_FOUND');
    }

    final historyData = historySnap.data() ?? <String, dynamic>{};
    
    // Chấp nhận cả user_name (Ví) và user_id (PayOS/Apps Script)
    final owner = (historyData['user_name'] ?? historyData['user_id'] ?? '').toString().trim();
    final accountId = (historyData['account_id'] ?? '').toString().trim();

    final accountSnap = await _firestore.collection('accounts').doc(accountId).get();
    if (!accountSnap.exists) {
      throw StateError('ACCOUNT_NOT_FOUND');
    }

    final accountData = accountSnap.data() ?? <String, dynamic>{};
    final soldTo = (accountData['sold_to'] ?? '').toString().trim();
    final status = (accountData['status'] ?? '').toString();

    // Kiểm tra quyền sở hữu linh hoạt hơn
    if (soldTo != currentUserName && soldTo != historyData['user_id']) {
      throw StateError('FORBIDDEN');
    }

    final username = (accountData['taikhoan'] ?? '').toString();
    final password = (accountData['matkhau'] ?? '').toString();

    if (username.isEmpty || password.isEmpty) {
      throw StateError('MISSING_CREDENTIALS');
    }

    return {
      'history_id': historyId,
      'transaction_code': historyData['transaction_code'] ?? historyData['order_id'] ?? historyData['orderCode'],
      'account_id': accountId,
      'account_code': accountData['account_code'],
      'price': accountData['price'],
      'rank': accountData['rank'],
      'hero_count': accountData['hero_count'],
      'skin_count': accountData['skin_count'],
      'status': accountData['status'],
      'image_url': accountData['image_url'],
      'taikhoan': username,
      'matkhau': password,
    };
  }
}
