import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/addiction_support_provider.dart';

class SupportResourcesScreen extends ConsumerWidget {
  const SupportResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(supportResourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos de Ayuda'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.teal.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🤝', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  'No estas solo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hay personas y organizaciones listas para ayudarte',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lineas de emergencia
          const Text(
            'Lineas de ayuda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...resources.map((r) => _ResourceCard(resource: r)),

          const SizedBox(height: 24),

          // Tips de emergencia
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'En caso de urgencia',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TipItem(text: 'Llama a alguien de confianza inmediatamente'),
                _TipItem(text: 'Alejate de cualquier dispositivo o lugar de apuestas'),
                _TipItem(text: 'Respira profundo y espera 15 minutos'),
                _TipItem(text: 'Recuerda por que empezaste este camino'),
                _TipItem(text: 'Busca una actividad que te distraiga'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Consejos generales
          const Text(
            'Estrategias que ayudan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _StrategyCard(
            icon: Icons.group,
            title: 'Busca apoyo grupal',
            description: 'Los grupos de apoyo como Jugadores Anonimos ofrecen un espacio seguro para compartir experiencias.',
          ),
          _StrategyCard(
            icon: Icons.psychology,
            title: 'Terapia profesional',
            description: 'Un psicologo especializado puede ayudarte a entender y manejar los impulsos.',
          ),
          _StrategyCard(
            icon: Icons.account_balance_wallet,
            title: 'Control financiero',
            description: 'Limita tu acceso al dinero. Considera que alguien de confianza administre tus finanzas temporalmente.',
          ),
          _StrategyCard(
            icon: Icons.schedule,
            title: 'Ocupa tu tiempo',
            description: 'Llena el tiempo que antes dedicabas a apostar con actividades saludables.',
          ),
          _StrategyCard(
            icon: Icons.fitness_center,
            title: 'Cuida tu cuerpo',
            description: 'El ejercicio fisico ayuda a liberar endorfinas y reduce la ansiedad.',
          ),

          const SizedBox(height: 32),

          // Mensaje final
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  '💪',
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(height: 8),
                Text(
                  'Cada dia es una nueva oportunidad',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'El camino a la recuperacion no es lineal, pero cada paso cuenta.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final SupportResource resource;

  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(resource.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        resource.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _call(resource.phone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(resource.phone),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (resource.website != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openWeb(resource.website!),
                    icon: const Icon(Icons.language, size: 18),
                    label: const Text('Web'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWeb(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.purple.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _StrategyCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
