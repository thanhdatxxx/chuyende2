class Env {
  static const List<String> geminiApiKeys = [
    'AIzaSyApBAqtRnfUFg09JyYJHtuYQPlTjcXZSQ8',
    'AIzaSyBIsnNKqC_RUqf6TudR810lv0hAEsotT0c',
    'AIzaSyAi6ZYpu7mq5p6Z3QF7H3oLle8HSXe7SHg',
    'AIzaSyA7xTvMucvj3S0h0wWxfkbSnKZ_vhkQniM',
    'AIzaSyA-zRL8VpgPuxkcIDed2YMVVKElYiLuUgY',
  ];

  // Quản lý index key đang hoạt động
  static int _currentKeyIndex = 0;

  // Lấy key hiện tại dựa trên index
  static String get geminiApiKey => geminiApiKeys[_currentKeyIndex];

  // Chuyển sang key tiếp theo khi key hiện tại bị lỗi/hết hạn mức
  static void nextKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % geminiApiKeys.length;
    print("🔄 Gemini: Đã chuyển sang API Key dự phòng (Index: $_currentKeyIndex)");
  }
}
