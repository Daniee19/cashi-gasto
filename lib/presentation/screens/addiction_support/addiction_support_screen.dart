import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/addiction_support_provider.dart';

class AddictionSupportScreen extends ConsumerWidget {
  const AddictionSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerAsync = ref.watch(abstinenceTrackerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo de Apoyo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header motivacional
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  '💪',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Estas en el camino correcto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cada dia sin apostar es una victoria',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tracker card
          trackerAsync.when(
            loading: () => const _TrackerCardLoading(),
            error: (e, _) => _TrackerCardError(error: e.toString()),
            data: (tracker) => _TrackerCard(
              tracker: tracker,
              onSetup: () => context.push(AppRoutes.abstinenceTracker),
            ),
          ),
          const SizedBox(height: 16),

          // Opciones
          const Text(
            'Herramientas de proteccion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          _OptionCard(
            icon: Icons.app_blocking,
            iconColor: Colors.red,
            title: 'Apps bloqueadas',
            subtitle: 'Bloquea apps de apuestas',
            onTap: () => context.push(AppRoutes.blockedApps),
          ),
          _OptionCard(
            icon: Icons.block,
            iconColor: Colors.orange,
            title: 'Sitios bloqueados',
            subtitle: 'Bloquea paginas de apuestas',
            onTap: () => context.push('${AppRoutes.blockedApps}/domains'),
          ),
          _OptionCard(
            icon: Icons.support_agent,
            iconColor: Colors.green,
            title: 'Recursos de ayuda',
            subtitle: 'Lineas de apoyo y especialistas',
            onTap: () => context.push(AppRoutes.supportResources),
          ),

          const SizedBox(height: 24),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tip del dia',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cuando sientas urgencia de apostar, espera 15 minutos. '
                  'La mayoria de los impulsos pasan en ese tiempo. '
                  'Usa ese tiempo para llamar a alguien o salir a caminar.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  final dynamic tracker;
  final VoidCallback onSetup;

  const _TrackerCard({required this.tracker, required this.onSetup});

  @override
  Widget build(BuildContext context) {
    if (tracker == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onSetup,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer, color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Iniciar contador de abstinencia',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lleva el registro de tus dias sin apostar',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Icon(Icons.arrow_forward, color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    }

    final days = tracker.currentStreakDays;
    final saved = tracker.dailyBetAverage * days;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onSetup,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    value: '$days',
                    label: 'dias',
                    icon: Icons.calendar_today,
                    color: AppColors.success,
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[200]),
                  _StatColumn(
                    value: 'S/ ${saved.toStringAsFixed(0)}',
                    label: 'ahorrado',
                    icon: Icons.savings,
                    color: AppColors.primary,
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[200]),
                  _StatColumn(
                    value: '${tracker.longestStreak}',
                    label: 'record',
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tracker.streakMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              if (tracker.isNewRecord) ...[
                const SizedBox(height: 4),
                const Text(
                  '🎉 Nuevo record personal!',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _TrackerCardLoading extends StatelessWidget {
  const _TrackerCardLoading();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TrackerCardError extends StatelessWidget {
  final String error;

  const _TrackerCardError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
