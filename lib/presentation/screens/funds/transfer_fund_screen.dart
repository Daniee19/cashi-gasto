import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fund.dart';
import '../../providers/fund_provider.dart';

class TransferFundScreen extends ConsumerStatefulWidget {
  const TransferFundScreen({super.key});

  @override
  ConsumerState<TransferFundScreen> createState() => _TransferFundScreenState();
}

class _TransferFundScreenState extends ConsumerState<TransferFundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Fund? _fromFund;
  Fund? _toFund;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fundsAsync = ref.watch(fundNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferir entre Fondos'),
      ),
      body: fundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (funds) {
          if (funds.length < 2) {
            return _buildInsufficientFunds(context);
          }
          return _buildTransferForm(context, funds);
        },
      ),
    );
  }

  Widget _buildInsufficientFunds(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 80,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Necesitas al menos 2 fondos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea otro fondo para poder hacer transferencias',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferForm(BuildContext context, List<Fund> funds) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transfer illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFundPreview(_fromFund, 'Origen'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  _buildFundPreview(_toFund, 'Destino'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // From Fund selector
            Text(
              'Desde',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            _buildFundSelector(
              funds: funds.where((f) => f.id != _toFund?.id).toList(),
              selectedFund: _fromFund,
              hint: 'Seleccionar fondo de origen',
              onChanged: (fund) {
                setState(() => _fromFund = fund);
              },
            ),
            if (_fromFund != null) ...[
              const SizedBox(height: 4),
              Text(
                'Disponible: \$${_fromFund!.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.income,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // To Fund selector
            Text(
              'Hacia',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            _buildFundSelector(
              funds: funds.where((f) => f.id != _fromFund?.id).toList(),
              selectedFund: _toFund,
              hint: 'Seleccionar fondo de destino',
              onChanged: (fund) {
                setState(() => _toFund = fund);
              },
            ),
            const SizedBox(height: 24),

            // Amount field
            Text(
              'Monto a transferir',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                suffixIcon: _fromFund != null
                    ? TextButton(
                        onPressed: () {
                          _amountController.text = _fromFund!.balance.toStringAsFixed(2);
                        },
                        child: const Text('MAX'),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto valido';
                }
                if (_fromFund != null && amount > _fromFund!.balance) {
                  return 'Saldo insuficiente';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Note field (optional)
            Text(
              'Nota (opcional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Agrega una nota...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Transfer button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleTransfer,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Transferir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundPreview(Fund? fund, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: fund != null
                ? _getFundColor(fund.type).withValues(alpha: 0.1)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            fund != null ? _getFundIcon(fund.type) : Icons.help_outline,
            color: fund != null ? _getFundColor(fund.type) : Colors.grey,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          fund?.name ?? label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: fund != null ? Colors.black : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFundSelector({
    required List<Fund> funds,
    required Fund? selectedFund,
    required String hint,
    required ValueChanged<Fund?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Fund>(
          value: selectedFund,
          isExpanded: true,
          hint: Text(hint),
          items: funds.map((fund) {
            return DropdownMenuItem<Fund>(
              value: fund,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getFundColor(fund.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFundIcon(fund.type),
                      color: _getFundColor(fund.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fund.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '\$${fund.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
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

  Color _getFundColor(FundType type) {
    switch (type) {
      case FundType.general:
        return AppColors.primary;
      case FundType.bank:
        return AppColors.info;
      case FundType.cash:
        return AppColors.income;
      case FundType.savings:
        return AppColors.warning;
    }
  }

  Future<void> _handleTransfer() async {
    if (_fromFund == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el fondo de origen')),
      );
      return;
    }
    if (_toFund == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el fondo de destino')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final result = await ref.read(fundNotifierProvider.notifier).transferBetweenFunds(
          fromFundId: _fromFund!.id,
          toFundId: _toFund!.id,
          amount: amount,
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transferencia de \$${amount.toStringAsFixed(2)} completada'),
            backgroundColor: AppColors.income,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Error al realizar la transferencia'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }
}
