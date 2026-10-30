import 'package:feedgo_app/models/cart_item.dart';
import 'package:feedgo_app/models/price_type.dart';
import 'package:feedgo_app/models/product.dart';
import 'package:feedgo_app/models/transaction_record.dart';
import 'package:feedgo_app/screens/main_screen.dart';
import 'package:feedgo_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

final class LogObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('PROVIDER FAIL: ${context.provider} -> $error\n$stackTrace');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Adapter Registration
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(TransactionRecordAdapter());
  Hive.registerAdapter(CartItemAdapter());
  Hive.registerAdapter(PriceTypeAdapter());

  // Buka box data
  await Hive.openBox<Product>('products_box');
  await Hive.openBox<TransactionRecord>('transactions_box');

  runApp(ProviderScope(observers: [LogObserver()], child: FeedGoApp()));
}

class FeedGoApp extends StatelessWidget {
  const FeedGoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeedGO!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
