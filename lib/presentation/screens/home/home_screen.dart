import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/user_profile.dart';
import '../../../services/image_upload_service.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/fund_provider.dart';
import '../../providers/selected_fund_provider.dart';
import '../../../services/budget_alert_service.dart';
import '../../widgets/cashito_welcome.dart';
import '../../widgets/cashito_mascot.dart';
import '../../widgets/category_icon.dart';
import '../../providers/alert_provider.dart';
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
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    // Initialize budget alert monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetAlertTriggerProvider);
      _checkWelcome();
    });
  }

  Future<void> _checkWelcome() async {
    final wasShown = await CashitoWelcome.wasShown();
    if (!wasShown && mounted) {
      setState(() => _showWelcome = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
        ),

        // Cashito Welcome Overlay
        if (_showWelcome)
          CashitoWelcome(
            onDismiss: () => setState(() => _showWelcome = false),
          ),
      ],
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
                      _buildNotificationBell(context),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showUserProfile(context, ref),
                        child: userProfileAsync.when(
                          loading: () => _buildHeaderAvatar(null),
                          error: (_, __) => _buildHeaderAvatar(null),
                          data: (profile) => _buildHeaderAvatar(profile?.profilePhoto),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selector de Fondos
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
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: AppColors.primary.withOpacity(0.05),
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(
              //       color: AppColors.primary.withOpacity(0.1),
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       Container(
              //         width: 48,
              //         height: 48,
              //         decoration: BoxDecoration(
              //           color: AppColors.primary.withOpacity(0.1),
              //           shape: BoxShape.circle,
              //           image: const DecorationImage(
              //             image: AssetImage('assets/images/cat-saludando.png'),
              //             fit: BoxFit.contain,
              //           ),
              //         ),                   
              //       ),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               AppStrings.mascotName,
              //               style: Theme.of(context).textTheme.titleSmall?.copyWith(
              //                     fontWeight: FontWeight.bold,
              //                     color: AppColors.primary,
              //                   ),
              //             ),
              //             const SizedBox(height: 2),
              //             Text(
              //               AppStrings.cashitoGreetings[0],
              //               style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //                     color: AppColors.textSecondary,
              //                   ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
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
    final formatter = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

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
                  image: const DecorationImage(
                    image: AssetImage('assets/images/cat-saludando.png'),
                    fit: BoxFit.contain,
                  ),
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

  Widget _buildHeaderAvatar(String? profilePhoto) {
    final hasPhoto = profilePhoto != null && profilePhoto.isNotEmpty;

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: hasPhoto
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: profilePhoto,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (_, __) => Image.asset(
                  'assets/images/cat-saludando.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/images/cat-saludando.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            )
          : Image.asset(
              'assets/images/cat-saludando.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    final unreadAlertsAsync = ref.watch(unreadAlertsProvider);

    return unreadAlertsAsync.when(
      loading: () => IconButton(
        onPressed: () => context.push(AppRoutes.alerts),
        icon: const Icon(Icons.notifications_outlined),
      ),
      error: (_, __) => IconButton(
        onPressed: () => context.push(AppRoutes.alerts),
        icon: const Icon(Icons.notifications_outlined),
      ),
      data: (unreadAlerts) {
        final count = unreadAlerts.length;

        return Stack(
          children: [
            IconButton(
              onPressed: () => context.push(AppRoutes.alerts),
              icon: Icon(
                count > 0 ? Icons.notifications : Icons.notifications_outlined,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.expense,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const CashitoMascot(mood: CashitoMood.receipts, size: 100),
          const SizedBox(height: 12),
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
    Map<String, Category> categoryMap,
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
            leading: category != null
                ? CategoryIcon(category: category, size: 44)
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
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
              '$sign S/${transaction.amount.toStringAsFixed(2)}',
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
                // Validar que el fondo seleccionado existe en la lista
                final validSelectedFundId = selectedFundId != null &&
                        funds.any((f) => f.id == selectedFundId)
                    ? selectedFundId
                    : null;

                // Si el fondo guardado no existe, limpiar la selección
                if (selectedFundId != null && validSelectedFundId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(selectedFundIdProvider.notifier).clearSelection();
                  });
                }

                return DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: validSelectedFundId,
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

  void _showUserProfile(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.read(userProfileNotifierProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserProfileSheet(
        userProfileAsync: userProfileAsync,
        onLogout: () async {
          Navigator.pop(context);
          // Navigate to auth or logout
          context.go(AppRoutes.login);
        },
      ),
    );
  }
}

class _UserProfileSheet extends ConsumerStatefulWidget {
  final AsyncValue<UserProfile?> userProfileAsync;
  final VoidCallback onLogout;

  const _UserProfileSheet({
    required this.userProfileAsync,
    required this.onLogout,
  });

  @override
  ConsumerState<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends ConsumerState<_UserProfileSheet> {
  bool _isEditing = false;
  bool _isUploadingPhoto = false;
  late TextEditingController _nameController;
  final ImageUploadService _imageService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    final profile = widget.userProfileAsync.valueOrNull;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _uploadProfilePhoto() async {
    setState(() => _isUploadingPhoto = true);

    final url = await _imageService.uploadProfilePhoto();

    if (url != null && mounted) {
      final success = await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfile(profilePhoto: url);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    }

    if (mounted) {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildProfileAvatar(UserProfile? profile) {
    final photoUrl = profile?.profilePhoto;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isUploadingPhoto
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const CashitoMascot(
                          mood: CashitoMood.happy,
                          size: 80,
                        ),
                      )
                    : const CashitoMascot(mood: CashitoMood.happy, size: 80),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar with photo upload
          userProfileAsync.when(
            loading: () => _buildProfileAvatar(null),
            error: (_, __) => _buildProfileAvatar(null),
            data: (profile) => _buildProfileAvatar(profile),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca para cambiar foto',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),

          // User info
          userProfileAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (profile) {
              if (profile == null) {
                return const Text('No se encontro perfil');
              }

              // Update controller if profile changed
              if (_nameController.text != profile.fullName && !_isEditing) {
                _nameController.text = profile.fullName;
              }

              return Column(
                children: [
                  if (_isEditing) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final success = await ref
                                .read(userProfileNotifierProvider.notifier)
                                .updateProfile(fullName: _nameController.text.trim());
                            if (success && mounted) {
                              setState(() => _isEditing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Perfil actualizado')),
                              );
                            }
                          },
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      profile.fullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getHelpModeLabel(profile.helpMode),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Miembro desde ${DateFormat('MMMM yyyy', 'es_ES').format(profile.createdAt)}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Actions
          if (!_isEditing) ...[
            _ProfileAction(
              icon: Icons.edit,
              label: 'Editar nombre',
              onTap: () => setState(() => _isEditing = true),
            ),
            _ProfileAction(
              icon: Icons.account_balance_wallet,
              label: 'Mis fondos',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.funds);
              },
            ),
            _ProfileAction(
              icon: Icons.category,
              label: 'Mis categorias',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.categories);
              },
            ),
            _ProfileAction(
              icon: Icons.settings,
              label: 'Configuracion',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.settings);
              },
            ),
            const SizedBox(height: 8),
            _ProfileAction(
              icon: Icons.logout,
              label: 'Cerrar sesion',
              color: AppColors.expense,
              onTap: widget.onLogout,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getHelpModeLabel(HelpMode mode) {
    switch (mode) {
      case HelpMode.general:
        return 'Modo General';
      case HelpMode.youth:
        return 'Modo Joven';
      case HelpMode.business:
        return 'Modo Negocio';
      case HelpMode.support:
        return 'Modo Apoyo';
    }
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = color ?? AppColors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: actionColor),
      title: Text(
        label,
        style: TextStyle(color: actionColor),
      ),
      trailing: Icon(Icons.chevron_right, color: actionColor.withValues(alpha: 0.5)),
      onTap: onTap,
    );
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
