import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metas Financieras',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AppSpacing.verticalGapMd,
            Text(
              'Aquí gestionarás tus metas de ahorro',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
