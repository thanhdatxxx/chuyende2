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

  @override
  Widget build(BuildContext context) {
    final displayCode = 123001 + globalIndex;
    final isSold = _isSoldStatus(acc['status']);
    final rankName = (acc['rank'] ?? '').toString();
    final price = acc['price'] is num ? (acc['price'] as num).toDouble() : 0.0;
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: PreviewableNetworkImage(imageUrl: (acc['image_url'] ?? '').toString()),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mã số: #$displayCode", style: AppStyles.accountCardTitleStyle),
                  const SizedBox(height: 2),
                  Text(currencyFormat.format(price), style: AppStyles.accountPriceStyle),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text("Rank: ", style: AppStyles.accountInfoLabelStyle),
                    const SizedBox(width: 2),
                    Image.asset(_getRankIcon(rankName), width: 32, height: 32, fit: BoxFit.contain),
                    const SizedBox(width: 4),
                    Expanded(child: Text(rankName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _getRankColor(rankName)), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('assets/images/rank/tuong.png', width: 32, height: 32, fit: BoxFit.contain),
                      const SizedBox(width: 4),
                      Text("${acc['hero_count'] ?? 0} Tướng", style: AppStyles.accountValueStyle),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('assets/images/rank/skin.png', width: 32, height: 32, fit: BoxFit.contain),
                      const SizedBox(width: 4),
                      Text("${acc['skin_count'] ?? 0} Skin", style: AppStyles.accountValueStyle),
                    ]),
                  ]),
                  const Spacer(),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onDetail(acc, id, displayCode),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text("Chi tiết", style: AppStyles.buttonTextStyle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSold ? null : onBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSold ? Colors.grey : AppStyles.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(isSold ? 'Đã bán' : 'Mua ngay', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
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
  const PreviewableNetworkImage({super.key, required this.imageUrl});

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey.shade800),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white),
          ),
          if (_isHovered)
            Container(
              color: Colors.black38,
              child: const Center(child: Text('Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
    );
  }
}
