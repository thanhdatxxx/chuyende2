# CHUYÊN ĐỀ 2 - ỨNG DỤNG BÁN TÀI KHOẢN LIÊN QUÂN

## 📌 Giới thiệu nhóm

| STT | Họ và Tên         | Mã Sinh Viên |
|-----|------------------|-------------|
| 1   | Nguyễn Thành Đạt | 20221080   |
| 2   | Nguyễn Tấn Dũng  | 20221006   |
| 3   | Quàng Văn Thiếm  | 20221002   |
| 4   | Ngô Anh Quân     | 20221071   |

---

## 📱 Giới thiệu dự án

**Tên dự án:** Ứng dụng bán tài khoản game Liên Quân

### 🔹 Mô tả:
Ứng dụng được xây dựng nhằm hỗ trợ người dùng mua bán tài khoản game **Liên Quân Mobile** một cách nhanh chóng, tiện lợi và an toàn. Người dùng có thể dễ dàng tìm kiếm, lựa chọn tài khoản phù hợp với nhu cầu của mình.

### 🔹 Mục tiêu:
- Cung cấp nền tảng mua bán tài khoản game uy tín
- Tối ưu trải nghiệm người dùng trên thiết bị di động
- Đảm bảo tính bảo mật và minh bạch trong giao dịch

### 🔹 Chức năng chính:
- Đăng ký / Đăng nhập tài khoản
- Xem danh sách tài khoản game
- Tìm kiếm và lọc tài khoản theo giá, rank, tướng
- Xem chi tiết tài khoản
- Đặt mua tài khoản
- Quản lý tài khoản cá nhân

### 🔹 Công nghệ sử dụng:
- Flutter (Mobile App)
- Dart
- Firebase / API Backend (tuỳ triển khai)

🚀 Hướng dẫn khởi chạy dự án
Để chạy ứng dụng này trên máy tính cá nhân hoặc thiết bị di động, vui lòng thực hiện theo các bước sau:

1. Chuẩn bị môi trường
Trước khi bắt đầu, hãy đảm bảo máy tính đã cài đặt:

Flutter SDK: Phiên bản mới nhất (tải tại flutter.dev).

Editor: VS Code hoặc Android Studio (đã cài plugin Flutter & Dart).

Git: Để thực hiện việc clone mã nguồn từ kho lưu trữ.

2. Cách lấy dự án về máy (Clone Project)
Mở terminal (hoặc CMD) trên máy tính và chạy lệnh sau:

Bash
git clone https://github.com/vthiem2k4/ten-du-an-cua-ban.git
(Lưu ý: Thay đường dẫn link GitHub thật của nhóm bạn vào đây)

Sau khi tải xong, di chuyển vào thư mục dự án:

Bash
cd ten-du-an-cua-ban
3. Cài đặt các thư viện phụ thuộc
Dự án sử dụng các gói như image_picker, intl, uuid, sqflite... Bạn cần tải chúng về bằng lệnh:

Bash
flutter pub get
4. Kết nối thiết bị
Dùng máy ảo: Mở Android Emulator hoặc iOS Simulator.

Dùng máy thật: Kết nối điện thoại qua cáp USB và bật chế độ "USB Debugging".

Kiểm tra thiết bị đã sẵn sàng chưa bằng lệnh:

Bash
flutter devices
5. Khởi chạy ứng dụng
Cuối cùng, chạy lệnh sau để khởi động ứng dụng:

Bash
flutter run


