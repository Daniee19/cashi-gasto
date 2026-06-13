import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fund.dart';
import '../../providers/fund_provider.dart';

class FundsScreen extends ConsumerWidget {
  const FundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = ref.watch(fundNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Fondos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transferir',
            onPressed: () => context.push(AppRoutes.transferFunds),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFundModal(context, ref),
          ),
        ],
      ),
      body: fundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.expense),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(fundNotifierProvider.notifier).loadFunds(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (funds) {
          if (funds.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(fundNotifierProvider.notifier).loadFunds(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Balance Card
                  _buildTotalBalanceCard(context, funds),
                  const SizedBox(height: 24),

                  // Distribution Chart
                  if (funds.length > 1) ...[
                    Text(
                      'Distribucion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildDistributionChart(context, funds),
                    const SizedBox(height: 24),
                  ],

                  // Funds List
                  Text(
                    'Mis Cuentas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...funds.map((fund) => _buildFundCard(context, ref, fund)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes fondos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer fondo para organizar tu dinero',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddFundModal(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Crear Fondo'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, List<Fund> funds) {
    final totalBalance = funds.fold<double>(0, (sum, fund) => sum + fund.balance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Balance Total',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${funds.length} ${funds.length == 1 ? 'fondo' : 'fondos'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(BuildContext context, List<Fund> funds) {
    final totalBalance = funds.fold<double>(0, (sum, fund) => sum + fund.balance);
    if (totalBalance == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('No hay balance para mostrar'),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.income,
      AppColors.expense,
      AppColors.warning,
      AppColors.info,
      AppColors.secondary,
    ];

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: funds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final fund = entry.value;
                  final percentage = (fund.balance / totalBalance) * 100;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: fund.balance,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: funds.asMap().entries.map((entry) {
              final index = entry.key;
              final fund = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fund.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFundCard(BuildContext context, WidgetRef ref, Fund fund) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFundColor(fund.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getFundIcon(fund.type),
            color: _getFundColor(fund.type),
          ),
        ),
        title: Text(
          fund.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          fund.type.displayName,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${fund.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: fund.balance >= 0 ? AppColors.income : AppColors.expense,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditFundModal(context, ref, fund);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, ref, fund);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppColors.expense),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: AppColors.expense)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFundIcon(FundType type) {
    switch (type) {
      case FundType.bank:
        return Icons.account_balance;
      case FundType.cash:
        return Icons.payments;
      case FundType.savings:
        return Icons.savings;
    }
  }

  Color _getFundColor(FundType type) {
    switch (type) {
      case FundType.bank:
        return AppColors.info;
      case FundType.cash:
        return AppColors.income;
      case FundType.savings:
        return AppColors.primary;
    }
  }

  void _showAddFundModal(BuildContext context, WidgetRef ref) {
    _showFundModal(context, ref, null);
  }

  void _showEditFundModal(BuildContext context, WidgetRef ref, Fund fund) {
    _showFundModal(context, ref, fund);
  }

  void _showFundModal(BuildContext context, WidgetRef ref, Fund? fund) {
    final isEditing = fund != null;
    final nameController = TextEditingController(text: fund?.name ?? '');
    final balanceController = TextEditingController(
      text: fund?.balance.toString() ?? '0',
    );
    FundType selectedType = fund?.type ?? FundType.cash;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Text(
                isEditing ? 'Editar Fondo' : 'Nuevo Fondo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del fondo',
                  hintText: 'Ej: Cuenta de ahorros',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Type selector
              Text(
                'Tipo de fondo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: FundType.values.map((type) {
                  final isSelected = selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getFundColor(type).withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _getFundColor(type)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getFundIcon(type),
                              color: isSelected
                                  ? _getFundColor(type)
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _getFundColor(type)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Balance field (only for new funds)
              if (!isEditing) ...[
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Balance inicial',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El nombre es requerido')),
                      );
                      return;
                    }

                    bool success;
                    if (isEditing) {
                      success = await ref.read(fundNotifierProvider.notifier).updateFund(
                            id: fund.id,
                            name: name,
                            type: selectedType,
                          );
                    } else {
                      final balance = double.tryParse(balanceController.text) ?? 0;
                      success = await ref.read(fundNotifierProvider.notifier).addFund(
                            name: name,
                            type: selectedType,
                            balance: balance,
                          );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? (isEditing ? 'Fondo actualizado' : 'Fondo creado')
                                : 'Error al guardar el fondo',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Guardar Cambios' : 'Crear Fondo'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Fund fund) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Fondo'),
        content: Text('¿Estas seguro de eliminar "${fund.name}"?\n\nEsta accion no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(fundNotifierProvider.notifier).deleteFund(fund.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Fondo eliminado' : 'Error al eliminar el fondo',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
