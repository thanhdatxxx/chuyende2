import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_styles.dart';

class AccountCard extends StatelessWidget {
  final Map<String, dynamic> acc;
  final String id;
  final int globalIndex;
  final VoidCallback onBuy;
  final Function(Map<String, dynamic>, String, int) onDetail;

  const AccountCard({
    super.key,
    required this.acc,
    required this.id,
    required this.globalIndex,
    required this.onBuy,
    required this.onDetail,
  });

  bool _isSoldStatus(dynamic value) {
    final status = (value ?? '').toString().trim().toLowerCase();
    return status.contains('đã bán') || status.contains('da ban');
  }

  String _getRankIcon(String rankName) {
    rankName = rankName.toLowerCase();
    if (rankName.contains('đồng')) return 'assets/images/rank/Bronze_rank.png';
    if (rankName.contains('bạc')) return 'assets/images/rank/Silver_rank.png';
    if (rankName.contains('vàng')) return 'assets/images/rank/Gold_rank.png';
    if (rankName.contains('bạch kim')) return 'assets/images/rank/Platinum_rank.png';
    if (rankName.contains('kim cương')) return 'assets/images/rank/Diamond_rank.png';
    if (rankName.contains('tinh anh')) return 'assets/images/rank/Veteran_Rank.png';
    if (rankName.contains('cao thủ')) return 'assets/images/rank/Master_rank.png';
    if (rankName.contains('chiến tướng') || rankName.contains('thách đấu') || rankName.contains('conquerer')) {
      return 'assets/images/rank/Conquerer_rank.png';
    }
    return 'assets/images/rank/Bronze_rank.png';
  }

  Color _getRankColor(String rankName) {
    rankName = rankName.toLowerCase();
    if (rankName.contains('đồng')) return const Color(0xFFCD7F32);
    if (rankName.contains('bạc')) return const Color(0xFFC0C0C0);
    if (rankName.contains('vàng')) return const Color(0xFFFFD700);
    if (rankName.contains('bạch kim')) return const Color(0xFFE5E4E2);
    if (rankName.contains('kim cương')) return const Color(0xFFB9F2FF);
    if (rankName.contains('tinh anh')) return const Color(0xFFA855F7);
    if (rankName.contains('cao thủ')) return const Color(0xFFFF4500);
    if (rankName.contains('chiến tướng') || rankName.contains('thách đấu')) return const Color(0xFFFF0000);
    return Colors.black87;
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCode = int.tryParse(acc['id']?.toString() ?? '') ?? (123001 + globalIndex);
    final isSold = _isSoldStatus(acc['status']);
    final rankName = (acc['rank'] ?? '').toString();
    final imageUrl = (acc['image_url'] ?? '').toString();
    final price = acc['price'] is num ? (acc['price'] as num).toDouble() : 0.0;
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final description = (acc['description'] ?? acc['note'] ?? 'Tài khoản cực phẩm, trắng thông tin, giá siêu rẻ...').toString();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 4, 
            child: PreviewableNetworkImage(
              imageUrl: imageUrl,
              onTap: () => _showImagePreview(context, imageUrl),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mã số: #$displayCode", style: AppStyles.accountCardTitleStyle),
                  const SizedBox(height: 2),
                  Text(currencyFormat.format(price), style: AppStyles.accountPriceStyle),
                  const SizedBox(height: 8),
                  
                  // Wrap nội dung vào ScrollView để tránh lỗi tràn trên máy nhỏ
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Text("Rank: ", style: AppStyles.accountInfoLabelStyle),
                            const SizedBox(width: 2),
                            Image.asset(_getRankIcon(rankName), width: 28, height: 28, fit: BoxFit.contain),
                            const SizedBox(width: 4),
                            Expanded(child: Text(rankName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _getRankColor(rankName)), overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center, 
                            spacing: 8, 
                            runSpacing: 4,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Image.asset('assets/images/rank/tuong.png', width: 24, height: 24, fit: BoxFit.contain),
                                const SizedBox(width: 4),
                                Text("${acc['hero_count'] ?? 0} Tướng", style: AppStyles.accountValueStyle),
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Image.asset('assets/images/rank/skin.png', width: 24, height: 24, fit: BoxFit.contain),
                                const SizedBox(width: 4),
                                Text("${acc['skin_count'] ?? 0} Skin", style: AppStyles.accountValueStyle),
                              ]),
                            ]
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14, 
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onDetail(acc, id, displayCode),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Chi tiết", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSold ? null : onBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSold ? Colors.grey : AppStyles.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isSold ? 'Đã bán' : 'Mua ngay', style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ])
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PreviewableNetworkImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;
  const PreviewableNetworkImage({super.key, required this.imageUrl, required this.onTap});

  @override
  State<PreviewableNetworkImage> createState() => _PreviewableNetworkImageState();
}

class _PreviewableNetworkImageState extends State<PreviewableNetworkImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.imageUrl.isEmpty ? null : widget.onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.imageUrl.isEmpty 
              ? Container(color: Colors.grey.shade800, child: const Icon(Icons.broken_image, color: Colors.white))
              : CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade800),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white),
                ),
            if (_isHovered && widget.imageUrl.isNotEmpty)
              Container(
                color: Colors.black38,
                child: const Center(child: Icon(Icons.zoom_in, color: Colors.white, size: 40)),
              ),
          ],
        ),
      ),
    );
  }
}
