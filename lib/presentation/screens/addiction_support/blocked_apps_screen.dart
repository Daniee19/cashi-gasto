import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/addiction_support_provider.dart';

class BlockedAppsScreen extends ConsumerWidget {
  const BlockedAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(blockedAppsNotifierProvider);
    final knownApps = ref.watch(knownBettingAppsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Apps y Sitios Bloqueados'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Apps', icon: Icon(Icons.apps, size: 20)),
              Tab(text: 'Sitios Web', icon: Icon(Icons.language, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AppsTab(appsAsync: appsAsync, knownApps: knownApps),
            const _DomainsTab(),
          ],
        ),
      ),
    );
  }
}

class _AppsTab extends ConsumerWidget {
  final AsyncValue<List<dynamic>> appsAsync;
  final List<KnownBettingApp> knownApps;

  const _AppsTab({required this.appsAsync, required this.knownApps});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return appsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (blockedApps) {
        final blockedPackages = blockedApps.map((a) => a.packageName).toSet();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bloquear apps te ayuda a evitar tentaciones. '
                      'Las apps bloqueadas no se desinstalan, solo las marcamos para recordarte.',
                      style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Apps bloqueadas
            if (blockedApps.isNotEmpty) ...[
              const Text(
                'Apps bloqueadas',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ...blockedApps.map((app) => _BlockedAppTile(
                name: app.appName,
                packageName: app.packageName,
                onRemove: () {
                  ref.read(blockedAppsNotifierProvider.notifier).removeApp(app.id);
                },
              )),
              const SizedBox(height: 24),
            ],

            // Sugerencias
            const Text(
              'Apps sugeridas para bloquear',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...knownApps
                .where((app) => !blockedPackages.contains(app.packageName))
                .map((app) => _SuggestedAppTile(
                      name: app.name,
                      packageName: app.packageName,
                      icon: app.icon,
                      onBlock: () {
                        ref.read(blockedAppsNotifierProvider.notifier).addApp(app.name, app.packageName);
                      },
                    )),

            const SizedBox(height: 24),

            // Agregar manual
            OutlinedButton.icon(
              onPressed: () => _showAddAppDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Agregar otra app'),
            ),
          ],
        );
      },
    );
  }

  void _showAddAppDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final packageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar app'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la app'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: packageController,
              decoration: const InputDecoration(
                labelText: 'Nombre del paquete (opcional)',
                hintText: 'com.ejemplo.app',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final pkg = packageController.text.trim().isEmpty ? 'custom.$name' : packageController.text.trim();
                ref.read(blockedAppsNotifierProvider.notifier).addApp(name, pkg);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

class _BlockedAppTile extends StatelessWidget {
  final String name;
  final String packageName;
  final VoidCallback onRemove;

  const _BlockedAppTile({
    required this.name,
    required this.packageName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.block, color: Colors.red),
        ),
        title: Text(name),
        subtitle: Text(packageName, style: const TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _SuggestedAppTile extends StatelessWidget {
  final String name;
  final String packageName;
  final String icon;
  final VoidCallback onBlock;

  const _SuggestedAppTile({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(name),
        trailing: OutlinedButton(
          onPressed: onBlock,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('Bloquear'),
        ),
      ),
    );
  }
}

class _DomainsTab extends ConsumerWidget {
  const _DomainsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainsAsync = ref.watch(blockedDomainsNotifierProvider);
    final knownDomains = ref.watch(knownBettingDomainsProvider);

    return domainsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (blockedDomains) {
        final blockedUrls = blockedDomains.map((d) => d.url).toSet();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los sitios bloqueados se guardan como recordatorio. '
                      'Para bloqueo efectivo, usa un bloqueador de navegador o configura tu router.',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dominios bloqueados
            if (blockedDomains.isNotEmpty) ...[
              const Text(
                'Sitios bloqueados',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ...blockedDomains.map((domain) => _BlockedDomainTile(
                url: domain.url,
                onRemove: () {
                  ref.read(blockedDomainsNotifierProvider.notifier).removeDomain(domain.id);
                },
              )),
              const SizedBox(height: 24),
            ],

            // Sugerencias
            const Text(
              'Sitios sugeridos para bloquear',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...knownDomains.where((url) => !blockedUrls.contains(url)).map(
                  (url) => _SuggestedDomainTile(
                    url: url,
                    onBlock: () {
                      ref.read(blockedDomainsNotifierProvider.notifier).addDomain(url);
                    },
                  ),
                ),

            const SizedBox(height: 24),

            // Agregar manual
            OutlinedButton.icon(
              onPressed: () => _showAddDomainDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Agregar otro sitio'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDomainDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar sitio'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL del sitio',
            hintText: 'ejemplo.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ref.read(blockedDomainsNotifierProvider.notifier).addDomain(url);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

class _BlockedDomainTile extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _BlockedDomainTile({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.block, color: Colors.red),
        ),
        title: Text(url),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _SuggestedDomainTile extends StatelessWidget {
  final String url;
  final VoidCallback onBlock;

  const _SuggestedDomainTile({required this.url, required this.onBlock});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.language, color: Colors.grey),
        ),
        title: Text(url),
        trailing: OutlinedButton(
          onPressed: onBlock,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('Bloquear'),
        ),
      ),
    );
  }
}
