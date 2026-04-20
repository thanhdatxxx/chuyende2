import 'dart:ui' as ui;
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/ui_effects.dart';
import '../widgets/app_styles.dart';
import '../widgets/home_footer.dart';
import '../widgets/top_menu.dart';

enum StatFilter { day, month, year, all }

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  StatFilter _currentFilter = StatFilter.all;

  bool _isDateInRange(DateTime date) {
    final now = DateTime.now();
    switch (_currentFilter) {
      case StatFilter.day:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case StatFilter.month:
        return date.year == now.year && date.month == now.month;
      case StatFilter.year:
        return date.year == now.year;
      case StatFilter.all:
        return true;
    }
  }

  String _getFilterText() {
    switch (_currentFilter) {
      case StatFilter.day: return "Hôm nay";
      case StatFilter.month: return "Tháng này";
      case StatFilter.year: return "Năm nay";
      case StatFilter.all: return "Tất cả thời gian";
    }
  }

  Future<void> _exportToExcel(List<QueryDocumentSnapshot> docs, double totalRevenue, double totalDeposit, int soldAccCount) async {
    try {
      final now = DateTime.now();
      final suggestedFileName = "BaoCao_Shop_${_getFilterText().replaceAll(' ', '_')}_${DateFormat('ddMMyyyy').format(now)}.csv";
      
      String csv = "\uFEFF"; 
      
      csv += "BÁO CÁO THỐNG KÊ DOANH THU & GIAO DỊCH\n";
      csv += "Đơn vị:,Shop Liên Quân Mobile\n";
      csv += "Phạm vi:,Thống kê ${_getFilterText()}\n";
      csv += "Thời điểm xuất:,${DateFormat('dd/MM/yyyy HH:mm').format(now)}\n\n";

      csv += "--- TỔNG QUAN DOANH THU ---\n";
      csv += "Hạng mục,Giá trị\n";
      csv += "Doanh thu bán tài khoản,${totalRevenue.toInt()} VNĐ\n";
      csv += "Số lượng acc đã bán,$soldAccCount acc\n";
      csv += "Tiền người dùng nạp,${totalDeposit.toInt()} VNĐ\n";
      csv += "Lợi nhuận ròng,${totalRevenue.toInt()} VNĐ\n\n";

      csv += "--- CHI TIẾT GIAO DỊCH ---\n";
      csv += "STT,Loại,Người dùng,Số tiền,Nội dung/Mã Acc,Thời gian\n";
      
      for (int i = 0; i < docs.length; i++) {
        final data = docs[i].data() as Map<String, dynamic>;
        final isPurchase = data['type'] == 'purchase';
        final type = isPurchase ? 'Mua acc' : 'Nạp tiền';
        final user = (data['user_name'] ?? 'N/A').toString().replaceAll(',', ' ');
        final amount = (data['amount'] ?? 0).toInt();
        final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? now;
        final timeStr = " ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}";
        
        String detail = "";
        if (isPurchase) {
          final accCode = data['account_code'] ?? 'N/A';
          detail = "Mã acc: #$accCode";
        } else {
          detail = (data['method'] == 'card' ? 'Nạp thẻ cào' : 'Nạp ví ATM/Momo');
        }
        
        csv += "${i + 1},$type,$user,$amount,$detail,$timeStr\n";
      }

      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", suggestedFileName)
        ..click();
      
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất báo cáo: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'BÁO CÁO & THỐNG KÊ HỆ THỐNG',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: 2),
                ),
              ),
            ),
            
            _buildFilterBar(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('1. Doanh thu & Dòng tiền (${_getFilterText()})', Icons.monetization_on),
                  _buildRevenueSection(),
                  const SizedBox(height: 40),

                  _buildSectionHeader('2. Giao dịch mới nhất (${_getFilterText()})', Icons.history),
                  _buildRecentTransactions(),
                  const SizedBox(height: 40),

                  _buildSectionHeader('3. Kho hàng (Tài khoản)', Icons.inventory_2),
                  _buildProductSection(),
                  const SizedBox(height: 40),

                  _buildSectionHeader('4. Người dùng & Số dư', Icons.people_alt),
                  _buildUserSection(),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: StatFilter.values.map((filter) {
            bool isSelected = _currentFilter == filter;
            String label = "";
            switch (filter) {
              case StatFilter.day: label = "Hôm nay"; break;
              case StatFilter.month: label = "Tháng này"; break;
              case StatFilter.year: label = "Năm nay"; break;
              case StatFilter.all: label = "Tất cả"; break;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (val) { if (val) setState(() => _currentFilter = filter); },
                selectedColor: AppStyles.primaryColor,
                backgroundColor: const Color(0xFF1E293B),
                labelStyle: TextStyle(
                  color: Colors.white, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), 
                  side: BorderSide(color: isSelected ? AppStyles.primaryColor : Colors.white24)
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 10),
      child: Row(
        children: [
          Icon(icon, color: AppStyles.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRevenueSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('history').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        double totalRevenue = 0;
        double totalDeposit = 0;
        int soldAccCount = 0;
        double cardRev = 0;
        double atmRev = 0;
        Map<int, double> monthlyRev = {};
        final now = DateTime.now();

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['created_at'] as Timestamp?)?.toDate() ?? now;
          return _isDateInRange(date);
        }).toList();

        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          final type = data['type'] ?? '';
          final date = (data['created_at'] as Timestamp?)?.toDate() ?? now;

          if (type == 'purchase') {
            totalRevenue += amount;
            soldAccCount++;
            if (date.year == now.year) {
              monthlyRev[date.month] = (monthlyRev[date.month] ?? 0) + amount;
            }
          } else if (type == 'deposit') {
            totalDeposit += amount;
            if (data['method'] == 'card') {
              cardRev += amount;
            } else {
              atmRev += amount;
            }
          }
        }

        return Column(
          children: [
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildStatCard('TỔNG DOANH THU', currencyFormat.format(totalRevenue), Colors.green, Icons.trending_up, isFullWidth: true),
                _buildStatCard('ACC ĐÃ BÁN', soldAccCount.toString(), Colors.purpleAccent, Icons.shopping_cart),
                _buildStatCard('LỢI NHUẬN', currencyFormat.format(totalRevenue), Colors.blue, Icons.account_balance_wallet),
                _buildStatCard('TỔNG TIỀN NẠP', currencyFormat.format(totalDeposit), Colors.orange, Icons.add_card),
              ],
            ),
            const SizedBox(height: 25),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: ElevatedButton.icon(
                onPressed: () => _exportToExcel(filteredDocs, totalRevenue, totalDeposit, soldAccCount),
                icon: const Icon(Icons.download),
                label: const Text('XUẤT BÁO CÁO EXCEL', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isWide ? 3 : 0,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biến động doanh thu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 30),
                            SizedBox(height: 200, child: _SimpleLineChart(monthlyData: monthlyRev)),
                          ],
                        ),
                      ),
                    ),
                    if (isWide) const SizedBox(width: 20) else const SizedBox(height: 20),
                    Expanded(
                      flex: isWide ? 2 : 0,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nguồn nạp tiền', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 30),
                            _buildPaymentProgress('Thẻ cào', totalDeposit > 0 ? cardRev / totalDeposit : 0, Colors.orange),
                            const SizedBox(height: 25),
                            _buildPaymentProgress('ATM / Momo', totalDeposit > 0 ? atmRev / totalDeposit : 0, Colors.purpleAccent),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('history').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final now = DateTime.now();

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['created_at'] as Timestamp?)?.toDate() ?? now;
          return _isDateInRange(date);
        }).take(15).toList();

        if (filteredDocs.isEmpty) {
          return const GlassContainer(padding: EdgeInsets.all(40), child: Center(child: Text("Không có giao dịch", style: TextStyle(color: Colors.white38))));
        }

        return GlassContainer(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: filteredDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isPurchase = data['type'] == 'purchase';
              final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? now;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (isPurchase ? Colors.red : Colors.green).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(isPurchase ? Icons.shopping_bag : Icons.account_balance_wallet, color: isPurchase ? Colors.redAccent : Colors.greenAccent, size: 24),
                ),
                title: Text(data['user_name'] ?? 'Ẩn danh', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('dd/MM HH:mm').format(createdAt), style: const TextStyle(color: Colors.white54)),
                trailing: Text('${isPurchase ? "-" : "+"}${currencyFormat.format(data['amount'] ?? 0)}', 
                  style: TextStyle(color: isPurchase ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.w900)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildProductSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final now = DateTime.now();
        final docs = snapshot.data!.docs;
        int totalCount = docs.length;
        int soldCount = 0;
        int oldStockCount = 0;
        Map<String, int> rankStats = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          final isSold = status.contains('đã bán') || status.contains('sold') || status.contains('da ban');
          final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? now;
          final rank = (data['rank'] ?? 'Khác').toString();

          if (isSold) {
            soldCount++;
            rankStats[rank] = (rankStats[rank] ?? 0) + 1;
          } else {
            if (now.difference(createdAt).inDays > 30) {
              oldStockCount++;
            }
          }
        }

        String bestSellingRank = "Chưa có";
        if (rankStats.isNotEmpty) {
          bestSellingRank = rankStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        }

        double sellRate = totalCount > 0 ? (soldCount / totalCount * 100) : 0;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildStatCard('TỔNG TÀI KHOẢN', totalCount.toString(), Colors.cyan, Icons.storage, 
                onTap: () => Navigator.pushNamed(context, '/admin-accounts')),
            _buildStatCard('TỶ LỆ BÁN RA', '${sellRate.toStringAsFixed(1)}%', Colors.pinkAccent, Icons.pie_chart),
            _buildStatCard('RANK BÁN CHẠY', bestSellingRank, Colors.orangeAccent, Icons.local_fire_department),
            _buildStatCard('TỒN KHO >30 NGÀY', oldStockCount.toString(), Colors.amber, Icons.hourglass_bottom),
          ],
        );
      },
    );
  }

  Widget _buildUserSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('user').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        int totalUsers = snapshot.data!.docs.length;
        double systemDebtValue = snapshot.data!.docs.fold(0.0, (acc, doc) => acc + ((doc.data() as Map)['balance'] ?? 0).toDouble());

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildStatCard('THÀNH VIÊN', totalUsers.toString(), Colors.indigoAccent, Icons.person_add, 
                onTap: () => Navigator.pushNamed(context, '/admin-users')),
            _buildStatCard('SỐ DƯ HỆ THỐNG', currencyFormat.format(systemDebtValue), Colors.teal, Icons.account_balance_wallet, width: 400),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {double width = 275, bool isFullWidth = false, VoidCallback? onTap}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = MediaQuery.of(context).size.width;
        double effectiveWidth = isFullWidth ? double.infinity : (screenWidth < 600 ? (screenWidth - 60) : width);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: effectiveWidth,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15)],
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.bold)),
                            if (onTap != null) ...[
                              const SizedBox(width: 5),
                              Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white.withValues(alpha: 0.3)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPaymentProgress(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            Text('${(percent * 100).toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: percent, minHeight: 10, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  final Map<int, double> monthlyData;
  const _SimpleLineChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _LineChartPainter(monthlyData));
  }
}

class _LineChartPainter extends CustomPainter {
  final Map<int, double> monthlyData;
  _LineChartPainter(this.monthlyData);

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyData.isEmpty) return;

    double leftMargin = 45.0;
    double bottomMargin = 25.0;
    double chartWidth = size.width - leftMargin;
    double chartHeight = size.height - bottomMargin;

    final paint = Paint()..color = AppStyles.primaryColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..shader = ui.Gradient.linear(Offset(size.width / 2, 0), Offset(size.width / 2, chartHeight), [AppStyles.primaryColor.withValues(alpha: 0.3), Colors.transparent]);
    
    double maxVal = monthlyData.values.fold(0, (max, v) => v > max ? v : max);
    if (maxVal == 0) maxVal = 1;

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    final List<double> yLabels = [0, maxVal / 2, maxVal];
    for (var val in yLabels) {
      String labelText = val >= 1000000 ? '${(val / 1000000).toStringAsFixed(1)}M' : val >= 1000 ? '${(val / 1000).toInt()}K' : val.toInt().toString();
      textPainter.text = TextSpan(text: labelText, style: const TextStyle(color: Colors.white38, fontSize: 10));
      textPainter.layout();
      
      double yPos = chartHeight - (val / maxVal * chartHeight * 0.8);
      textPainter.paint(canvas, Offset(0, yPos - 7));
      
      final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
      canvas.drawLine(Offset(leftMargin, yPos), Offset(size.width, yPos), gridPaint);
    }

    final points = <Offset>[];
    final stepX = chartWidth / 11;
    for (int i = 1; i <= 12; i++) {
      double val = monthlyData[i] ?? 0;
      points.add(Offset(leftMargin + (i - 1) * stepX, chartHeight - (val / maxVal * chartHeight * 0.8)));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    final fillPath = Path.from(path)..lineTo(points.last.dx, chartHeight)..lineTo(leftMargin, chartHeight)..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = Colors.white;
    for (var p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 2, paint);
    }
    
    for (int i = 1; i <= 12; i += 2) {
      textPainter.text = TextSpan(text: 'T$i', style: const TextStyle(color: Colors.white38, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin + (i - 1) * stepX - 5, chartHeight + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
