import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cache_service.dart';
import 'account_card.dart';
import 'app_styles.dart';

class AccountSections extends StatelessWidget {
  final String selectedRank;
  final String minPriceText;
  final String maxPriceText;
  final int currentPage;
  final int itemsPerPage;
  final int soldCurrentPage;
  final int soldItemsPerPage;
  final Function(int) onPageChanged;
  final Function(int) onSoldPageChanged;
  final Function(Map<String, dynamic>, String, int) onBuy;

  const AccountSections({
    super.key,
    required this.selectedRank,
    required this.minPriceText,
    required this.maxPriceText,
    required this.currentPage,
    required this.itemsPerPage,
    required this.soldCurrentPage,
    required this.soldItemsPerPage,
    required this.onPageChanged,
    required this.onSoldPageChanged,
    required this.onBuy,
  });

  double _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  bool _isSoldStatus(dynamic value) => (value ?? '').toString().trim().toLowerCase().contains('đã bán');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(20), child: Text("Lỗi tải dữ liệu", style: TextStyle(color: Colors.white)));
        
        List<Map<String, dynamic>>? data;
        if (snapshot.hasData && snapshot.data != null) {
          data = snapshot.data!.docs.map((doc) => {...(doc.data() as Map<String, dynamic>), 'docId': doc.id}).toList();
          CacheService.cacheAccounts(data);
        } else {
          data = CacheService.getCachedAccounts();
          if (data == null) return const Center(child: CircularProgressIndicator());
        }

        final filtered = data.where((d) {
          double min = double.tryParse(minPriceText) ?? 0;
          double max = double.tryParse(maxPriceText) ?? double.maxFinite;
          return (selectedRank == 'Tất cả' || d['rank'].toString().contains(selectedRank)) && 
                 _asDouble(d['price']) >= min && _asDouble(d['price']) <= max;
        }).toList();

        final available = filtered.where((d) => !_isSoldStatus(d['status'])).toList();
        final sold = filtered.where((d) => _isSoldStatus(d['status'])).toList();

        return Column(
          children: [
            _buildGridSection(context, "DANH SÁCH TÀI KHOẢN", available, currentPage, itemsPerPage, onPageChanged, true),
            if (sold.isNotEmpty) ...[
              const SizedBox(height: 40),
              _buildGridSection(context, "TÀI KHOẢN ĐÃ BÁN", sold, soldCurrentPage, soldItemsPerPage, onSoldPageChanged, false),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGridSection(BuildContext context, String title, List<Map<String, dynamic>> docs, int current, int perPage, Function(int) onChange, bool isAvailable) {
    if (docs.isEmpty) return const SizedBox.shrink();
    
    final totalPages = (docs.length / perPage).ceil();
    int start = (current - 1) * perPage;
    if (start >= docs.length) start = 0;
    int end = start + perPage;
    if (end > docs.length) end = docs.length;
    final pagedDocs = docs.sublist(start, end);

    final sw = MediaQuery.of(context).size.width;
    int count = sw >= 1450 ? 4 : sw >= 1100 ? 3 : sw >= 760 ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(title, style: isAvailable ? AppStyles.sectionTitleStyle : const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(15),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: sw < 450 ? 0.94 : 0.72,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: pagedDocs.length,
          itemBuilder: (ctx, i) {
            final doc = pagedDocs[i];
            final globalIdx = start + i;
            return AccountCard(
              acc: doc,
              id: doc['docId'] ?? '',
              globalIndex: globalIdx,
              onBuy: () => onBuy(doc, doc['docId'] ?? '', 123001 + globalIdx),
              onDetail: (a, b, c) => Navigator.pushNamed(context, '/detail', arguments: {'docId': b, 'displayCode': c, 'account': a}),
            );
          },
        ),
        _buildPagination(totalPages, current, onChange),
      ],
    );
  }

  Widget _buildPagination(int total, int current, Function(int) onChange) {
    if (total <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(onPressed: current > 1 ? () => onChange(current - 1) : null, child: const Text("Trước")),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Trang $current/$total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ElevatedButton(onPressed: current < total ? () => onChange(current + 1) : null, child: const Text("Sau")),
      ],
    );
  }
}
