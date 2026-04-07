import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/background_music_service.dart';
import 'services/cache_service.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/detail_user.dart';
import 'screens/history_screen.dart';
import 'screens/bank_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/history_transaction_detail_screen.dart';
import 'widgets/ui_effects.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const bool _showContactButton = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BackgroundMusicService()),
      ],
      child: MaterialApp(
        title: 'Shop Liên Quân Mobile',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                child,
                if (_showContactButton)
                  const Positioned(
                    right: 12,
                    bottom: 12,
                    child: SafeArea(
                      child: SizedBox(width: 104, child: ExpandableContactButton()),
                    ),
                  ),
              ],
            ),
          );
        },
        theme: ThemeData(
          primarySwatch: Colors.orange,
          scaffoldBackgroundColor: const Color(0xFF0A0E21),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/detail': (context) => const AccountDetailPage(),
          '/user-detail': (context) => const DetailUserPage(),
          '/history': (context) => const HistoryScreen(),
          '/history-transaction-detail': (context) => const HistoryTransactionDetailScreen(),
          '/payment': (context) => const PaymentCheckoutScreen(),
          '/bank': (context) => const BankScreen(),
          '/bank-card': (context) => const BankScreen(initialMode: DepositMode.card),
          '/bank-atm': (context) => const BankScreen(initialMode: DepositMode.atm),
        },
      ),
    );
  }
}
