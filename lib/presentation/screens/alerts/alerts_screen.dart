import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../widgets/cashito_mascot.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 12),
                    Text('Marcar todo como leido'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 12),
                    Text('Eliminar leidas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Eliminar todas', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  isSelected: _selectedFilter == null,
                  onTap: () => setState(() => _selectedFilter = null),
                ),
                const SizedBox(width: 8),
                ...AlertType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: type.displayName,
                    isSelected: _selectedFilter == type,
                    onTap: () => setState(() => _selectedFilter = type),
                    color: _getTypeColor(type),
                  ),
                )),
              ],
            ),
          ),

          // Alerts list
          Expanded(
            child: alertsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(alertNotifierProvider.notifier).loadAlerts(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (alerts) {
                final filteredAlerts = _selectedFilter == null
                    ? alerts
                    : alerts.where((a) => a.alertType == _selectedFilter).toList();

                if (filteredAlerts.isEmpty) {
                  return CashitoEmptyState(
                    mood: CashitoMood.noNotifications,
                    title: _selectedFilter == null
                        ? 'No tienes alertas'
                        : 'No hay alertas de este tipo',
                    subtitle: 'Todo esta en orden',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(alertNotifierProvider.notifier).loadAlerts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return _AlertCard(
                        alert: alert,
                        onTap: () => _markAsRead(alert),
                        onDismissed: () => _deleteAlert(alert),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(AlertType type) {
    switch (type) {
      case AlertType.budgetWarning:
        return Colors.orange;
      case AlertType.goalReminder:
        return AppColors.success;
      case AlertType.loanDue:
        return Colors.red;
      case AlertType.streakMilestone:
        return AppColors.primary;
      case AlertType.general:
        return Colors.blueGrey;
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'mark_all_read':
        await ref.read(alertNotifierProvider.notifier).markAllAsRead();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todas las alertas marcadas como leidas')),
          );
        }
        break;
      case 'delete_read':
        final confirm = await _showConfirmDialog(
          'Eliminar alertas leidas',
          '¿Eliminar todas las alertas que ya leiste?',
        );
        if (confirm == true) {
          await ref.read(alertNotifierProvider.notifier).deleteReadAlerts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alertas leidas eliminadas')),
            );
          }
        }
        break;
      case 'delete_all':
        final confirm = await _showConfirmDialog(
          'Eliminar todas las alertas',
          '¿Estas seguro de eliminar todas las alertas? Esta accion no se puede deshacer.',
        );
        if (confirm == true) {
          await ref.read(alertNotifierProvider.notifier).deleteAllAlerts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Todas las alertas eliminadas')),
            );
          }
        }
        break;
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _markAsRead(Alert alert) async {
    if (!alert.isRead) {
      await ref.read(alertNotifierProvider.notifier).markAsRead(alert.id);
    }
  }

  void _deleteAlert(Alert alert) async {
    await ref.read(alertNotifierProvider.notifier).deleteAlert(alert.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alerta "${alert.title}" eliminada'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              // Re-create the alert
              ref.read(alertNotifierProvider.notifier).addAlert(
                alertType: alert.alertType,
                title: alert.title,
                message: alert.message,
                alertDate: alert.alertDate,
              );
            },
          ),
        ),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: alert.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: alert.isRead
                  ? Colors.grey[200]!
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(alert.alertType).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTypeIcon(alert.alertType),
                  color: _getTypeColor(alert.alertType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(alert.alertType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.alertType.displayName,
                            style: TextStyle(
                              color: _getTypeColor(alert.alertType),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(alert.alertDate),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(AlertType type) {
    switch (type) {
      case AlertType.budgetWarning:
        return Colors.orange;
      case AlertType.goalReminder:
        return AppColors.success;
      case AlertType.loanDue:
        return Colors.red;
      case AlertType.streakMilestone:
        return AppColors.primary;
      case AlertType.general:
        return Colors.blueGrey;
    }
  }

  IconData _getTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.budgetWarning:
        return Icons.warning_amber_rounded;
      case AlertType.goalReminder:
        return Icons.flag_outlined;
      case AlertType.loanDue:
        return Icons.payment;
      case AlertType.streakMilestone:
        return Icons.emoji_events_outlined;
      case AlertType.general:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${DateFormat.Hm().format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} dias';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
