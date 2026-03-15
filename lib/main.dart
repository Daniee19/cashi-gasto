import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/constants.dart';
import 'core/theme/theme.dart';
import 'core/widgets/main_shell.dart';
import 'features/auth/auth.dart';
import 'features/onboarding/onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formato de fechas en español
  await initializeDateFormatting('es_ES', null);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: CashiGastoApp()));
}

class CashiGastoApp extends ConsumerWidget {
  const CashiGastoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Cashi Gasto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: switch (authState) {
        AuthInitial() => const _SplashScreen(),
        AuthLoading() => const _SplashScreen(),
        AuthAuthenticated() => const MainShell(),
        AuthUnauthenticated() => const OnboardingPage(),
        AuthError() => const OnboardingPage(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.verticalGapLg,
            Text(
              'Cashi Gasto',
              style: AppTypography.displayMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
