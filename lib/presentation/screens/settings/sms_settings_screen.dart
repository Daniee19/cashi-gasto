import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fund.dart';
import '../../../data/models/transaction.dart';
import '../../../services/sms_parser_service.dart';
import '../../../services/transaction_notification_service.dart';
import '../../providers/fund_provider.dart';
import '../../providers/sms_settings_provider.dart';

class SmsSettingsScreen extends ConsumerStatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  ConsumerState<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends ConsumerState<SmsSettingsScreen> {
  bool _hasPermission = false;
  StreamSubscription<ParsedBankNotification>? _pendingSubscription;
  final List<ParsedBankNotification> _pendingTransactions = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _listenForPending();
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final granted = await TransactionNotificationService.instance.isPermissionGranted;
    if (mounted) setState(() => _hasPermission = granted);
  }

  void _listenForPending() {
    _pendingSubscription = TransactionNotificationService.instance
        .onTransactionDetected
        .listen((notification) {
      final settings = ref.read(smsSettingsNotifierProvider);
      if (!settings.isAutoRegister && mounted) {
        setState(() => _pendingTransactions.add(notification));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(smsSettingsNotifierProvider);
    final notifier = ref.read(smsSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteccion automatica'),
      ),
      body: ListView(
        children: [
          // Header informativo
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Registro automatico',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Detecta pagos de Yape, BCP y mas desde sus notificaciones',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Toggle principal
          _buildSection(
            children: [
              SwitchListTile(
                value: settings.isEnabled,
                onChanged: (value) async {
                  await notifier.toggleEnabled(value);
                  await _checkPermission();
                },
                title: const Text('Activar deteccion', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Escuchar notificaciones de apps bancarias'),
                secondary: Icon(
                  settings.isEnabled ? Icons.sensors : Icons.sensors_off,
                  color: settings.isEnabled ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),

          // Permiso (si está activado pero sin permiso)
          if (settings.isEnabled && !_hasPermission)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Permiso requerido', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Debes permitir el acceso a notificaciones en los ajustes del sistema',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await TransactionNotificationService.instance.requestPermission();
                              await Future.delayed(const Duration(seconds: 1));
                              await _checkPermission();
                            },
                            icon: const Icon(Icons.settings, size: 16),
                            label: const Text('Abrir ajustes', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (settings.isEnabled) ...[
            // Modo de registro
            _buildSection(
              title: 'Modo de registro',
              children: [
                SwitchListTile(
                  value: settings.isAutoRegister,
                  onChanged: (value) => notifier.toggleAutoRegister(value),
                  title: const Text('Registro automatico'),
                  subtitle: Text(
                    settings.isAutoRegister
                        ? 'Las transacciones se registran sin preguntar'
                        : 'Se mostrara una notificacion para confirmar',
                    style: const TextStyle(fontSize: 13),
                  ),
                  secondary: Icon(
                    settings.isAutoRegister ? Icons.flash_on : Icons.touch_app,
                    color: settings.isAutoRegister ? AppColors.warning : AppColors.info,
                  ),
                ),
              ],
            ),

            // Cuenta por defecto
            _buildSection(
              title: 'Cuenta por defecto',
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final fundsAsync = ref.watch(fundsProvider);
                    return fundsAsync.when(
                      loading: () => const ListTile(title: Text('Cargando...')),
                      error: (e, _) => ListTile(title: Text('Error: $e')),
                      data: (funds) => ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: AppColors.info, size: 20),
                        ),
                        title: Text(
                          _getSelectedFundName(funds, settings.defaultFundId),
                          style: TextStyle(
                            color: settings.defaultFundId != null ? null : AppColors.textMuted,
                          ),
                        ),
                        subtitle: const Text('Donde se registraran las transacciones', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showFundPicker(funds, settings.defaultFundId, notifier),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Apps monitoreadas
            _buildSection(
              title: 'Apps monitoreadas',
              children: SmsParserService.bankPackages.entries
                  .where((e) => e.value != 'SMS') // agrupar SMS aparte
                  .map((entry) => SwitchListTile(
                        value: !settings.disabledApps.contains(entry.key),
                        onChanged: (enabled) => notifier.toggleApp(entry.key, enabled),
                        title: Text(entry.value),
                        subtitle: Text(_getAppDescription(entry.value), style: const TextStyle(fontSize: 12)),
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor: _getAppColor(entry.value).withOpacity(0.1),
                          child: Text(
                            entry.value[0],
                            style: TextStyle(color: _getAppColor(entry.value), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // SMS genéricos
            _buildSection(
              title: 'SMS bancarios',
              children: [
                SwitchListTile(
                  value: !settings.disabledApps.contains('com.android.mms') &&
                      !settings.disabledApps.contains('com.google.android.apps.messaging'),
                  onChanged: (enabled) {
                    notifier.toggleApp('com.android.mms', enabled);
                    notifier.toggleApp('com.google.android.apps.messaging', enabled);
                    notifier.toggleApp('com.samsung.android.messaging', enabled);
                  },
                  title: const Text('Mensajes SMS'),
                  subtitle: const Text('Detectar transacciones de SMS bancarios', style: TextStyle(fontSize: 12)),
                  secondary: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sms, color: AppColors.success, size: 20),
                  ),
                ),
              ],
            ),

            // Transacciones pendientes de confirmar
            if (_pendingTransactions.isNotEmpty)
              _buildSection(
                title: 'Pendientes de confirmar',
                children: _pendingTransactions.map((t) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (t.type == TransactionType.income ? AppColors.income : AppColors.expense)
                        .withOpacity(0.1),
                    child: Icon(
                      t.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                      color: t.type == TransactionType.income ? AppColors.income : AppColors.expense,
                      size: 20,
                    ),
                  ),
                  title: Text('S/ ${t.amount.toStringAsFixed(2)}'),
                  subtitle: Text(t.description, style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => setState(() => _pendingTransactions.remove(t)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.success),
                        onPressed: () async {
                          await notifier.confirmTransaction(t);
                          if (mounted) setState(() => _pendingTransactions.remove(t));
                        },
                      ),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({String? title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted,
            )),
          ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showFundPicker(List<Fund> funds, String? currentId, SmsSettingsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Cuenta por defecto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Opción "sin cuenta"
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.textMuted),
              title: const Text('Sin cuenta por defecto'),
              trailing: currentId == null ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                notifier.setDefaultFundId(null);
                Navigator.pop(context);
              },
            ),
            ...funds.map((fund) => ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: AppColors.info, size: 18),
              ),
              title: Text(fund.name),
              subtitle: Text(fund.type.displayName, style: const TextStyle(fontSize: 12)),
              trailing: currentId == fund.id ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                notifier.setDefaultFundId(fund.id);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getSelectedFundName(List<Fund> funds, String? fundId) {
    if (fundId == null) return 'Seleccionar cuenta';
    return funds.where((f) => f.id == fundId).firstOrNull?.name ?? 'Seleccionar cuenta';
  }

  String _getAppDescription(String appName) {
    switch (appName) {
      case 'Yape': return 'Pagos y transferencias Yape';
      case 'BCP': return 'Banco de Credito del Peru';
      case 'Interbank': return 'Interbank app movil';
      case 'BBVA': return 'BBVA Continental';
      case 'Scotiabank': return 'Scotiabank Peru';
      case 'Banco de la Nacion': return 'Banco de la Nacion';
      default: return appName;
    }
  }

  Color _getAppColor(String appName) {
    switch (appName) {
      case 'Yape': return const Color(0xFF6B21A8);
      case 'BCP': return const Color(0xFF003DA5);
      case 'Interbank': return const Color(0xFF00843D);
      case 'BBVA': return const Color(0xFF004481);
      case 'Scotiabank': return const Color(0xFFEC111A);
      case 'Banco de la Nacion': return const Color(0xFF003366);
      default: return AppColors.primary;
    }
  }
}
