import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Indicador de carga centrado
class AppLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  const AppLoading({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: color ?? AppColors.primary,
          ),
          if (message != null) ...[
            AppSpacing.verticalGapMd,
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay de carga para bloquear interacción
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: AppLoading(message: message),
          ),
      ],
    );
  }
}
