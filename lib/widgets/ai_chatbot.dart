import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_service.dart';
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import 'app_styles.dart';

class AIChatBot extends StatefulWidget {
  final String apiKey;
  const AIChatBot({super.key, required this.apiKey});

  @override
  State<AIChatBot> createState() => _AIChatBotState();
}

class _AIChatBotState extends State<AIChatBot> {
  bool _isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  final List<Content> _history = [];
  late final AIService _aiService;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _aiService = AIService(apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _scrollToBottom();
      if (_history.isEmpty) {
        _sendWelcomeMessage();
      }
      Future.delayed(const Duration(milliseconds: 300), () => _focusNode.requestFocus());
    }
  }

  void _sendWelcomeMessage() {
    final auth = context.read<AuthService>();
    String greeting = "Chào bạn!";
    
    if (auth.isLoggedIn) {
      final name = auth.fullName.isNotEmpty ? auth.fullName : auth.userName;
      greeting = "Chào $name!";
    }

    setState(() {
      _history.add(Content('model', [
        TextPart("👋 $greeting Mình là Trợ lý ảo của Shop Liên Quân.\n\n"
            " Mình có thể giúp bạn:\n"
            "• Tìm tài khoản theo Rank, Tướng hoặc Skin.\n"
            "• Hướng dẫn nạp tiền và thanh toán.\n"
            "• Giải đáp các thắc mắc về dịch vụ của shop.\n\n"
            "Bạn đang quan tâm đến mẫu tài khoản nào nhỉ?")
      ]));
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _history.add(Content('user', [TextPart(text)]));
      _controller.clear();
      _isLoading = true;
      _history.add(Content('model', [TextPart("")]));
    });

    _scrollToBottom();

    String currentResponse = "";
    try {
      final stream = _aiService.chatStream(text, _history.take(_history.length - 1).toList());
      
      await for (final chunk in stream) {
        currentResponse += chunk;
        if (mounted) {
          setState(() {
            _history[_history.length - 1] = Content('model', [TextPart(currentResponse)]);
          });
          _scrollToBottomInstant();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _history[_history.length - 1] = Content('model', [TextPart("Xin lỗi, tôi gặp lỗi kết nối AI.")]);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _focusNode.requestFocus();
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottomInstant() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleViewDetail(String id) async {
    try {
      var doc = await FirebaseFirestore.instance.collection('accounts').doc(id).get();
      if (!doc.exists) {
        var query = await FirebaseFirestore.instance.collection('accounts').where('id', isEqualTo: id).limit(1).get();
        if (query.docs.isEmpty) {
          final numericId = int.tryParse(id);
          if (numericId != null) {
            query = await FirebaseFirestore.instance.collection('accounts').where('id', isEqualTo: numericId).limit(1).get();
          }
        }
        if (query.docs.isNotEmpty) doc = query.docs.first;
      }

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final displayCode = int.tryParse(data['id']?.toString() ?? '') ?? 123001;
        NavigationService.navigatorKey.currentState?.pushNamed('/detail', arguments: {
          'docId': doc.id,
          'displayCode': displayCode,
          'account': data,
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy thông tin chi tiết.')));
        }
      }
    } catch (e) {
      debugPrint("Lỗi chi tiết: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Stack(
      children: [
        if (_isExpanded)
          Positioned(
            bottom: 80,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: isMobile ? size.width * 0.85 : 400,
                height: size.height * 0.7,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const Divider(color: Colors.white24),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              return _buildChatContent(_history[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputArea(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        _buildFab(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppStyles.primaryColor,
              radius: 15,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            SizedBox(width: 10),
            Text("Trợ lý Shop Liên Quân", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: _toggleChat,
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: "Hỏi tôi bất cứ điều gì...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: Icon(Icons.send, color: _isLoading ? Colors.grey : AppStyles.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: AppStyles.primaryColor,
        child: Icon(_isExpanded ? Icons.keyboard_arrow_down : Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildChatContent(Content content) {
    final isUser = content.role == 'user';
    final text = content.parts.whereType<TextPart>().map((e) => e.text).join();
    
    final RegExp accRegExp = RegExp(r'\[(?:ID|MÃ):([\w-]+)\]', caseSensitive: false);
    final List<String> accountIds = accRegExp.allMatches(text).map((m) => m.group(1)!).toList();
    
    String cleanText = text.replaceAllMapped(accRegExp, (match) => match.group(1)!)
                          .replaceAll("**", "")
                          .trim();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppStyles.primaryColor.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(color: isUser ? Colors.white24 : Colors.white10),
            ),
            child: _buildRichText(cleanText.isEmpty && !isUser ? "Đang suy nghĩ..." : (cleanText.isEmpty ? text : cleanText)),
          ),
          if (accountIds.isNotEmpty && !isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: accountIds.toSet().map((id) => _buildViewDetailButton(id)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRichText(String text) {
    // Regex tìm link Zalo cụ thể hoặc các link nói chung
    final RegExp linkRegExp = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    final matches = linkRegExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4));
    }

    List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (var match in matches) {
      // Thêm đoạn chữ thường trước link
      if (match.start > lastIndex) {
        String preText = text.substring(lastIndex, match.start);
        // Nếu đoạn chữ trước kết thúc bằng "tại đây: ", chúng ta sẽ xử lý đặc biệt
        if (preText.endsWith("tại đây: ")) {
          spans.add(TextSpan(text: preText.substring(0, preText.length - 9)));
          lastIndex = match.start; // Sẽ xử lý "tại đây" thành link ở bước sau
        } else {
          spans.add(TextSpan(text: preText));
        }
      }

      String url = match.group(0)!;
      bool isZalo = url.contains("zalo.me");

      // Tạo Link
      spans.add(TextSpan(
        text: isZalo ? "tại đây" : url,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontFamily: 'Roboto'),
        children: spans,
      ),
    );
  }

  Widget _buildViewDetailButton(String accountId) {
    return ElevatedButton.icon(
      onPressed: () => _handleViewDetail(accountId),
      icon: const Icon(Icons.shopping_cart_outlined, size: 14),
      label: Text("CHI TIẾT: ${accountId.toUpperCase()}"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppStyles.primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
