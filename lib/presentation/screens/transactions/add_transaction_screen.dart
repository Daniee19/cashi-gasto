import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/category.dart';
import '../../../data/models/fund.dart';
import '../../../data/models/transaction.dart';
import '../../providers/category_provider.dart';
import '../../providers/fund_provider.dart';
import '../../providers/selected_fund_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _transactionType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Category? _selectedCategory;
  Fund? _selectedFund;

  @override
  void initState() {
    super.initState();
    // Auto-seleccionar el fondo activo después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFund();
    });
  }

  void _autoSelectFund() {
    final fundsAsync = ref.read(fundsProvider);
    fundsAsync.whenData((funds) {
      if (!mounted || funds.isEmpty) return;

      // Si solo hay un fondo, seleccionarlo automáticamente
      if (funds.length == 1) {
        setState(() => _selectedFund = funds.first);
        return;
      }

      // Si hay un fondo seleccionado en el home, usarlo
      final selectedFundId = ref.read(selectedFundIdProvider);
      if (selectedFundId != null) {
        final selectedFund = funds.where((f) => f.id == selectedFundId).firstOrNull;
        if (selectedFund != null) {
          setState(() => _selectedFund = selectedFund);
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFund == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un fondo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final notifier = ref.read(transactionNotifierProvider.notifier);

    final success = await notifier.addTransaction(
      amount: amount,
      type: _transactionType,
      transactionDate: _selectedDate,
      categoryId: _selectedCategory?.id,
      fundId: _selectedFund?.id,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaccion guardada')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la transaccion. Verifica tu conexion.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategoryPicker() {
    final categoryType = _transactionType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Consumer(
          builder: (context, ref, _) {
            final categoriesAsync = ref.watch(categoriesByTypeProvider(categoryType));

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Seleccionar categoria',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (categories) => categories.isEmpty
                        ? const Center(child: Text('No hay categorias disponibles'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return ListTile(
                                leading: CategoryIcon(
                                  category: category,
                                  size: 40,
                                ),
                                title: Text(category.name),
                                trailing: _selectedCategory?.id == category.id
                                    ? const Icon(Icons.check, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  setState(() => _selectedCategory = category);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFundPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Consumer(
          builder: (context, ref, _) {
            final fundsAsync = ref.watch(fundsProvider);

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Seleccionar cuenta',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: fundsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Error: $e'),
                        ],
                      ),
                    ),
                    data: (funds) => funds.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No tienes fondos creados'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: funds.length,
                            itemBuilder: (context, index) {
                              final fund = funds[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getFundIcon(fund.type),
                                    color: AppColors.info,
                                  ),
                                ),
                                title: Text(fund.name),
                                subtitle: Text(fund.type.displayName),
                                trailing: _selectedFund?.id == fund.id
                                    ? const Icon(Icons.check, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  setState(() => _selectedFund = fund);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addTransaction),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Selector
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: AppStrings.expense,
                        icon: Icons.arrow_upward,
                        color: AppColors.expense,
                        isSelected: _transactionType == TransactionType.expense,
                        onTap: () => setState(() {
                          _transactionType = TransactionType.expense;
                          _selectedCategory = null; // Reset category when type changes
                        }),
                      ),
                    ),
                    Expanded(
                      child: _TypeButton(
                        label: AppStrings.income,
                        icon: Icons.arrow_downward,
                        color: AppColors.income,
                        isSelected: _transactionType == TransactionType.income,
                        onTap: () => setState(() {
                          _transactionType = TransactionType.income;
                          _selectedCategory = null; // Reset category when type changes
                        }),
                      ),
                    ),
                    Expanded(
                      child: _TypeButton(
                        label: AppStrings.transfer,
                        icon: Icons.swap_horiz,
                        color: AppColors.transfer,
                        isSelected: _transactionType == TransactionType.transfer,
                        onTap: () => setState(() {
                          _transactionType = TransactionType.transfer;
                          _selectedCategory = null; // Reset category when type changes
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: AppStrings.amount,
                  prefixText: '\$ ',
                  prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _selectedCategory != null
                    ? CategoryIcon(
                        category: _selectedCategory!,
                        size: 48,
                        borderRadius: 12,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                title: const Text(AppStrings.category),
                subtitle: Text(
                  _selectedCategory?.name ?? 'Seleccionar categoria',
                  style: TextStyle(
                    color: _selectedCategory != null ? null : AppColors.textMuted,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showCategoryPicker,
              ),
              const Divider(),

              // Fund Selector (obligatorio)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedFund != null
                        ? _getFundIcon(_selectedFund!.type)
                        : Icons.account_balance_wallet_outlined,
                    color: AppColors.info,
                  ),
                ),
                title: Row(
                  children: [
                    const Text(AppStrings.fund),
                    const Text(' *', style: TextStyle(color: Colors.red)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Los fondos te ayudan a organizar tu dinero\nen diferentes cuentas o billeteras',
                      child: Icon(
                        Icons.help_outline,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  _selectedFund?.name ?? 'Seleccionar cuenta (requerido)',
                  style: TextStyle(
                    color: _selectedFund != null ? null : AppColors.textMuted,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showFundPicker,
              ),
              const Divider(),

              // Date Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.warning,
                  ),
                ),
                title: const Text(AppStrings.date),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Note Field
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: AppStrings.note,
                  hintText: 'Agrega una nota (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
