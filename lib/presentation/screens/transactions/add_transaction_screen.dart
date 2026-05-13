import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';

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

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final notifier = ref.read(transactionNotifierProvider.notifier);

    final success = await notifier.addTransaction(
      amount: amount,
      type: _transactionType,
      transactionDate: _selectedDate,
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
            content: Text('Error al guardar la transaccion'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        onTap: () => setState(() => _transactionType = TransactionType.expense),
                      ),
                    ),
                    Expanded(
                      child: _TypeButton(
                        label: AppStrings.income,
                        icon: Icons.arrow_downward,
                        color: AppColors.income,
                        isSelected: _transactionType == TransactionType.income,
                        onTap: () => setState(() => _transactionType = TransactionType.income),
                      ),
                    ),
                    Expanded(
                      child: _TypeButton(
                        label: AppStrings.transfer,
                        icon: Icons.swap_horiz,
                        color: AppColors.transfer,
                        isSelected: _transactionType == TransactionType.transfer,
                        onTap: () => setState(() => _transactionType = TransactionType.transfer),
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
                leading: Container(
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
                subtitle: const Text('Seleccionar categoria'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show category picker
                },
              ),
              const Divider(),

              // Fund Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.info,
                  ),
                ),
                title: const Text(AppStrings.fund),
                subtitle: const Text('Seleccionar cuenta'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show fund picker
                },
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
