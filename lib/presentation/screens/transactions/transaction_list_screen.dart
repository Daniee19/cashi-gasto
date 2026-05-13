import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactions),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter options
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show search
            },
          ),
        ],
      ),
      body: Center(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTransaction),
        child: const Icon(Icons.add),
      ),
    );
  }
}
