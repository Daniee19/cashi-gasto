import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AppSpacing.verticalGapMd,
            Text(
              'Aquí verás tus reportes financieros',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
