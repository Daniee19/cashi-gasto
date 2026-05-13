import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/utils.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../transactions/presentation/providers/transactions_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState is AuthAuthenticated
        ? authState.user.fullName.split(' ').first
        : 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userFundProvider);
            ref.invalidate(recentTransactionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.verticalGapMd,
                _Header(userName: userName),
                AppSpacing.verticalGapMd,
                const _BalanceCard(),
                AppSpacing.verticalGapLg,
                const _QuickAccess(),
                AppSpacing.verticalGapLg,
                const _RecentTransactions(),
                AppSpacing.verticalGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String userName;

  const _Header({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
          ),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        AppSpacing.horizontalGapSm,
        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $userName',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormatter.fullDate(DateTime.now()),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        // Bell
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundAsync = ref.watch(userFundProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: fundAsync.when(
        data: (fund) {
          final total = fund?.total ?? 0;
          final isNegative = total < 0;

          return Column(
            children: [
              // Balance label
              Text(
                'Balance total',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.verticalGapSm,
              // Balance amount
              Text(
                CurrencyFormatter.formatWithSign(total),
                style: AppTypography.moneyLarge.copyWith(
                  color: isNegative ? AppColors.expense : AppColors.textPrimary,
                ),
              ),
              AppSpacing.verticalGapMd,
              // Fund breakdown
              Row(
                children: [
                  Expanded(
                    child: _FundChip(
                      icon: Icons.account_balance,
                      label: 'Banco',
                      amount: fund?.bank ?? 0,
                    ),
                  ),
                  AppSpacing.horizontalGapSm,
                  Expanded(
                    child: _FundChip(
                      icon: Icons.wallet,
                      label: 'Efectivo',
                      amount: fund?.cash ?? 0,
                    ),
                  ),
                  AppSpacing.horizontalGapSm,
                  Expanded(
                    child: _FundChip(
                      icon: Icons.savings,
                      label: 'Ahorros',
                      amount: fund?.saving ?? 0,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}

class _FundChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;

  const _FundChip({
    required this.icon,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Quick Access ─────────────────────────────────────────────────────────────

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  static const _items = [
    _QuickItem(Icons.favorite_border, 'Categorías'),
    _QuickItem(Icons.history, 'Presupuesto'),
    _QuickItem(Icons.receipt_long_outlined, 'Préstamos'),
    _QuickItem(Icons.person_outline, 'Cajones'),
    _QuickItem(Icons.help_outline, 'Necesito ayuda'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acceso rápido',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.verticalGapSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _items
              .map((item) => _QuickChip(icon: item.icon, label: item.label))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  const _QuickItem(this.icon, this.label);
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          AppSpacing.horizontalGapXs,
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transacciones recientes',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Ver todas las transacciones
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        AppSpacing.verticalGapSm,
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return _EmptyTransactions();
            }
            return Column(
              children: transactions.map((tx) {
                final isExpense = tx.amount < 0;
                return _TransactionTile(
                  amount: tx.amount,
                  date: tx.transactionDate,
                  note: tx.note,
                  isExpense: isExpense,
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.grey400,
          ),
          AppSpacing.verticalGapSm,
          Text(
            'Sin transacciones',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.verticalGapXs,
          Text(
            'Presiona + para registrar tu primer ingreso o gasto',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final double amount;
  final DateTime date;
  final String? note;
  final bool isExpense;

  const _TransactionTile({
    required this.amount,
    required this.date,
    this.note,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusSm,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.expense : AppColors.income)
                  .withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? AppColors.expense : AppColors.income,
              size: 20,
            ),
          ),
          AppSpacing.horizontalGapMd,
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note ?? (isExpense ? 'Gasto' : 'Ingreso'),
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.relative(date),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          // Amount
          Text(
            CurrencyFormatter.formatWithSign(amount),
            style: AppTypography.titleSmall.copyWith(
              color: isExpense ? AppColors.expense : AppColors.income,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
