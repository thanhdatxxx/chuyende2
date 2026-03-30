import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import thư viện gốc
import 'firebase_options.dart'; // File này do lệnh lúc nãy tự sinh ra

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/detail_screen.dart';

void main() async {
  // Bắt buộc phải có dòng này khi dùng hàm async trong main
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase cho đúng nền tảng đang chạy (Android/Web/Windows)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Liên Quân Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const HomeScreen(),
        // '/login': (context) => const LoginScreen(),
        // '/detail': (context) => const DetailScreen(),
      },
    );
  }
}