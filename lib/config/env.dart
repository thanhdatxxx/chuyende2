class Env {
  static const List<String> geminiApiKeys = [
    'AIzaSyB12xD9-vcvmx4veNKB6Ri8lQdGVAXJFYI',
    'AIzaSyC2KYmCkYu8oD2amKlcnsk0WkkiOFQlSj8',
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
