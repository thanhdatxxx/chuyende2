import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../config/env.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _zaloLink = "https://zalo.me/0942449399"; 

  AIService({String? apiKey});

  GenerativeModel _createModel(String shopContext) {
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Env.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Giảm temperature để AI phản hồi chính xác hơn, bớt "bay bổng"
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system('''
BẠN LÀ CHUYÊN VIÊN TƯ VẤN BÁN HÀNG CỦA SHOP LIÊN QUÂN MOBILE.

DỮ LIỆU KHO HÀNG THỰC TẾ (Chỉ được tư vấn các ID có trong đây):
$shopContext

NHIỆM VỤ QUAN TRỌNG NHẤT:
1. Khi khách hỏi tìm acc/tài khoản, bạn PHẢI liệt kê danh sách tài khoản phù hợp nhất từ dữ liệu trên.
2. Nếu không có acc đúng yêu cầu (sai rank, sai giá), bạn PHẢI nói: "Hiện tại shop chưa có acc đúng như yêu cầu, nhưng mình gửi bạn các mẫu tương tự/đẹp nhất hiện có nhé:" và LIỆT KÊ các acc khác từ kho hàng.
3. Định dạng bắt buộc cho mỗi tài khoản:
   - Mã số: [ID:mã_id] | [Tên Rank] - [Số tướng] Tướng - [Số Skin] Skin - Giá: [Giá tiền]
4. Luôn thêm tag [ID:mã_id] (ví dụ [ID:123456]) vào cuối mỗi dòng để khách có thể nhấn xem chi tiết.
5. Nếu khách hỏi về uy tín/xem ảnh/mua hàng, hãy dẫn link Zalo: $_zaloLink.
6. Tuyệt đối không tự bịa ra thông số tài khoản (ID, Rank, Giá) không có trong danh sách trên.
'''),
    );
  }

  Future<String> _getShopContext(String userMessage) async {
    try {
      final snapshot = await _firestore
          .collection('accounts')
          .where('status', isNotEqualTo: 'Đã bán')
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return "Kho hàng hiện tại đang trống.";

      List<QueryDocumentSnapshot> allDocs = snapshot.docs;
      String msg = userMessage.toLowerCase();
      
      // Lọc giá thông minh hơn
      double? maxPrice;
      final pricePatterns = [
        RegExp(r'(\d+)\s*(triệu|tr|củ)'),
        RegExp(r'(\d+)\s*k'),
        RegExp(r'dưới\s*(\d+)\s*(triệu|tr|củ|k)?'),
      ];

      for (var pattern in pricePatterns) {
        final match = pattern.firstMatch(msg);
        if (match != null) {
          double val = double.tryParse(match.group(1)!) ?? 0;
          String? unit = match.groupCount >= 2 ? match.group(2) : null;
          
          if (unit == 'triệu' || unit == 'tr' || unit == 'củ') {
            maxPrice = val * 1000000;
          } else if (unit == 'k') {
            maxPrice = val * 1000;
          } else if (val > 0 && val < 5000) { // Ví dụ "10 triệu" nhưng chỉ bắt được "10"
             maxPrice = val * 1000000;
          }
          break;
        }
      }

      // Phát hiện rank
      List<String> targetRanks = [];
      final ranks = ['đồng', 'bạc', 'vàng', 'bạch kim', 'tinh anh', 'cao thủ', 'chiến tướng', 'thách đấu'];
      for (var r in ranks) {
        if (msg.contains(r)) targetRanks.add(r);
      }

      List<QueryDocumentSnapshot> filteredDocs = allDocs;
      
      if (targetRanks.isNotEmpty) {
        filteredDocs = filteredDocs.where((doc) {
          final rank = (doc.data() as Map<String, dynamic>)['rank']?.toString().toLowerCase() ?? '';
          return targetRanks.any((tr) => rank.contains(tr));
        }).toList();
      }

      if (maxPrice != null) {
        filteredDocs = filteredDocs.where((doc) {
          final price = (doc.data() as Map<String, dynamic>)['price'] ?? 0;
          return price <= maxPrice!;
        }).toList();
      }

      // Nếu lọc xong mà trống, trả về 15 acc bất kỳ để AI có dữ liệu mà gợi ý
      if (filteredDocs.isEmpty) {
        return _formatDocsToContext(allDocs.take(15).toList());
      }

      return _formatDocsToContext(filteredDocs.take(30).toList());
    } catch (e) {
      print("Error fetching context: $e");
      return "Dữ liệu kho hàng tạm thời không khả dụng.";
    }
  }

  String _formatDocsToContext(List<QueryDocumentSnapshot> docs) {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    String context = "";
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final id = data['id']?.toString() ?? doc.id; 
      final rank = data['rank'] ?? 'Chưa xác định';
      final heroes = data['hero_count'] ?? 0;
      final skins = data['skin_count'] ?? 0;
      final price = currencyFormat.format(data['price'] ?? 0);
      
      context += "- ID: $id | Rank: $rank, $heroes Tướng, $skins Skin, Giá: $price\n";
    }
    return context;
  }

  Stream<String> chatStream(String message, List<Content> history) async* {
    yield "Đang kiểm tra kho hàng... 🔍 "; 
    
    int attempts = 0;
    while (attempts < Env.geminiApiKeys.length) {
      try {
        final shopContext = await _getShopContext(message);
        final model = _createModel(shopContext);

        // Lấy 4 câu hội thoại gần nhất để giữ ngữ cảnh mà không làm loãng Prompt hệ thống
        final cleanHistory = history.length > 4 ? history.sublist(history.length - 4) : history;
        final chatSession = model.startChat(history: cleanHistory);
        
        final responseStream = chatSession.sendMessageStream(Content.text(message));
        
        await for (final chunk in responseStream) {
          if (chunk.text != null) yield chunk.text!;
        }
        return; 
      } catch (e) {
        attempts++;
        Env.nextKey(); 
        if (attempts >= Env.geminiApiKeys.length) {
          yield "\nHệ thống AI đang bận. Liên hệ Zalo $_zaloLink để được hỗ trợ trực tiếp nhé! 🙏";
        } else {
          yield "\n(Đang thử kết nối lại...) ";
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  }
}
