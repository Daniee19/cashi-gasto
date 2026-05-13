import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'theme.dart';

class CashiGastoApp extends ConsumerWidget {
  const CashiGastoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Add theme mode provider for dark mode toggle

    return MaterialApp.router(
      title: 'Cashi Gasto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRoutes.router,
    );
  }
}
