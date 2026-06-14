import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/fund.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/fund_provider.dart';
import '../../providers/selected_fund_provider.dart';

class TransactionListScreen extends ConsumerWidget {
  final bool showAppBar;

  const TransactionListScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final fundsAsync = ref.watch(fundNotifierProvider);
    final selectedFundId = ref.watch(selectedFundIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactions),
        automaticallyImplyLeading: showAppBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(transactionNotifierProvider.notifier).loadTransactions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Fund Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildFundSelector(context, ref, fundsAsync, selectedFundId),
          ),

          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(transactionNotifierProvider.notifier).loadTransactions();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Agrupar transacciones por fecha y luego por hora
                final grouped = _groupTransactionsByDateAndHour(transactions);

                return categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildTransactionList(context, ref, grouped, {}, {}),
                  data: (categories) {
                    final categoryMap = {for (var c in categories) c.id: c};
                    final funds = fundsAsync.valueOrNull ?? [];
                    final fundMap = {for (var f in funds) f.id: f};
                    return _buildTransactionList(context, ref, grouped, categoryMap, fundMap);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: showAppBar
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.addTransaction),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFundSelector(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Fund>> fundsAsync,
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
      child: fundsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Cargando fondos...'),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Error al cargar fondos'),
        ),
        data: (funds) {
          final validSelectedFundId = selectedFundId != null &&
                  funds.any((f) => f.id == selectedFundId)
              ? selectedFundId
              : null;

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
                  final icon = _getFundIcon(fund.type);
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
    );
  }

  IconData _getFundIcon(FundType type) {
    switch (type) {
      case FundType.general:
        return Icons.account_balance_wallet;
      case FundType.bank:
        return Icons.account_balance;
      case FundType.cash:
        return Icons.payments;
      case FundType.savings:
        return Icons.savings;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay transacciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera transaccion para comenzar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.addTransaction),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addTransaction),
          ),
        ],
      ),
    );
  }

  /// Agrupa transacciones por fecha y luego por hora
  Map<String, Map<String, List<Transaction>>> _groupTransactionsByDateAndHour(
      List<Transaction> transactions) {
    final Map<String, Map<String, List<Transaction>>> grouped = {};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final transaction in transactions) {
      final dateKey = dateFormat.format(transaction.transactionDate);
      final hourKey = '${transaction.createdAt.hour.toString().padLeft(2, '0')}:00';

      grouped.putIfAbsent(dateKey, () => {});
      grouped[dateKey]!.putIfAbsent(hourKey, () => []);
      grouped[dateKey]![hourKey]!.add(transaction);
    }

    // Ordenar transacciones dentro de cada hora por createdAt (más reciente primero)
    for (final dateKey in grouped.keys) {
      for (final hourKey in grouped[dateKey]!.keys) {
        grouped[dateKey]![hourKey]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    }

    return grouped;
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    Map<String, Map<String, List<Transaction>>> grouped,
    Map<String, dynamic> categoryMap,
    Map<String, Fund> fundMap,
  ) {
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final hourGroups = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final sortedHours = hourGroups.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDateHeader(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Timeline por horas
            ...sortedHours.map((hourKey) {
              final transactions = hourGroups[hourKey]!;
              return _buildHourGroup(context, ref, hourKey, transactions, categoryMap, fundMap);
            }),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildHourGroup(
    BuildContext context,
    WidgetRef ref,
    String hourKey,
    List<Transaction> transactions,
    Map<String, dynamic> categoryMap,
    Map<String, Fund> fundMap,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 60,
          child: Column(
            children: [
              // Hour label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hourKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Timeline line
              if (transactions.length > 1)
                Container(
                  width: 2,
                  height: (transactions.length - 1) * 88.0,
                  margin: const EdgeInsets.only(top: 4),
                  color: AppColors.primary.withOpacity(0.2),
                ),
            ],
          ),
        ),

        // Transactions column
        Expanded(
          child: Column(
            children: transactions.map((transaction) {
              return _TransactionCard(
                transaction: transaction,
                category: categoryMap[transaction.categoryId],
                fund: transaction.fundId != null ? fundMap[transaction.fundId] : null,
                onEdit: () => _showEditModal(context, ref, transaction),
                onDelete: () => _showDeleteConfirmation(context, ref, transaction),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Hoy';
    } else if (transactionDate == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('EEEE, d MMMM', 'es_ES').format(date);
    }
  }

  void _showEditModal(BuildContext context, WidgetRef ref, Transaction transaction) {
    final amountController = TextEditingController(text: transaction.amount.toString());
    final noteController = TextEditingController(text: transaction.note ?? '');
    TransactionType selectedType = transaction.type;
    DateTime selectedDate = transaction.transactionDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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

                Text(
                  'Editar transaccion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Type selector
                Row(
                  children: [
                    _TypeChip(
                      label: 'Gasto',
                      isSelected: selectedType == TransactionType.expense,
                      color: AppColors.expense,
                      onTap: () => setModalState(() => selectedType = TransactionType.expense),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Ingreso',
                      isSelected: selectedType == TransactionType.income,
                      color: AppColors.income,
                      onTap: () => setModalState(() => selectedType = TransactionType.income),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                ),

                // Note
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Nota (opcional)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un monto valido')),
                        );
                        return;
                      }

                      final updated = transaction.copyWith(
                        amount: amount,
                        type: selectedType,
                        transactionDate: selectedDate,
                        note: noteController.text.isNotEmpty ? noteController.text : null,
                      );

                      final success = await ref
                          .read(transactionNotifierProvider.notifier)
                          .updateTransaction(updated);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Transaccion actualizada'
                                : 'Error al actualizar'),
                            backgroundColor: success ? null : Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Guardar cambios'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar transaccion'),
        content: Text(
          '¿Estas seguro de eliminar esta transaccion de \$${transaction.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(transactionNotifierProvider.notifier)
                  .deleteTransaction(transaction.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Transaccion eliminada'
                        : 'Error al eliminar'),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final dynamic category;
  final Fund? fund;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.category,
    this.fund,
    required this.onEdit,
    required this.onDelete,
  });

  /// Convierte nombres de iconos Material a emojis
  String _getEmoji(String? iconName, bool isExpense) {
    const iconToEmoji = {
      // Gastos
      'restaurant': '🍔',
      'directions_car': '🚗',
      'movie': '🎬',
      'shopping_bag': '🛍️',
      'medical_services': '🏥',
      'school': '📚',
      'receipt': '🧾',
      'more_horiz': '📦',
      // Ingresos
      'payments': '💵',
      'trending_up': '📈',
      'card_giftcard': '🎁',
      // Otros
      'home': '🏠',
      'pets': '🐾',
      'fitness_center': '💪',
      'flight': '✈️',
      'phone': '📱',
      'wifi': '📶',
      'water_drop': '💧',
      'bolt': '⚡',
    };

    if (iconName == null) {
      return isExpense ? '💸' : '💰';
    }

    // Si ya es un emoji, devolverlo tal cual
    if (iconName.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
      return iconName;
    }

    return iconToEmoji[iconName] ?? (isExpense ? '💸' : '💰');
  }

  void _showDetails(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;
    final sign = isExpense ? '-' : '+';
    final categoryIcon = _getEmoji(category?.icon, isExpense);
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es_ES');
    final timeFormat = DateFormat('HH:mm');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Icono y monto
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(categoryIcon, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$sign\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category?.name ?? transaction.type.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detalles
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha',
                    value: dateFormat.format(transaction.transactionDate),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Hora',
                    value: timeFormat.format(transaction.createdAt),
                  ),
                  if (fund != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Fondo',
                      value: fund!.name,
                    ),
                  ],
                  if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.notes_outlined,
                      label: 'Nota',
                      value: transaction.note!,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit();
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;
    final sign = isExpense ? '-' : '+';
    final timeFormat = DateFormat('HH:mm');
    final categoryIcon = _getEmoji(category?.icon, isExpense);

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Icono categoría
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(categoryIcon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? transaction.type.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(
                          timeFormat.format(transaction.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if (transaction.note != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.sticky_note_2_outlined, size: 12, color: Colors.grey[400]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Monto
              Text(
                '$sign\$${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
