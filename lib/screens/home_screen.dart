import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/ui_settings_service.dart';
import '../widgets/app_styles.dart';
import '../widgets/account_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/home_footer.dart';
import '../widgets/ui_effects.dart';
import '../widgets/top_menu.dart';
import 'payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  // Dùng flag static để chỉ redirect 1 lần sau khi load trang (tránh loop khi quay lại trang chủ)
  static bool _hasCheckedRedirect = false;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _minPriceController = TextEditingController(text: "");
  final TextEditingController _maxPriceController = TextEditingController(text: "");
  final ScrollController _scrollController = ScrollController();

  String selectedRank = 'Tất cả';
  final List<String> ranks = ['Tất cả', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Tinh Anh', 'Cao Thủ', 'Chiến Tướng', 'Thách Đấu'];

  int currentPage = 1;
  final int itemsPerPage = 12;
  int soldCurrentPage = 1;
  final int soldItemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    _checkPayOSRedirect();
  }

  void _checkPayOSRedirect() {
    if (!kIsWeb || HomeScreen._hasCheckedRedirect) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.base;
      // Nếu URL có chứa status (trả về từ PayOS), chuyển hướng sang màn hình thanh toán
      if (uri.queryParameters.containsKey('status')) {
        HomeScreen._hasCheckedRedirect = true;
        Navigator.pushNamed(context, '/payment');
      }
    });
  }

  double _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  bool _isSoldStatus(dynamic value) => (value ?? '').toString().trim().toLowerCase().contains('đã bán');

  Future<void> _handleBuyFromHome(Map<String, dynamic> acc, String accountId, int displayCode) async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để mua!')));
      return;
    }

    final price = _asDouble(acc['price']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận mua'),
        content: Text('Mua tài khoản #$displayCode giá ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mua ngay'))
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pushNamed(context, '/payment', arguments: PaymentFlowArgs(
        accountId: accountId, 
        displayCode: displayCode, 
        price: price, 
        rank: (acc['rank'] ?? '').toString(), 
        heroCount: (acc['hero_count'] ?? '').toString(), 
        skinCount: (acc['skin_count'] ?? '').toString()
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final uiSettings = context.watch<UiSettingsService>();
    final String bg = uiSettings.backgroundImage;
    final ImageProvider bgProvider = bg.startsWith('http') || bg.startsWith('https')
        ? NetworkImage(bg)
        : AssetImage(bg) as ImageProvider;

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: bgProvider, 
                fit: BoxFit.cover, 
                opacity: 0.78,
                filterQuality: kIsWeb ? FilterQuality.none : FilterQuality.low,
              )
            ),
            child: Column(
              children: [
                const TopMenu(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        _buildBannerSlider(uiSettings.banners),
                        FilterBar(
                          selectedRank: selectedRank, ranks: ranks, minPriceController: _minPriceController, maxPriceController: _maxPriceController,
                          onRankChanged: (v) => setState(() => selectedRank = v),
                          onSearch: () => setState(() => currentPage = 1),
                          onClear: () => setState(() { _minPriceController.clear(); _maxPriceController.clear(); selectedRank = 'Tất cả'; }),
                        ),
                        const Padding(padding: EdgeInsets.all(15), child: Align(alignment: Alignment.centerLeft, child: Text("DANH SÁCH TÀI KHOẢN", style: AppStyles.sectionTitleStyle))),
                        _buildAccountSections(),
                        const SizedBox(height: 50),
                        const HomeFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: isMobile ? 80 : null,
            top: isMobile ? null : 14,
            right: 14,
            child: const SafeArea(child: FloatingMusicButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlider(List<String> banners) {
    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true, 
        aspectRatio: 22 / 8, 
        enlargeCenterPage: true, 
        viewportFraction: 0.62,
      ),
      items: banners.map((i) {
        Widget imageWidget;
        if (i.startsWith('http') || i.startsWith('https')) {
          imageWidget = Image.network(
            i, 
            fit: BoxFit.cover, 
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.white10,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white30, size: 40),
              ),
            ),
          );
        } else {
          imageWidget = Image.asset(
            i, 
            fit: BoxFit.cover, 
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.white10,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white30, size: 40),
              ),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageWidget,
        );
      }).toList(),
    );
  }

  Widget _buildAccountSections() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Lỗi tải dữ liệu");
        List<Map<String, dynamic>>? data;
        if (snapshot.hasData && snapshot.data != null) {
          data = snapshot.data!.docs.map((doc) => {...(doc.data() as Map<String, dynamic>), 'docId': doc.id}).toList();
          CacheService.cacheAccounts(data);
        } else {
          data = CacheService.getCachedAccounts();
          if (data == null) return const Center(child: CircularProgressIndicator());
        }

        final filtered = data.where((d) {
          double min = double.tryParse(_minPriceController.text) ?? 0;
          double max = double.tryParse(_maxPriceController.text) ?? double.maxFinite;
          return (selectedRank == 'Tất cả' || d['rank'].toString().contains(selectedRank)) && _asDouble(d['price']) >= min && _asDouble(d['price']) <= max;
        }).toList();

        final available = filtered.where((d) => !_isSoldStatus(d['status'])).toList();
        final sold = filtered.where((d) => _isSoldStatus(d['status'])).toList();

        final int availableStartIndex = (currentPage - 1) * itemsPerPage;
        final pagedAvailable = available.skip(availableStartIndex).take(itemsPerPage).toList();

        final int soldStartIndex = (soldCurrentPage - 1) * soldItemsPerPage;
        final pagedSold = sold.skip(soldStartIndex).take(soldItemsPerPage).toList();

        return Column(children: [
          _buildGrid(pagedAvailable, availableStartIndex),
          _buildPagination((available.length / itemsPerPage).ceil(), currentPage, (p) => setState(() => currentPage = p)),
          if (sold.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Text('TÀI KHOẢN ĐÃ BÁN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)))),
            _buildGrid(pagedSold, soldStartIndex),
            _buildPagination((sold.length / soldItemsPerPage).ceil(), soldCurrentPage, (p) => setState(() => soldCurrentPage = p)),
          ]
        ]);
      },
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> docs, int start) {
    final sw = MediaQuery.of(context).size.width;
    int count = sw >= 1450 ? 4 : sw >= 1100 ? 3 : sw >= 760 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count, 
        childAspectRatio: sw < 450 ? 0.65 : 0.72,
        crossAxisSpacing: 15, 
        mainAxisSpacing: 15
      ),
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        // Lấy đúng ID từ trường 'id' của tài khoản (vd: 260001)
        final int displayId = int.tryParse(docs[i]['id']?.toString() ?? '') ?? (123001 + start + i);
        
        return AccountCard(
          acc: docs[i], 
          id: docs[i]['docId'] ?? '', 
          globalIndex: start + i, 
          onBuy: () => _handleBuyFromHome(docs[i], docs[i]['docId'] ?? '', displayId), 
          onDetail: (a, b, c) => Navigator.pushNamed(context, '/detail', arguments: {'docId': b, 'displayCode': c, 'account': a}),
        );
      },
    );
  }

  Widget _buildPagination(int total, int current, Function(int) onChange) {
    if (total <= 1) return const SizedBox.shrink();
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      ElevatedButton(onPressed: current > 1 ? () => onChange(current - 1) : null, child: const Text("Trước")),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Trang $current/$total", style: const TextStyle(color: Colors.white))),
      ElevatedButton(onPressed: current < total ? () => onChange(current + 1) : null, child: const Text("Sau")),
    ]);
  }
}
