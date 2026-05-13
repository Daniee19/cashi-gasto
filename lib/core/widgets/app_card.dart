import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Card reutilizable con estilo consistente
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool hasShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: card,
      );
    }

    return card;
  }
}
