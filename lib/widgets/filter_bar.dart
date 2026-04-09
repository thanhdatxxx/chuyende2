import 'package:flutter/material.dart';
import 'app_styles.dart';

class FilterBar extends StatelessWidget {
  final String selectedRank;
  final List<String> ranks;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final Function(String) onRankChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const FilterBar({
    super.key,
    required this.selectedRank,
    required this.ranks,
    required this.minPriceController,
    required this.maxPriceController,
    required this.onRankChanged,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 1200),
        decoration: AppStyles.glassContainerDecoration,
        child: Wrap(
          spacing: 20,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Dropdown Rank
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedRank,
                  dropdownColor: AppStyles.secondaryColor,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppStyles.primaryColor),
                  items: ranks.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => onRankChanged(val!),
                ),
              ),
            ),
            // Input Giá
            _buildPriceInput("Giá từ:", minPriceController),
            _buildPriceInput("đến:", maxPriceController),
            // Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, size: 20, color: Colors.white),
                  label: const Text("Lọc", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh, color: AppStyles.textColorSecondary),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput(String label, TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppStyles.textColorSecondary)),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppStyles.primaryColor)),
              hintText: "Nhập giá...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
