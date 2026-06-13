import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/budget.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  final bool showAppBar;

  const BudgetsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Presupuestos'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddBudgetModal(context, ref, categoriesAsync),
                ),
              ],
            )
          : null,
      body: budgetsAsync.when(
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
                onPressed: () => ref.read(budgetNotifierProvider.notifier).loadBudgets(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return _buildEmptyState(context, ref, categoriesAsync);
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(budgetNotifierProvider.notifier).loadBudgets(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                _buildSummaryCard(context, budgets),
                const SizedBox(height: 24),

                // Active budgets header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Presupuestos Activos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddBudgetModal(context, ref, categoriesAsync),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Budget cards
                ...budgets.map((budget) => _buildBudgetCard(
                      context,
                      ref,
                      budget,
                      categoriesAsync,
                    )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: showAppBar
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddBudgetModal(context, ref, categoriesAsync),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 80,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin presupuestos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un presupuesto para controlar tus gastos por categoria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddBudgetModal(context, ref, categoriesAsync),
              icon: const Icon(Icons.add),
              label: const Text('Crear Presupuesto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<BudgetWithSpent> budgets) {
    final totalBudgeted = budgets.fold<double>(0, (sum, b) => sum + b.budget.amountBudgeted);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spent);
    final overBudgetCount = budgets.where((b) => b.isOverBudget).length;
    final warningCount = budgets.where((b) => b.isWarning).length;

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Presupuestado',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${totalBudgeted.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Gastado',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${totalSpent.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalBudgeted > 0 ? (totalSpent / totalBudgeted).clamp(0, 1) : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                totalSpent > totalBudgeted ? AppColors.expense : Colors.white,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (overBudgetCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$overBudgetCount excedido${overBudgetCount > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (warningCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$warningCount cerca del limite',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    BudgetWithSpent budgetWithSpent,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    final budget = budgetWithSpent.budget;
    final spent = budgetWithSpent.spent;
    final percentUsed = budgetWithSpent.percentUsed;
    final remaining = budgetWithSpent.remaining;

    // Get category name
    final categoryName = categoriesAsync.when(
      loading: () => 'Cargando...',
      error: (_, __) => 'Categoria',
      data: (categories) {
        final category = categories.where((c) => c.id == budget.categoryId).firstOrNull;
        return category?.name ?? 'Sin categoria';
      },
    );

    final categoryIcon = categoriesAsync.when(
      loading: () => null,
      error: (_, __) => null,
      data: (categories) {
        final category = categories.where((c) => c.id == budget.categoryId).firstOrNull;
        return category?.icon;
      },
    );

    // Determine color based on percentage
    Color progressColor;
    Color bgColor;
    if (budgetWithSpent.isOverBudget) {
      progressColor = AppColors.expense;
      bgColor = AppColors.expense.withValues(alpha: 0.1);
    } else if (budgetWithSpent.isWarning) {
      progressColor = AppColors.warning;
      bgColor = AppColors.warning.withValues(alpha: 0.1);
    } else {
      progressColor = AppColors.income;
      bgColor = AppColors.income.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: categoryIcon != null
                      ? Text(categoryIcon, style: const TextStyle(fontSize: 22))
                      : Icon(Icons.category, color: progressColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      budget.period.displayName,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditBudgetModal(context, ref, budgetWithSpent);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, ref, budget);
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
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentUsed / 100).clamp(0, 1),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gastado',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  Text(
                    '\$${spent.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${percentUsed.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    budgetWithSpent.isOverBudget ? 'Excedido' : 'Disponible',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  Text(
                    '\$${remaining.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: budgetWithSpent.isOverBudget ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBudgetModal(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    final amountController = TextEditingController();
    Category? selectedCategory;
    BudgetPeriod selectedPeriod = BudgetPeriod.monthly;

    // Get expense categories only
    final expenseCategories = categoriesAsync.when(
      loading: () => <Category>[],
      error: (_, __) => <Category>[],
      data: (categories) => categories.where((c) => c.type == CategoryType.expense).toList(),
    );

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
                'Nuevo Presupuesto',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Category selector
              Text(
                'Categoria',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Category>(
                    value: selectedCategory,
                    isExpanded: true,
                    hint: const Text('Seleccionar categoria'),
                    items: expenseCategories.map((category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Row(
                          children: [
                            Text(category.icon ?? '📁', style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() => selectedCategory = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount field
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto limite',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),

              // Period selector
              Text(
                'Periodo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: BudgetPeriod.values.map((period) {
                  final isSelected = selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedPeriod = period),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            period.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona una categoria')),
                      );
                      return;
                    }
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa un monto valido')),
                      );
                      return;
                    }

                    final success = await ref.read(budgetNotifierProvider.notifier).addBudget(
                          categoryId: selectedCategory!.id,
                          period: selectedPeriod,
                          amountBudgeted: amount,
                        );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Presupuesto creado' : 'Error al crear presupuesto',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Crear Presupuesto'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBudgetModal(
    BuildContext context,
    WidgetRef ref,
    BudgetWithSpent budgetWithSpent,
  ) {
    final budget = budgetWithSpent.budget;
    final amountController = TextEditingController(
      text: budget.amountBudgeted.toStringAsFixed(2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
              'Editar Presupuesto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto limite',
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),

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

                  final success = await ref.read(budgetNotifierProvider.notifier).updateBudget(
                        id: budget.id,
                        amountBudgeted: amount,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Presupuesto actualizado' : 'Error al actualizar',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Guardar Cambios'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: const Text('¿Estas seguro de eliminar este presupuesto?\n\nEsta accion no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(budgetNotifierProvider.notifier).deleteBudget(budget.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Presupuesto eliminado' : 'Error al eliminar',
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
