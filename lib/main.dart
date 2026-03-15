import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/widgets/main_shell.dart';

void main() {
  runApp(const ProviderScope(child: CashiGastoApp()));
}

class CashiGastoApp extends StatelessWidget {
  const CashiGastoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashi Gasto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
