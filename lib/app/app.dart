import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/sms_settings_provider.dart';
import 'routes.dart';
import 'theme.dart';

class CashiGastoApp extends ConsumerWidget {
  const CashiGastoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializar servicio de detección automática si está habilitado
    ref.watch(smsSettingsNotifierProvider);

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
