import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _minPriceController = TextEditingController(text: "");
  final TextEditingController _maxPriceController = TextEditingController(text: "");
  // --- TRẠNG THÁI BỘ LỌC ---
  String selectedRank = 'Tất cả';
  RangeValues selectedPriceRange = const RangeValues(0, 2000000);
  List<String> ranks = ['Tất cả', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'];

  // --- TRẠNG THÁI PHÂN TRANG ---
  int currentPage = 1;
  final int itemsPerPage = 12; // Thiết lập 4x3 = 12 item mỗi trang

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            setState(() {
              selectedRank = 'Tất cả';
              selectedPriceRange = const RangeValues(0, 2000000);
              currentPage = 1;
            });
          },
        ),
        title: const Text(
          'SHOP ACC LIÊN QUÂN',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text("Đăng nhập", style: TextStyle(color: Colors.white)),
          ),
          const VerticalDivider(color: Colors.white54, indent: 12, endIndent: 12),
          TextButton(
            onPressed: () => print("Mở trang Đăng ký"),
            child: const Text("Đăng ký", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Slide ảnh banner
            _buildBannerSlider(),

            // 2. Bộ lọc Rank và Giá
            _buildFilterBar(),

            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "DANH SÁCH TÀI KHOẢN",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
            ),

            // 3. Grid danh sách Acc (Hiển thị 4 cột)
            _buildAccountGrid(),

            // 4. Nút phân trang
            _buildPagination(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: SLIDE BANNER ---
  Widget _buildBannerSlider() {
    final List<String> imgList = [
      'assets/images/banner1.jpg',
      'assets/images/banner2.jpg',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        aspectRatio: 16 / 7,
        enlargeCenterPage: true,
        viewportFraction: 0.8,
      ),
      items: imgList.map((item) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Image.asset(
            item,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 50),
            ),
          ),
        ),
      )).toList(),
    );
  }

  // --- WIDGET: BỘ LỌC ---
  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 15,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 1. Lọc theo Rank
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Rank: ", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedRank,
                items: ranks.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() {
                  selectedRank = val!;
                  currentPage = 1;
                }),
              ),
            ],
          ),

          // 2. Nhập Giá tối thiểu
          _buildPriceInput("Giá từ:", _minPriceController),

          // 3. Nhập Giá tối đa
          _buildPriceInput("đến:", _maxPriceController),

          // 4. Nút Lọc (Để kích hoạt tìm kiếm)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                // Chỉ cần setState trống ở đây, các biến minInput/maxInput
                // ở trên sẽ tự đọc dữ liệu mới nhất từ Controller khi build lại.
                currentPage = 1;
              });
              print("Đang lọc giá từ ${_minPriceController.text} đến ${_maxPriceController.text}");
            },
            icon: const Icon(Icons.search, size: 18, color: Colors.white),
            label: const Text("Lọc ngay", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

// Hàm phụ để tạo ô nhập giá nhanh
  Widget _buildPriceInput(String label, TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(),
              hintText: "Nhập giá...",
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // --- WIDGET: GRID TÀI KHOẢN ---
  Widget _buildAccountGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

// 1. Logic Lọc dữ liệu
        var filteredDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;

          // Lấy giá trị từ Controller
          String minText = _minPriceController.text.trim();
          String maxText = _maxPriceController.text.trim();

          // Chuyển sang số, nếu trống thì gán giá trị mặc định cực thấp/cực cao
          double minInput = double.tryParse(minText) ?? 0;
          double maxInput = double.tryParse(maxText) ?? double.maxFinite; // Vô hạn

          // Lọc theo Rank
          bool matchRank = selectedRank == 'Tất cả' || data['rank'] == selectedRank;

          // Lọc theo Giá (Ép kiểu toDouble để tránh lỗi logic Firestore)
          double itemPrice = (data['price'] ?? 0).toDouble();
          bool matchPrice = itemPrice >= minInput && itemPrice <= maxInput;

          return matchRank && matchPrice;
        }).toList();
        // 2. Logic Phân trang (Cắt lấy 12 item)
        int startIndex = (currentPage - 1) * itemsPerPage;
        int endIndex = startIndex + itemsPerPage;
        if (startIndex >= filteredDocs.length) return const Center(child: Text("Không có tài khoản nào"));
        if (endIndex > filteredDocs.length) endIndex = filteredDocs.length;

        var displayDocs = filteredDocs.sublist(startIndex, endIndex);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4 cột
            childAspectRatio: 0.68, // Tỉ lệ để cân đối 3 hàng
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: displayDocs.length,
          itemBuilder: (context, index) {
            var acc = displayDocs[index].data() as Map<String, dynamic>;
            String id = displayDocs[index].id;
            return _buildAccountCard(acc, id);
          },
        );
      },
    );
  }

  // --- WIDGET: THẺ TÀI KHOẢN ---
  Widget _buildAccountCard(Map<String, dynamic> acc, String id) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Image.network(
                acc['image_url'] ?? '',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${acc['price']}đ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 5),
                  Text("Rank: ${acc['rank']}", style: const TextStyle(fontSize: 15)),
                  Text("Tướng: ${acc['hero_count']} | Skin: ${acc['skin_count'] ?? 0}", style: const TextStyle(fontSize: 15)),
                  Text("Mô tả: ${acc['description']}", style: const TextStyle(fontSize: 15)),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => print("Chi tiết: $id"),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: const Text("Chi tiết", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => print("Mua: $id"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Mua ngay", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET: THANH PHÂN TRANG ---
  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
            child: const Text("Trước"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("Trang $currentPage", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white,)),
          ),
          ElevatedButton(
            onPressed: () => setState(() => currentPage++), // Bạn có thể thêm giới hạn max page dựa vào data length
            child: const Text("Sau"),
          ),
        ],
      ),
    );
  }
}