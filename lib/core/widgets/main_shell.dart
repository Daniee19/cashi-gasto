import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../features/chatbot/presentation/chatbot_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/goals/presentation/goals_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../theme/theme.dart';

/// Provider para el índice de navegación actual
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Shell principal con navegación inferior
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const List<Widget> _pages = [
    DashboardPage(),
    ReportsPage(),
    GoalsPage(),
    ChatbotPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: AppColors.shadowLight,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: GNav(
              gap: AppSpacing.sm,
              activeColor: AppColors.primary,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: AppColors.surfaceVariant,
              color: AppColors.grey400,
              selectedIndex: currentIndex,
              onTabChange: (index) {
                ref.read(navigationIndexProvider.notifier).state = index;
              },
              tabs: const [
                GButton(
                  icon: Icons.home_outlined,
                  text: 'Inicio',
                ),
                GButton(
                  icon: Icons.bar_chart_outlined,
                  text: 'Reportes',
                ),
                GButton(
                  icon: Icons.flag_outlined,
                  text: 'Metas',
                ),
                GButton(
                  icon: Icons.chat_bubble_outline,
                  text: 'Chat',
                ),
                GButton(
                  icon: Icons.settings_outlined,
                  text: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTransactionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.arrow_downward,
                  color: AppColors.income,
                ),
              ),
              title: const Text('Registrar ingreso'),
              subtitle: const Text('Añadir dinero recibido'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionPage(
                      type: TransactionType.income,
                    ),
                  ),
                );
              },
            ),
            AppSpacing.verticalGapSm,
            ListTile(
              leading: Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: AppColors.expense,
                ),
              ),
              title: const Text('Registrar gasto'),
              subtitle: const Text('Añadir dinero gastado'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionPage(
                      type: TransactionType.expense,
                    ),
                  ),
                );
              },
            ),
            AppSpacing.verticalGapMd,
          ],
        ),
      ),
    );
  }
}
