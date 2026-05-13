import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/utils.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/transactions_provider.dart';

/// Tipo de transacción a registrar
enum TransactionType { income, expense }

class AddTransactionPage extends ConsumerStatefulWidget {
  final TransactionType type;

  const AddTransactionPage({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  String? _selectedFundType;
  bool _isLoading = false;

  bool get isIncome => widget.type == TransactionType.income;

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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    if (_selectedFundType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cajón')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(transactionsRepositoryProvider);
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      final fund = await ref.read(userFundProvider.future);

      if (userId == null || fund == null) {
        throw Exception('Usuario no autenticado');
      }

      final amount = double.parse(
        _amountController.text.replaceAll(',', '.'),
      );

      await repository.createTransaction(
        userId: userId,
        categoryId: _selectedCategory!.id,
        fundId: fund.id,
        amount: isIncome ? amount : -amount,
        method: TransactionMethod.manual,
        transactionDate: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIncome ? 'Ingreso registrado' : 'Gasto registrado',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = isIncome
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isIncome ? 'Registrar ingreso' : 'Registrar gasto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Monto
            _SectionTitle(title: 'Monto'),
            AppSpacing.verticalGapSm,
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
              style: AppTypography.moneyLarge.copyWith(
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
              decoration: InputDecoration(
                prefixText: 'S/ ',
                prefixStyle: AppTypography.moneyLarge.copyWith(
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
                hintText: '0.00',
              ),
            ),
            AppSpacing.verticalGapLg,

            // Categoría
            _SectionTitle(title: 'Categoría'),
            AppSpacing.verticalGapSm,
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: categories.map((category) {
                  final isSelected = _selectedCategory?.id == category.id;
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: AppColors.surface,
                  );
                }).toList(),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text('Error: $e'),
            ),
            AppSpacing.verticalGapLg,

            // Cajón (Fund)
            _SectionTitle(title: 'Cajón'),
            AppSpacing.verticalGapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ['Banco', 'Efectivo', 'Ahorros'].map((fund) {
                final isSelected = _selectedFundType == fund;
                return ChoiceChip(
                  label: Text(fund),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFundType = selected ? fund : null;
                    });
                  },
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
            AppSpacing.verticalGapLg,

            // Fecha
            _SectionTitle(title: 'Fecha'),
            AppSpacing.verticalGapSm,
            InkWell(
              onTap: _selectDate,
              borderRadius: AppSpacing.borderRadiusMd,
              child: Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.horizontalGapMd,
                    Text(
                      DateFormatter.fullDate(_selectedDate),
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalGapLg,

            // Nota
            _SectionTitle(title: 'Nota (opcional)'),
            AppSpacing.verticalGapSm,
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Añade una descripción...',
              ),
            ),
            AppSpacing.verticalGapXl,

            // Botón guardar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isIncome ? AppColors.income : AppColors.expense,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Text(isIncome ? 'Guardar ingreso' : 'Guardar gasto'),
              ),
            ),
            AppSpacing.verticalGapMd,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}
