import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../config/env.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _zaloContact = "0942449399"; 
  final String _zaloLink = "https://zalo.me/0942449399"; 

  AIService({String? apiKey});

  GenerativeModel _createModel(String shopContext) {
    return GenerativeModel(
      // Cập nhật lên model 2.0 Flash Experimental - Nhanh và thông minh hơn
      model: 'gemini-2.5-flash',
      apiKey: Env.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      systemInstruction: Content.system('''
BẠN LÀ NHÂN VIÊN BÁN HÀNG TẬN TÂM CỦA SHOP LIÊN QUÂN MOBILE.

DỮ LIỆU KHO HÀNG HIỆN TẠI (Chỉ tư vấn trong danh sách này):
$shopContext

QUY TẮC QUAN TRỌNG:
1. Khi khách hỏi tìm acc, bạn PHẢI tra cứu "DỮ LIỆU KHO HÀNG" ở trên.
2. Với mỗi tài khoản gợi ý, bạn PHẢI trình bày theo định dạng chuẩn:
   - Mã số: mã_id | [Tên Rank] - [Số tướng] Tướng - [Số Skin] Skin - Giá: [Giá tiền] [ID:mã_id]
3. Tuyệt đối PHẢI bao gồm tag [ID:mã_id] ở CUỐI MỖI DÒNG gợi ý tài khoản.
4. HỖ TRỢ TRỰC TIẾP QUA ZALO: Cung cấp link $_zaloLink khi khách sợ bị lừa, muốn bán acc, xem ảnh chi tiết hoặc khiếu nại.
5. Luôn thân thiện, chuyên nghiệp và sử dụng Emoji phù hợp.
'''),
    );
  }

  Future<String> _getShopContext(String userMessage) async {
    try {
      Query query = _firestore.collection('accounts').where('status', isNotEqualTo: 'Đã bán');
      String msg = userMessage.toLowerCase();
      
      if (msg.contains('đồng')) query = query.where('rank', isEqualTo: 'Đồng');
      else if (msg.contains('bạc')) query = query.where('rank', isEqualTo: 'Bạc');
      else if (msg.contains('vàng')) query = query.where('rank', isEqualTo: 'Vàng');
      else if (msg.contains('bạch kim')) query = query.where('rank', isEqualTo: 'Bạch Kim');
      else if (msg.contains('tinh anh')) query = query.where('rank', isEqualTo: 'Tinh Anh');
      else if (msg.contains('cao thủ')) query = query.where('rank', isEqualTo: 'Cao Thủ');
      else if (msg.contains('chiến tướng')) query = query.where('rank', isEqualTo: 'Chiến Tướng');
      else if (msg.contains('thách đấu')) query = query.where('rank', isEqualTo: 'Thách Đấu');

      final accountsSnapshot = await query.limit(50).get();

      if (accountsSnapshot.docs.isEmpty) {
        final fallbackSnapshot = await _firestore
            .collection('accounts')
            .where('status', isNotEqualTo: 'Đã bán')
            .limit(30)
            .get();
        if (fallbackSnapshot.docs.isEmpty) return "Kho hàng hiện tại đang trống.";
        return _formatDocsToContext(fallbackSnapshot.docs);
      }

      return _formatDocsToContext(accountsSnapshot.docs);
    } catch (e) {
      print("Error fetching context: $e");
      return "Không thể kết nối dữ liệu kho hàng.";
    }
  }

  String _formatDocsToContext(List<QueryDocumentSnapshot> docs) {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    String context = "";
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final id = data['id'] ?? doc.id; 
      final rank = data['rank'] ?? 'Chưa xác định';
      final heroes = data['hero_count'] ?? 0;
      final skins = data['skin_count'] ?? 0;
      final price = currencyFormat.format(data['price'] ?? 0);
      
      context += "- ID: $id | Rank: $rank, $heroes Tướng, $skins Skin, Giá: $price.\n";
    }
    return context;
  }

  Stream<String> chatStream(String message, List<Content> history) async* {
    yield "Đang kiểm tra kho hàng... 🔍"; 
    
    int attempts = 0;
    while (attempts < Env.geminiApiKeys.length) {
      try {
        final shopContext = await _getShopContext(message);
        final model = _createModel(shopContext);

        final cleanHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
        final chatSession = model.startChat(history: cleanHistory);
        
        final responseStream = chatSession.sendMessageStream(Content.text(message));
        
        await for (final chunk in responseStream) {
          if (chunk.text != null) yield chunk.text!;
        }
        return; 
      } catch (e) {
        print("🔴 Lỗi Gemini: $e");
        
        attempts++;
        Env.nextKey(); 

        if (attempts >= Env.geminiApiKeys.length) {
          yield "Hệ thống AI đang quá tải. Bạn liên hệ trực tiếp nhân viên tại đây: https://zalo.me/0942449399 để được hỗ trợ nhé! 🙏";
        } else {
          yield "Đang thử kết nối lại với máy chủ dự phòng... 🔄";
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }
  }
}
