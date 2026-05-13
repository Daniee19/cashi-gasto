import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Sección de cuenta
          _SectionHeader(title: 'Cuenta'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Perfil',
            subtitle: 'Editar información personal',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Configurar alertas',
            onTap: () {},
          ),
          AppSpacing.verticalGapLg,

          // Sección de preferencias
          _SectionHeader(title: 'Preferencias'),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Categorías',
            subtitle: 'Gestionar categorías',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cajones',
            subtitle: 'Configurar fondos',
            onTap: () {},
          ),
          AppSpacing.verticalGapLg,

          // Sección de ayuda
          _SectionHeader(title: 'Ayuda'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Centro de ayuda',
            subtitle: 'Preguntas frecuentes',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacidad',
            subtitle: 'Políticas y términos',
            onTap: () {},
          ),
          AppSpacing.verticalGapLg,

          // Cerrar sesión
          _SettingsTile(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            subtitle: 'Salir de la cuenta',
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: () => _showLogoutDialog(context, ref),
          ),
          AppSpacing.verticalGapXl,

          // Versión
          Center(
            child: Text(
              'Versión 1.0.0',
              style: AppTypography.bodySmall,
            ),
          ),
          AppSpacing.verticalGapMd,
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.grey400,
      ),
      onTap: onTap,
    );
  }
}
