import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'payment_screen.dart';
import '../widgets/ui_effects.dart';

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
  List<String> ranks = ['Tất cả', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'];

  int currentPage = 1;
  final int itemsPerPage = 12;
  int soldCurrentPage = 1;
  final int soldItemsPerPage = 4;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isSoldStatus(dynamic value) {
    final status = (value ?? '').toString().trim().toLowerCase();
    return status.contains('đã bán') || status.contains('da ban');
  }

  Map<String, dynamic> _sanitizeAccountData(Map<String, dynamic> account) {
    final safeData = Map<String, dynamic>.from(account);
    // Tránh lộ dữ liệu nhạy cảm ở danh sách công khai.
    safeData.remove('taikhoan');
    safeData.remove('matkhau');
    return safeData;
  }


  Future<void> _handleBuyFromHome(Map<String, dynamic> acc, String accountId, int displayCode) async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để mua tài khoản!')),
      );
      return;
    }

    final price = _asDouble(acc['price']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận mua tài khoản'),
        content: Text('Bạn có muốn mua tài khoản #$displayCode với giá ${price.toInt()}đ không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mua ngay')),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: PaymentFlowArgs(
        accountId: accountId,
        displayCode: displayCode,
        price: price,
        rank: (acc['rank'] ?? '').toString(),
        heroCount: (acc['hero_count'] ?? '').toString(),
        skinCount: (acc['skin_count'] ?? '').toString(),
      ),
    );
  }


  void _changeSoldPage(int nextPage) {
    final previousOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => soldCurrentPage = nextPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetOffset = previousOffset.clamp(0.0, maxScroll).toDouble();
      _scrollController.jumpTo(targetOffset);
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/anh-lien-quan-4k-thu-nguyen-ve-than-66.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.78,
                  filterQuality: FilterQuality.low,
                ),
              ),
              child: Column(
                children: [
                  _buildTopMenu(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          _buildBannerSlider(),
                          _buildFilterBar(),
                          const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "DANH SÁCH TÀI KHOẢN",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                              ),
                            ),
                          ),
                          _buildAccountSections(),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 14,
              right: 14,
              child: SafeArea(child: FloatingMusicButton()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/'),
                child: const AnimatedShopName(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Consumer<AuthService>(
                      builder: (context, authService, _) {
                        if (!authService.isLoggedIn) {
                          return Row(
                            children: [
                              _buildMenuItem('Đăng ký', null, () => Navigator.pushNamed(context, '/register')),
                              const SizedBox(width: 25),
                              _buildMenuItem('Đăng nhập', null, () => Navigator.pushNamed(context, '/login')),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              _buildMenuItem('Trang chủ', Icons.home, () => Navigator.pushNamed(context, '/')),
                              const SizedBox(width: 20),
                              _buildMenuItem('Lịch sử giao dịch', Icons.history, () {
                                Navigator.pushNamed(context, '/history');
                              }),
                              const SizedBox(width: 20),
                              const DepositMenuButton(),
                              const SizedBox(width: 30),

                              Row(
                                children: [
                                  Text(
                                    authService.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFF7ED),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                    ),
                                    child: PopupMenuButton(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      position: PopupMenuPosition.under,
                                      offset: const Offset(12, 10),
                                      constraints: const BoxConstraints(minWidth: 190),
                                      color: Colors.white.withValues(alpha: 0.16),
                                      surfaceTintColor: Colors.transparent,
                                      shadowColor: Colors.black.withValues(alpha: 0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                                      ),
                                      icon: const Icon(Icons.account_circle, color: Color(0xFFF97316), size: 30),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          child: const Text('Thông tin cá nhân', style: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600)),
                                          onTap: () {
                                            Navigator.pushNamed(context, '/user-detail');
                                          },
                                        ),
                                        PopupMenuItem(
                                          child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600)),
                                          onTap: () {
                                            context.read<AuthService>().logout();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Đăng xuất thành công!')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData? icon, VoidCallback onTap) {
    return HoverMenuItem(title: title, icon: icon, onTap: onTap);
  }

  // (Các phần code Banner, Filter, Grid... giữ nguyên)
  Widget _buildBannerSlider() {
    final List<String> imgList = ['assets/images/banner1.jpg', 'assets/images/banner2.jpg'];
    return ClipRect(
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          aspectRatio: 22 / 8,
          enlargeCenterPage: true,
          viewportFraction: 0.62,
        ),
        items: imgList
            .map(
              (item) => Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Image.asset(item, fit: BoxFit.cover, width: double.infinity, filterQuality: FilterQuality.low),
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Wrap(
        spacing: 20, runSpacing: 15, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Rank: ", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedRank,
                items: ranks.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() {
                  selectedRank = val!;
                  currentPage = 1;
                  soldCurrentPage = 1;
                }),
              ),
            ],
          ),
          _buildPriceInput("Giá từ:", _minPriceController),
          _buildPriceInput("đến:", _maxPriceController),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              currentPage = 1;
              soldCurrentPage = 1;
            }),
            icon: const Icon(Icons.search, size: 18, color: Colors.white),
            label: const Text("Lọc ngay", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput(String label, TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        SizedBox(width: 120, height: 40, child: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder(), hintText: "Nhập giá..."))),
      ],
    );
  }

  Widget _buildAccountSections() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          double minInput = double.tryParse(_minPriceController.text) ?? 0;
          double maxInput = double.tryParse(_maxPriceController.text) ?? double.maxFinite;
          bool matchRank = selectedRank == 'Tất cả' || (data['rank'] ?? '').toString().contains(selectedRank);
          double itemPrice = _asDouble(data['price']);
          return matchRank && itemPrice >= minInput && itemPrice <= maxInput;
        }).toList();

        final availableDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !_isSoldStatus(data['status']);
        }).toList();

        final soldDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _isSoldStatus(data['status']);
        }).toList();

        final totalPages = availableDocs.isEmpty ? 1 : (availableDocs.length / itemsPerPage).ceil();
        final soldTotalPages = soldDocs.isEmpty ? 1 : (soldDocs.length / soldItemsPerPage).ceil();
        if (currentPage > totalPages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => currentPage = totalPages);
            }
          });
        }
        if (soldCurrentPage > soldTotalPages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => soldCurrentPage = soldTotalPages);
            }
          });
        }

        int startIndex = (currentPage - 1) * itemsPerPage;
        int endIndex = (startIndex + itemsPerPage > availableDocs.length) ? availableDocs.length : startIndex + itemsPerPage;
        if (startIndex >= availableDocs.length) startIndex = 0;
        if (endIndex < startIndex) endIndex = startIndex;
        final displayDocs = availableDocs.sublist(startIndex, endIndex);

        int soldStartIndex = (soldCurrentPage - 1) * soldItemsPerPage;
        int soldEndIndex = (soldStartIndex + soldItemsPerPage > soldDocs.length)
            ? soldDocs.length
            : soldStartIndex + soldItemsPerPage;
        if (soldStartIndex >= soldDocs.length) soldStartIndex = 0;
        if (soldEndIndex < soldStartIndex) soldEndIndex = soldStartIndex;
        final soldDisplayDocs = soldDocs.sublist(soldStartIndex, soldEndIndex);

        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth >= 1450
            ? 4
            : screenWidth >= 1100
            ? 3
            : screenWidth >= 760
            ? 2
            : 1;

        final childAspectRatio = crossAxisCount == 1 ? 1.12 : 0.72;

        if (availableDocs.isEmpty && soldDocs.isEmpty) {
          return const Center(child: Text('Không có tài khoản nào'));
        }

        return Column(
          children: [
            if (displayDocs.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: displayDocs.length,
                itemBuilder: (context, index) {
                  final globalIndex = startIndex + index;
                  return _buildAccountCard(
                    _sanitizeAccountData(displayDocs[index].data() as Map<String, dynamic>),
                    displayDocs[index].id,
                    globalIndex,
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Không còn tài khoản đang bán theo bộ lọc hiện tại.'),
              ),
            _buildPagination(totalPages),
            const SizedBox(height: 26),
            if (soldDocs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TÀI KHOẢN ĐÃ BÁN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade300,
                    ),
                  ),
                ),
              ),
            if (soldDocs.isNotEmpty) const SizedBox(height: 10),
            if (soldDocs.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: soldDisplayDocs.length,
                itemBuilder: (context, index) {
                  final globalIndex = availableDocs.length + soldStartIndex + index;
                  return _buildAccountCard(
                    _sanitizeAccountData(soldDisplayDocs[index].data() as Map<String, dynamic>),
                    soldDisplayDocs[index].id,
                    globalIndex,
                  );
                },
              ),
            if (soldDocs.isNotEmpty) _buildSoldPagination(soldTotalPages),
          ],
        );
      },
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> acc, String id, int globalIndex) {
    final displayCode = 123001 + globalIndex;
    final isSold = _isSoldStatus(acc['status']);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade900,
              child: _PreviewableNetworkImage(imageUrl: (acc['image_url'] ?? '').toString()),
            ),
          ),
          Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Mã số: #$displayCode", style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("${acc['price']}đ", style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 5),
            Text("Rank: ${acc['rank']}", style: const TextStyle(fontSize: 14, color: Colors.black87)),
            Text("Tướng: ${acc['hero_count']} | Skin: ${acc['skin_count'] ?? 0}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const Spacer(),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/detail',
                    arguments: {
                      'docId': id,
                      'displayCode': displayCode,
                      'account': Map<String, dynamic>.from(acc),
                    },
                  ),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text("Chi tiết", style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSold ? null : () => _handleBuyFromHome(acc, id, displayCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSold ? Colors.grey : const Color(0xFFF97316),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(isSold ? 'Đã bán' : 'Mua', style: const TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ),
            ])
          ])))
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      ElevatedButton(
        onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
        child: const Text("Trước"),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          "Trang $currentPage/$totalPages",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
        ),
      ),
      ElevatedButton(
        onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
        child: const Text("Sau"),
      ),
    ]));
  }

  Widget _buildSoldPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: soldCurrentPage > 1 ? () => _changeSoldPage(soldCurrentPage - 1) : null,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
            child: const Text("Trước"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Đã bán: Trang $soldCurrentPage/$totalPages",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: soldCurrentPage < totalPages ? () => _changeSoldPage(soldCurrentPage + 1) : null,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
            child: const Text("Sau"),
          ),
        ],
      ),
    );
  }
}

class _PreviewableNetworkImage extends StatefulWidget {
  const _PreviewableNetworkImage({required this.imageUrl});

  final String imageUrl;

  @override
  State<_PreviewableNetworkImage> createState() => _PreviewableNetworkImageState();
}

class _PreviewableNetworkImageState extends State<_PreviewableNetworkImage> {
  bool _isHovered = false;

  void _openPreview() {
    if (widget.imageUrl.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 10,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(100),
                trackpadScrollCausesScale: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(widget.imageUrl, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _openPreview,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white),
            ),
            AnimatedOpacity(
              opacity: _isHovered ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: const Text(
                  'Preview',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





