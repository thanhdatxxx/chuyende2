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

  // 1. TẠO ĐƠN HÀNG CHỜ (PENDING)
  Future<void> createPendingOrder({
    required int orderCode,
    required String userId,
    required String accountDocId,
    required String id,
    required double price,
  }) async {
    await _firestore.collection('orders').add({
      'orderCode': orderCode,
      'user_id': userId,
      'account_id': accountDocId,
      'id': id, 
      'amount': price,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // 2. TẠO LINK THANH TOÁN - Gửi ID tài khoản lên Apps Script
  Future<Map<String, dynamic>> createPayOSLink({
    required int orderCode,
    required int amount,
    required String accountIdReal, 
  }) async {
    try {
      final String currentOrigin = Uri.base.origin;
      final String returnUrl = "$currentOrigin/#/payment"; 

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'create_link',
          'orderCode': orderCode,
          'amount': amount,
          'id': accountIdReal, 
          'returnUrl': returnUrl, 
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Lỗi kết nối PayOS: $e');
    }
  }

  // Cập nhật trạng thái khi HỦY trực tiếp trên Firestore (Dùng cho Tab cũ nhận biết)
  Future<void> updateOrderCancel(int orderCode) async {
    final query = await _firestore
        .collection('orders')
        .where('orderCode', isEqualTo: orderCode)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({'status': 'cancelled'});
    }
  }

  // Thông báo hủy qua Apps Script (Để hệ thống phía server biết)
  Future<void> cancelOrder(int orderCode) async {
    try {
      await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'cancel_payment',
          'orderCode': orderCode,
        }),
      );
    } catch (e) {
      print("Lỗi khi báo hủy đơn: $e");
    }
  }

  // Lắng nghe kết quả thành công Realtime (Từ history)
  Stream<DocumentSnapshot?> listenToPurchaseHistory(int orderCode) {
    return _firestore
        .collection('history')
        .where('orderCode', isEqualTo: orderCode)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }

  // Lắng nghe trạng thái đơn hàng (Từ orders - Để biết khi nào bị cancelled)
  Stream<DocumentSnapshot?> listenToPaymentStatus(int orderCode) {
    return _firestore
        .collection('orders')
        .where('orderCode', isEqualTo: orderCode)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }

  // --- CÁC CHỨC NĂNG THANH TOÁN BẰNG VÍ (GIỮ NGUYÊN) ---

  Future<PurchaseResult> purchaseAccount({
    required String userName,
    required String userId,
    required String accountId, 
    required int accountCode,
    required double price,
  }) async {
    try {
      if (userId.isEmpty || accountId.isEmpty) throw "Dữ liệu không hợp lệ.";
      final userSnap = await _firestore.collection('user').doc(userId).get();
      final accountSnap = await _firestore.collection('accounts').doc(accountId).get();
      
      if (!userSnap.exists) throw "Tài khoản không tồn tại.";
      if (!accountSnap.exists) throw "Nick không tồn tại.";

      final userData = userSnap.data()!;
      final accountData = accountSnap.data()!;
      final currentBalance = _asDouble(userData['balance']);
      
      if (currentBalance < price) throw "Số dư không đủ!";
      if (_isSoldStatus(accountData['status'] ?? '')) throw "Nick đã bán!";

      final int orderCode = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final double updatedBalance = currentBalance - price;

      final batch = _firestore.batch();
      final historyRef = _firestore.collection('history').doc();
      final orderRef = _firestore.collection('orders').doc();

      batch.update(_firestore.collection('user').doc(userId), {'balance': updatedBalance});
      batch.update(_firestore.collection('accounts').doc(accountId), {'status': 'Đã bán', 'sold_to': userId, 'sold_at': FieldValue.serverTimestamp()});
      
      batch.set(orderRef, {'orderCode': orderCode, 'user_id': userId, 'account_id': accountId, 'amount': price, 'status': 'completed', 'created_at': FieldValue.serverTimestamp()});
      batch.set(historyRef, {
        'account_id': accountId, 'amount': price, 'created_at': FieldValue.serverTimestamp(),
        'matkhau': accountData['matkhau'], 'orderCode': orderCode, 'status': 'Thành công',
        'taikhoan': accountData['taikhoan'], 'type': 'purchase', 'user_id': userId,
        'user_name': userName, 'balance_after': updatedBalance,
      });

      await batch.commit();
      return PurchaseResult(newBalance: updatedBalance, transactionCode: orderCode, historyId: historyRef.id);
    } catch (e) {
      throw e.toString();
    }
  }

  // --- HÀM LẤY CHI TIẾT LỊCH SỬ (KHÔNG ĐƯỢC XÓA) ---
  Future<Map<String, dynamic>> getPurchasedAccountDetail({
    required String historyId,
    required String currentUserName,
  }) async {
    final historySnap = await _firestore.collection('history').doc(historyId).get();
    if (!historySnap.exists) throw "Giao dịch không tồn tại.";

    final historyData = historySnap.data()!;
    final accountId = (historyData['account_id'] ?? '').toString();
    final accountSnap = await _firestore.collection('accounts').doc(accountId).get();

    return {
      if (accountSnap.exists) ...accountSnap.data()!,
      'history_id': historyId,
      'orderCode': historyData['orderCode'],
      'taikhoan': historyData['taikhoan'],
      'matkhau': historyData['matkhau'],
      'amount': historyData['amount'],
    };
  }

  Future<Map<String, String>> getTransactionCredentials({required String historyId, required String currentUserName}) async {
    final detail = await getPurchasedAccountDetail(historyId: historyId, currentUserName: currentUserName);
    return {'taikhoan': (detail['taikhoan'] ?? '').toString(), 'matkhau': (detail['matkhau'] ?? '').toString()};
  }
}
