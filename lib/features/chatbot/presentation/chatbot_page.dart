import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente'),
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chatbot Financiero',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AppSpacing.verticalGapMd,
            Text(
              'Tu asistente para consejos financieros',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
