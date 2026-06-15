import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/financial_goal.dart';
import '../../providers/financial_goal_provider.dart';
import '../../widgets/cashito_mascot.dart';
import 'dart:math' as math;

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(financialGoalNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas Financieras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalModal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Completadas'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      body: goalsAsync.when(
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
                onPressed: () => ref.read(financialGoalNotifierProvider.notifier).loadGoals(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (goals) {
          final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
          final completedGoals = goals.where((g) => g.status == GoalStatus.completed).toList();
          final cancelledGoals = goals.where((g) => g.status == GoalStatus.cancelled).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGoalsList(context, activeGoals, GoalStatus.active),
              _buildGoalsList(context, completedGoals, GoalStatus.completed),
              _buildGoalsList(context, cancelledGoals, GoalStatus.cancelled),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalsList(BuildContext context, List<FinancialGoal> goals, GoalStatus status) {
    if (goals.isEmpty) {
      return _buildEmptyState(context, status);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(financialGoalNotifierProvider.notifier).loadGoals(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) => _buildGoalCard(context, goals[index]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, GoalStatus status) {
    CashitoMood mood;
    String title;
    String? subtitle;

    switch (status) {
      case GoalStatus.active:
        mood = CashitoMood.goals;
        title = 'No tienes metas activas';
        subtitle = 'Crea una meta para empezar a ahorrar';
        break;
      case GoalStatus.completed:
        mood = CashitoMood.happy;
        title = 'Aun no has completado metas';
        subtitle = '¡Sigue adelante, tu puedes!';
        break;
      case GoalStatus.cancelled:
        mood = CashitoMood.sad;
        title = 'No tienes metas canceladas';
        subtitle = 'Eso es bueno, sigue asi';
        break;
    }

    return CashitoEmptyState(
      mood: mood,
      title: title,
      subtitle: subtitle,
      action: status == GoalStatus.active
          ? ElevatedButton.icon(
              onPressed: () => _showAddGoalModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear Meta'),
            )
          : null,
    );
  }

  Widget _buildGoalCard(BuildContext context, FinancialGoal goal) {
    final progress = goal.progressPercentage;
    final daysRemaining = goal.daysRemaining;
    final isCompleted = goal.status == GoalStatus.completed;
    final isCancelled = goal.status == GoalStatus.cancelled;
    final isActive = goal.status == GoalStatus.active;

    Color progressColor;
    if (isCompleted) {
      progressColor = AppColors.income;
    } else if (isCancelled) {
      progressColor = AppColors.textMuted;
    } else if (daysRemaining != null && daysRemaining <= 7 && daysRemaining >= 0) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular progress
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(70, 70),
                      painter: _CircularProgressPainter(
                        progress: progress / 100,
                        color: progressColor,
                        backgroundColor: Colors.grey[200]!,
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isActive)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) => _handleMenuAction(context, value, goal),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'contribute',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle, size: 20, color: AppColors.income),
                                    SizedBox(width: 8),
                                    Text('Aportar'),
                                  ],
                                ),
                              ),
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
                                value: 'complete',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 20, color: AppColors.income),
                                    SizedBox(width: 8),
                                    Text('Marcar completada'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, size: 20, color: AppColors.expense),
                                    SizedBox(width: 8),
                                    Text('Cancelar', style: TextStyle(color: AppColors.expense)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else if (isCompleted || isCancelled)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) => _handleMenuAction(context, value, goal),
                            itemBuilder: (context) => [
                              if (isCancelled)
                                const PopupMenuItem(
                                  value: 'reactivate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.refresh, size: 20, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Reactivar'),
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
                    if (goal.description != null && goal.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.description!,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Amount info
                    Row(
                      children: [
                        Text(
                          'S/ ${goal.currentAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                        Text(
                          ' / S/ ${goal.targetAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isActive && daysRemaining != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: daysRemaining <= 7
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: daysRemaining <= 7 ? AppColors.warning : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    daysRemaining < 0
                        ? 'Vencida hace ${-daysRemaining} dias'
                        : daysRemaining == 0
                            ? 'Vence hoy'
                            : daysRemaining == 1
                                ? 'Vence manana'
                                : '$daysRemaining dias restantes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: daysRemaining <= 7 ? AppColors.warning : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showContributeModal(context, goal),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Aportar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, FinancialGoal goal) {
    switch (action) {
      case 'contribute':
        _showContributeModal(context, goal);
        break;
      case 'edit':
        _showEditGoalModal(context, goal);
        break;
      case 'complete':
        _markAsCompleted(context, goal);
        break;
      case 'cancel':
        _showCancelConfirmation(context, goal);
        break;
      case 'reactivate':
        _reactivateGoal(context, goal);
        break;
      case 'delete':
        _showDeleteConfirmation(context, goal);
        break;
    }
  }

  void _showAddGoalModal(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();
    final initialController = TextEditingController(text: '0');
    DateTime? selectedDeadline;

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
          child: SingleChildScrollView(
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
                  'Nueva Meta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la meta',
                    hintText: 'Ej: Viaje a la playa',
                    prefixIcon: Icon(Icons.flag),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion (opcional)',
                    hintText: 'Describe tu meta...',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto objetivo',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: initialController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto inicial (opcional)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.savings),
                  ),
                ),
                const SizedBox(height: 16),

                // Deadline selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDeadline != null
                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                        : 'Fecha limite (opcional)',
                  ),
                  trailing: selectedDeadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setModalState(() => selectedDeadline = null),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setModalState(() => selectedDeadline = date);
                    }
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un nombre para la meta')),
                        );
                        return;
                      }

                      final target = double.tryParse(targetController.text);
                      if (target == null || target <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un monto objetivo valido')),
                        );
                        return;
                      }

                      final initial = double.tryParse(initialController.text) ?? 0;

                      final success = await ref.read(financialGoalNotifierProvider.notifier).addGoal(
                            title: title,
                            description: descriptionController.text.trim().isNotEmpty
                                ? descriptionController.text.trim()
                                : null,
                            targetAmount: target,
                            initialAmount: initial,
                            deadline: selectedDeadline,
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Meta creada' : 'Error al crear meta'),
                          ),
                        );
                      }
                    },
                    child: const Text('Crear Meta'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditGoalModal(BuildContext context, FinancialGoal goal) {
    final titleController = TextEditingController(text: goal.title);
    final descriptionController = TextEditingController(text: goal.description ?? '');
    final targetController = TextEditingController(text: goal.targetAmount.toStringAsFixed(2));
    DateTime? selectedDeadline = goal.deadline;

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
          child: SingleChildScrollView(
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
                  'Editar Meta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la meta',
                    prefixIcon: Icon(Icons.flag),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion (opcional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto objetivo',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDeadline != null
                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                        : 'Sin fecha limite',
                  ),
                  trailing: selectedDeadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setModalState(() => selectedDeadline = null),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setModalState(() => selectedDeadline = date);
                    }
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un nombre para la meta')),
                        );
                        return;
                      }

                      final target = double.tryParse(targetController.text);
                      if (target == null || target <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un monto objetivo valido')),
                        );
                        return;
                      }

                      final success = await ref.read(financialGoalNotifierProvider.notifier).updateGoal(
                            id: goal.id,
                            title: title,
                            description: descriptionController.text.trim().isNotEmpty
                                ? descriptionController.text.trim()
                                : null,
                            targetAmount: target,
                            deadline: selectedDeadline,
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Meta actualizada' : 'Error al actualizar'),
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
        ),
      ),
    );
  }

  void _showContributeModal(BuildContext context, FinancialGoal goal) {
    final amountController = TextEditingController();
    final remaining = goal.remainingAmount;

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
              'Aportar a "${goal.title}"',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faltan S/ ${remaining.toStringAsFixed(2)} para completar la meta',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto a aportar',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                suffixIcon: TextButton(
                  onPressed: () {
                    amountController.text = remaining.toStringAsFixed(2);
                  },
                  child: const Text('TODO'),
                ),
              ),
              autofocus: true,
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

                  final result = await ref.read(financialGoalNotifierProvider.notifier).addContribution(
                        goalId: goal.id,
                        amount: amount,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    if (result.success) {
                      final newAmount = goal.currentAmount + amount;
                      final completed = newAmount >= goal.targetAmount;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            completed
                                ? '¡Felicidades! Meta completada'
                                : 'Aporte de S/ ${amount.toStringAsFixed(2)} registrado',
                          ),
                          backgroundColor: completed ? AppColors.income : null,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.error ?? 'Error al registrar aporte')),
                      );
                    }
                  }
                },
                child: const Text('Aportar'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsCompleted(BuildContext context, FinancialGoal goal) async {
    final success = await ref.read(financialGoalNotifierProvider.notifier).markAsCompleted(goal.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '¡Meta completada!' : 'Error al completar'),
          backgroundColor: success ? AppColors.income : null,
        ),
      );
    }
  }

  void _showCancelConfirmation(BuildContext context, FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Meta'),
        content: Text('¿Estas seguro de cancelar "${goal.title}"?\n\nPuedes reactivarla mas tarde.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(financialGoalNotifierProvider.notifier).markAsCancelled(goal.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Meta cancelada' : 'Error al cancelar')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Si, cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivateGoal(BuildContext context, FinancialGoal goal) async {
    final success = await ref.read(financialGoalNotifierProvider.notifier).reactivate(goal.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Meta reactivada' : 'Error al reactivar')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Meta'),
        content: Text(
          '¿Estas seguro de eliminar "${goal.title}"?\n\nEsta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(financialGoalNotifierProvider.notifier).deleteGoal(goal.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Meta eliminada' : 'Error al eliminar'),
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

// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
