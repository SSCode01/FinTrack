import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/main_nav_screen.dart';
import 'models/money_transaction.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // 🔑 Register adapter (ONLY ONCE)
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MoneyTransactionAdapter());
  }

  // 📦 Open box
  await Hive.openBox<MoneyTransaction>('transactionsBox');

  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MainNavScreen(),
    );
  }
}
