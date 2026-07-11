import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_parser_service.dart';

/// Servicio que escucha notificaciones del sistema y detecta transacciones bancarias.
/// Solo funciona en Android.
class TransactionNotificationService {
  static TransactionNotificationService? _instance;
  static TransactionNotificationService get instance =>
      _instance ??= TransactionNotificationService._();

  TransactionNotificationService._();

  StreamSubscription<ServiceNotificationEvent>? _subscription;
  final _transactionController = StreamController<ParsedBankNotification>.broadcast();

  /// Stream de transacciones detectadas para que la UI/provider las consuma
  Stream<ParsedBankNotification> get onTransactionDetected => _transactionController.stream;

  /// Keys de notificaciones ya procesadas (deduplicación en memoria)
  final Set<String> _processedKeys = {};

  /// Verificar si el permiso de notificaciones está concedido
  Future<bool> get isPermissionGranted =>
      NotificationListenerService.isPermissionGranted();

  /// Abrir ajustes del sistema para conceder el permiso
  Future<void> requestPermission() =>
      NotificationListenerService.requestPermission();

  /// Iniciar la escucha de notificaciones
  Future<void> startListening() async {
    if (_subscription != null) return; // ya escuchando

    final hasPermission = await isPermissionGranted;
    if (!hasPermission) {
      debugPrint('TransactionNotificationService: sin permiso de notificaciones');
      return;
    }

    _subscription = NotificationListenerService.notificationsStream.listen(
      _handleNotification,
      onError: (e) => debugPrint('Error en notification listener: $e'),
    );

    debugPrint('TransactionNotificationService: escucha iniciada');
  }

  /// Detener la escucha
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('TransactionNotificationService: escucha detenida');
  }

  void _handleNotification(ServiceNotificationEvent event) {
    final packageName = event.packageName ?? '';
    final title = event.title ?? '';
    final text = event.content ?? '';

    // Filtrar: solo apps bancarias
    if (!SmsParserService.isBankApp(packageName)) return;

    // Parsear
    final parsed = SmsParserService.parse(packageName, title, text);
    if (parsed == null) return;

    // Deduplicar
    if (_processedKeys.contains(parsed.deduplicationKey)) return;
    _processedKeys.add(parsed.deduplicationKey);

    // ponytail: limpiar keys viejas cada 100 entradas para no crecer infinito
    if (_processedKeys.length > 100) {
      _processedKeys.clear();
    }

    debugPrint('TransactionNotificationService: detectada ${parsed.type.value} S/ ${parsed.amount} de ${parsed.sourceApp}');
    _transactionController.add(parsed);
  }

  void dispose() {
    stopListening();
    _transactionController.close();
    _instance = null;
  }
}

// ─── Preferencias de configuración ──────────────────────────

class SmsSettingsService {
  static const _keyEnabled = 'sms_detection_enabled';
  static const _keyAutoRegister = 'sms_auto_register';
  static const _keyDefaultFundId = 'sms_default_fund_id';
  static const _keyDisabledApps = 'sms_disabled_apps';

  final SharedPreferences _prefs;
  SmsSettingsService(this._prefs);

  bool get isEnabled => _prefs.getBool(_keyEnabled) ?? false;
  Future<void> setEnabled(bool value) => _prefs.setBool(_keyEnabled, value);

  bool get isAutoRegister => _prefs.getBool(_keyAutoRegister) ?? false;
  Future<void> setAutoRegister(bool value) => _prefs.setBool(_keyAutoRegister, value);

  String? get defaultFundId => _prefs.getString(_keyDefaultFundId);
  Future<void> setDefaultFundId(String? value) =>
      value != null ? _prefs.setString(_keyDefaultFundId, value) : _prefs.remove(_keyDefaultFundId);

  Set<String> get disabledApps =>
      (_prefs.getStringList(_keyDisabledApps) ?? []).toSet();
  Future<void> setDisabledApps(Set<String> apps) =>
      _prefs.setStringList(_keyDisabledApps, apps.toList());

  bool isAppEnabled(String packageName) => !disabledApps.contains(packageName);

  Future<void> toggleApp(String packageName, bool enabled) async {
    final apps = disabledApps;
    if (enabled) {
      apps.remove(packageName);
    } else {
      apps.add(packageName);
    }
    await setDisabledApps(apps);
  }
}
