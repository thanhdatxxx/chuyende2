import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../config/env.dart';

class AIService {
  int _currentKeyIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AIService({String? apiKey});

  void _rotateKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % Env.geminiApiKeys.length;
    print("🔄 Đã đổi sang API Key mới (Index: $_currentKeyIndex)");
  }

  GenerativeModel _createModel() {
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Env.geminiApiKeys[_currentKeyIndex],
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      systemInstruction: Content.system('''
BẠN LÀ NHÂN VIÊN BÁN HÀNG TẬN TÂM CỦA SHOP LIÊN QUÂN MOBILE.

QUY TẮC QUAN TRỌNG:
1. Khi khách hỏi tìm acc (ví dụ: "tìm acc 500k", "có acc thách đấu không"), bạn PHẢI tra cứu "DANH SÁCH KHO HÀNG" bên dưới.
2. Với mỗi tài khoản gợi ý, bạn PHẢI trình bày theo định dạng chuẩn sau để khách dễ nhìn:
   - Mã số: mã_id | [Tên Rank] - [Số tướng] Tướng - [Số Skin] Skin - Giá: [Giá tiền] [ID:mã_id]
3. Tuyệt đối PHẢI bao gồm tag [ID:mã_id] ở CUỐI MỖI DÒNG gợi ý tài khoản. Đây là mã kỹ thuật để tạo nút bấm, đừng bỏ sót.
4. Nếu không có acc đúng yêu cầu, hãy gợi ý các acc có giá hoặc rank gần nhất.
5. Luôn thân thiện, chuyên nghiệp và sử dụng Emoji phù hợp.
'''),
    );
  }

  Future<String> _getShopContext(String userMessage) async {
    try {
      final accountsSnapshot = await _firestore
          .collection('accounts')
          .where('status', isNotEqualTo: 'Đã bán')
          .limit(30)
          .get();

      if (accountsSnapshot.docs.isEmpty) return "Kho hàng hiện tại đang trống.";

      final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
      String context = "DANH SÁCH KHO HÀNG THỰC TẾ ĐANG CÓ:\n";
      
      for (var doc in accountsSnapshot.docs) {
        final data = doc.data();
        final id = data['id'] ?? doc.id; 
        final rank = data['rank'] ?? 'Chưa xác định';
        final heroes = data['hero_count'] ?? 0;
        final skins = data['skin_count'] ?? 0;
        final price = currencyFormat.format(data['price'] ?? 0);
        
        context += "- ID: $id | Rank: $rank, $heroes Tướng, $skins Skin, Giá: $price.\n";
      }
      return context;
    } catch (e) {
      return "Không thể kết nối dữ liệu kho hàng.";
    }
  }

  Stream<String> chatStream(String message, List<Content> history) async* {
    int attempts = 0;
    while (attempts < Env.geminiApiKeys.length) {
      try {
        final shopContext = await _getShopContext(message);
        final fullPrompt = "DỮ LIỆU KHO HÀNG:\n$shopContext\n\nCÂU HỎI CỦA KHÁCH: $message";

        final model = _createModel();
        final chatSession = model.startChat(
          history: history.length > 8 ? history.sublist(history.length - 8) : history,
        );
        
        final responseStream = chatSession.sendMessageStream(Content.text(fullPrompt));
        
        await for (final chunk in responseStream) {
          if (chunk.text != null) yield chunk.text!;
        }
        return; 
      } catch (e) {
        attempts++;
        _rotateKey();
        if (attempts >= Env.geminiApiKeys.length) {
          yield "Xin lỗi, hệ thống AI đang quá tải. Bạn hãy thử lại sau nhé!";
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  }
}
