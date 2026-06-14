import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/fund_provider.dart';
import '../../providers/selected_fund_provider.dart';
import '../../../services/budget_alert_service.dart';
import '../more/more_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../budgets/budgets_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize budget alert monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetAlertTriggerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(context),
          const TransactionListScreen(showAppBar: false),
          const BudgetsScreen(showAppBar: false),
          const MoreScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTransaction),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: AppStrings.transactions,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            activeIcon: Icon(Icons.savings),
            label: AppStrings.budgets,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: AppStrings.more,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    final fundsAsync = ref.watch(fundNotifierProvider);
    final selectedFundId = ref.watch(selectedFundIdProvider);
    final filteredBalance = ref.watch(filteredBalanceProvider);

    // Obtener nombre del usuario
    final userName = userProfileAsync.when(
      loading: () => 'Usuario',
      error: (_, __) => 'Usuario',
      data: (profile) => profile?.fullName ?? 'Usuario',
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(transactionNotifierProvider.notifier).loadTransactions();
          ref.read(userProfileNotifierProvider.notifier).loadUserProfile();
          ref.read(fundNotifierProvider.notifier).loadFunds();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fund Selector
              _buildFundSelector(context, fundsAsync, selectedFundId),
              const SizedBox(height: 16),

              // Balance Card - with filtered data
              _buildBalanceCard(
                context,
                filteredBalance.balance,
                filteredBalance.income,
                filteredBalance.expense,
              ),
              const SizedBox(height: 24),

              // Cashito Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.mascotName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.cashitoGreetings[0],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Acciones rapidas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickAction(
                    icon: Icons.add,
                    label: 'Agregar',
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.addTransaction),
                  ),
                  _QuickAction(
                    icon: Icons.list_alt,
                    label: 'Historial',
                    color: AppColors.info,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _QuickAction(
                    icon: Icons.pie_chart,
                    label: 'Reportes',
                    color: AppColors.warning,
                    onTap: () => context.push(AppRoutes.reports),
                  ),
                  _QuickAction(
                    icon: Icons.chat,
                    label: 'Cashito',
                    color: AppColors.secondary,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transacciones recientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recent transactions list (filtered by fund)
              filteredTransactionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Error: $error'),
                  ),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return _buildEmptyTransactions(context);
                  }

                  // Show only last 5 transactions
                  final recent = transactions.take(5).toList();

                  return categoriesAsync.when(
                    loading: () => _buildRecentTransactionsList(context, recent, {}),
                    error: (_, __) => _buildRecentTransactionsList(context, recent, {}),
                    data: (categories) {
                      final categoryMap = {for (var c in categories) c.id: c};
                      return _buildRecentTransactionsList(context, recent, categoryMap);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    double income,
    double expense,
  ) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Balance Total',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatter.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  icon: Icons.arrow_downward,
                  label: AppStrings.income,
                  amount: formatter.format(income),
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BalanceItem(
                  icon: Icons.arrow_upward,
                  label: AppStrings.expense,
                  amount: formatter.format(expense),
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay transacciones aun',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega tu primera transaccion',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(
    BuildContext context,
    List<Transaction> transactions,
    Map<String, dynamic> categoryMap,
  ) {
    return Column(
      children: transactions.map((transaction) {
        final category = categoryMap[transaction.categoryId];
        final isExpense = transaction.type == TransactionType.expense;
        final color = isExpense ? AppColors.expense : AppColors.income;
        final sign = isExpense ? '-' : '+';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: category != null
                    ? Text(
                        category.icon ?? (isExpense ? '💸' : '💰'),
                        style: const TextStyle(fontSize: 22),
                      )
                    : Icon(
                        isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                      ),
              ),
            ),
            title: Text(
              category?.name ?? transaction.type.displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              DateFormat('dd MMM', 'es_ES').format(transaction.transactionDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Text(
              '$sign\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFundSelector(
    BuildContext context,
    AsyncValue<List<dynamic>> fundsAsync,
    String? selectedFundId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: fundsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Cargando fondos...'),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Error al cargar fondos'),
              ),
              data: (funds) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedFundId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                    hint: Row(
                      children: [
                        Icon(Icons.account_balance_wallet,
                             size: 20,
                             color: AppColors.primary.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        const Text('Todos los fondos'),
                      ],
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.all_inclusive,
                                 size: 20,
                                 color: AppColors.primary.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            const Text('Todos los fondos'),
                          ],
                        ),
                      ),
                      ...funds.map((fund) {
                        final icon = _getFundIcon(fund.type.value);
                        return DropdownMenuItem<String?>(
                          value: fund.id,
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fund.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      ref.read(selectedFundIdProvider.notifier).setSelectedFund(value);
                    },
                  ),
                );
              },
            ),
          ),
          // Icono de ayuda contextual
          Tooltip(
            message: 'Los fondos te permiten organizar tu dinero\nen diferentes cuentas (banco, efectivo, ahorros).\n\nSelecciona un fondo para filtrar transacciones\no elige "Todos los fondos" para ver todo.',
            child: IconButton(
              icon: Icon(
                Icons.help_outline,
                size: 20,
                color: AppColors.primary.withOpacity(0.6),
              ),
              onPressed: () {
                _showFundHelpDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFundHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Acerca de los Fondos'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Los fondos te ayudan a organizar tu dinero en diferentes cuentas o billeteras.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Tipos de fondos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('General - Uso multiple'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.account_balance, size: 20, color: AppColors.info),
                SizedBox(width: 8),
                Text('Banco - Cuentas bancarias'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.payments, size: 20, color: AppColors.income),
                SizedBox(width: 8),
                Text('Efectivo - Dinero en mano'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.savings, size: 20, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Ahorros - Dinero apartado'),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Usa el selector para filtrar transacciones por fondo o ver todas juntas.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  IconData _getFundIcon(String type) {
    switch (type) {
      case 'general':
        return Icons.account_balance_wallet;
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.payments;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _BalanceItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
