import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../widgets/app_styles.dart';
import '../widgets/account_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/home_footer.dart';
import '../widgets/ui_effects.dart';
import 'payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mua ngay'))],
      ),
    );

    if (confirmed == true) {
      Navigator.pushNamed(context, '/payment', arguments: PaymentFlowArgs(accountId: accountId, displayCode: displayCode, price: price, rank: (acc['rank'] ?? '').toString(), heroCount: (acc['hero_count'] ?? '').toString(), skinCount: (acc['skin_count'] ?? '').toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/anh-lien-quan-4k-thu-nguyen-ve-than-66.jpg'), fit: BoxFit.cover, opacity: 0.78)),
            child: Column(
              children: [
                _buildTopMenu(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        _buildBannerSlider(),
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
          const Positioned(top: 14, right: 14, child: SafeArea(child: FloatingMusicButton())),
        ],
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 1200), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: [
            InkWell(onTap: () => Navigator.pushNamed(context, '/'), child: const Row(children: [Icon(Icons.gamepad, color: AppStyles.primaryColor, size: 28), SizedBox(width: 8), AnimatedShopName()])),
            const Spacer(),
            _buildAuthMenu(),
          ]),
        ),
      ),
    );
  }

  Widget _buildAuthMenu() {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          return Row(children: [
            _buildMenuItem('Đăng ký', null, () => Navigator.pushNamed(context, '/register')),
            const SizedBox(width: 25),
            _buildMenuItem('Đăng nhập', null, () => Navigator.pushNamed(context, '/login')),
          ]);
        }
        return Row(children: [
          _buildMenuItem('Trang chủ', Icons.home, () {}),
          if (!auth.isAdmin) ...[
            const SizedBox(width: 20),
            _buildMenuItem('Lịch sử', Icons.history, () => Navigator.pushNamed(context, '/history')),
            const SizedBox(width: 20),
            const DepositMenuButton(),
          ],
          const SizedBox(width: 30),
          UserMenuButton(auth: auth),
        ]);
      },
    );
  }

  Widget _buildMenuItem(String t, IconData? i, VoidCallback o) => HoverMenuItem(title: t, icon: i, onTap: o);

  Widget _buildBannerSlider() {
    final List<String> imgs = ['assets/images/banner1.jpg', 'assets/images/banner2.jpg', 'assets/images/banner3.jpg'];
    return CarouselSlider(
      options: CarouselOptions(autoPlay: true, aspectRatio: 22 / 8, enlargeCenterPage: true, viewportFraction: 0.62),
      items: imgs.map((i) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset(i, fit: BoxFit.cover, width: double.infinity))).toList(),
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

        return Column(children: [
          _buildGrid(available, (currentPage - 1) * itemsPerPage),
          _buildPagination((available.length / itemsPerPage).ceil(), currentPage, (p) => setState(() => currentPage = p)),
          if (sold.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Text('TÀI KHOẢN ĐÃ BÁN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)))),
            _buildGrid(sold, (soldCurrentPage - 1) * soldItemsPerPage),
          ]
        ]);
      },
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> docs, int start) {
    final sw = MediaQuery.of(context).size.width;
    int count = sw >= 1450 ? 4 : sw >= 1100 ? 3 : sw >= 760 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, childAspectRatio: sw < 450 ? 0.94 : 0.72, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: docs.length,
      itemBuilder: (ctx, i) => AccountCard(
        acc: docs[i], id: docs[i]['docId'] ?? '', globalIndex: start + i, 
        onBuy: () => _handleBuyFromHome(docs[i], docs[i]['docId'] ?? '', 123001 + start + i), 
        onDetail: (a, b, c) => Navigator.pushNamed(context, '/detail', arguments: {'docId': b, 'displayCode': c, 'account': a}),
      ),
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
