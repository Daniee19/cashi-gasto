import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/sms_parser_service.dart';
import '../../services/transaction_notification_service.dart';
import 'transaction_provider.dart';

/// Provider de SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Provider del servicio de configuración SMS
final smsSettingsServiceProvider = FutureProvider<SmsSettingsService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SmsSettingsService(prefs);
});

/// Provider del servicio de escucha de notificaciones (singleton)
final transactionNotificationServiceProvider = Provider<TransactionNotificationService>((ref) {
  return TransactionNotificationService.instance;
});

/// Estado reactivo de la configuración SMS
class SmsSettingsNotifier extends StateNotifier<SmsSettingsState> {
  final SmsSettingsService _settings;
  final TransactionNotificationService _notificationService;
  final Ref _ref;
  StreamSubscription<ParsedBankNotification>? _subscription;

  SmsSettingsNotifier(this._settings, this._notificationService, this._ref)
      : super(SmsSettingsState(
          isEnabled: _settings.isEnabled,
          isAutoRegister: _settings.isAutoRegister,
          defaultFundId: _settings.defaultFundId,
          disabledApps: _settings.disabledApps,
        )) {
    if (state.isEnabled) {
      _startListening();
    }
  }

  Future<void> toggleEnabled(bool enabled) async {
    await _settings.setEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);

    if (enabled) {
      final hasPermission = await _notificationService.isPermissionGranted;
      if (!hasPermission) {
        await _notificationService.requestPermission();
      }
      _startListening();
    } else {
      _stopListening();
    }
  }

  Future<void> toggleAutoRegister(bool auto) async {
    await _settings.setAutoRegister(auto);
    state = state.copyWith(isAutoRegister: auto);
  }

  Future<void> setDefaultFundId(String? fundId) async {
    await _settings.setDefaultFundId(fundId);
    state = state.copyWith(defaultFundId: fundId, clearFundId: fundId == null);
  }

  Future<void> toggleApp(String packageName, bool enabled) async {
    await _settings.toggleApp(packageName, enabled);
    state = state.copyWith(disabledApps: _settings.disabledApps);
  }

  void _startListening() {
    _notificationService.startListening();
    _subscription?.cancel();
    _subscription = _notificationService.onTransactionDetected.listen(
      _onTransactionDetected,
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _notificationService.stopListening();
  }

  void _onTransactionDetected(ParsedBankNotification notification) {
    // Verificar que la app no esté deshabilitada
    final packageEntry = SmsParserService.bankPackages.entries
        .where((e) => e.value == notification.sourceApp)
        .firstOrNull;
    if (packageEntry != null && !_settings.isAppEnabled(packageEntry.key)) return;

    if (state.isAutoRegister) {
      _autoRegisterTransaction(notification);
    }
    // Si no es auto, el stream sigue disponible para que la UI muestre confirmación
  }

  Future<void> _autoRegisterTransaction(ParsedBankNotification notification) async {
    final notifier = _ref.read(transactionNotifierProvider.notifier);
    await notifier.addTransaction(
      amount: notification.amount,
      type: notification.type,
      transactionDate: notification.detectedAt,
      fundId: state.defaultFundId,
      note: notification.description,
    );
  }

  /// Registrar manualmente una transacción detectada (modo confirmación)
  Future<bool> confirmTransaction(ParsedBankNotification notification, {String? fundId, String? categoryId}) {
    final notifier = _ref.read(transactionNotifierProvider.notifier);
    return notifier.addTransaction(
      amount: notification.amount,
      type: notification.type,
      transactionDate: notification.detectedAt,
      fundId: fundId ?? state.defaultFundId,
      categoryId: categoryId,
      note: notification.description,
    );
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}

/// Estado de la configuración SMS
class SmsSettingsState {
  final bool isEnabled;
  final bool isAutoRegister;
  final String? defaultFundId;
  final Set<String> disabledApps;

  const SmsSettingsState({
    this.isEnabled = false,
    this.isAutoRegister = false,
    this.defaultFundId,
    this.disabledApps = const {},
  });

  SmsSettingsState copyWith({
    bool? isEnabled,
    bool? isAutoRegister,
    String? defaultFundId,
    bool clearFundId = false,
    Set<String>? disabledApps,
  }) {
    return SmsSettingsState(
      isEnabled: isEnabled ?? this.isEnabled,
      isAutoRegister: isAutoRegister ?? this.isAutoRegister,
      defaultFundId: clearFundId ? null : (defaultFundId ?? this.defaultFundId),
      disabledApps: disabledApps ?? this.disabledApps,
    );
  }
}

/// Provider principal del notifier SMS
final smsSettingsNotifierProvider =
    StateNotifierProvider<SmsSettingsNotifier, SmsSettingsState>((ref) {
  // ponytail: acceso síncrono, si prefs no cargó aún usa defaults
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  final settings = prefs != null ? SmsSettingsService(prefs) : null;
  final notificationService = ref.watch(transactionNotificationServiceProvider);

  if (settings == null) {
    // Retornar notifier con estado por defecto hasta que prefs cargue
    return SmsSettingsNotifier(
      SmsSettingsService(prefs ?? _FallbackPrefs()),
      notificationService,
      ref,
    );
  }

  return SmsSettingsNotifier(settings, notificationService, ref);
});

/// Fallback mientras SharedPreferences carga
class _FallbackPrefs implements SharedPreferences {
  @override
  bool? getBool(String key) => null;
  @override
  String? getString(String key) => null;
  @override
  List<String>? getStringList(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool> setString(String key, String value) async => true;
  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
  @override
  Future<bool> remove(String key) async => true;

  // Stubs requeridos por la interfaz
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
