import '../data/models/transaction.dart';

/// Datos extraídos de una notificación bancaria
class ParsedBankNotification {
  final double amount;
  final TransactionType type;
  final String description;
  final String sourceApp;
  final String rawText;
  final DateTime detectedAt;

  const ParsedBankNotification({
    required this.amount,
    required this.type,
    required this.description,
    required this.sourceApp,
    required this.rawText,
    required this.detectedAt,
  });

  /// Hash para detección de duplicados (mismo monto + minuto)
  String get deduplicationKey {
    final minuteKey = '${detectedAt.year}${detectedAt.month}${detectedAt.day}${detectedAt.hour}${detectedAt.minute}';
    return '${sourceApp}_${amount}_${type.value}_$minuteKey';
  }
}

/// Parsea notificaciones de apps bancarias peruanas
class SmsParserService {
  /// Paquetes de apps bancarias que monitoreamos
  static const Map<String, String> bankPackages = {
    'com.bcp.innovacxion.yapeapp': 'Yape',
    'com.bcp.bank.bcp': 'BCP',
    'pe.interbank.mobilebanking': 'Interbank',
    'com.bbva.peru': 'BBVA',
    'com.scotiabank.peru': 'Scotiabank',
    'pe.com.bn.app.bancodelanacion': 'Banco de la Nacion',
    'com.android.mms': 'SMS',           // SMS genéricos
    'com.google.android.apps.messaging': 'SMS', // Google Messages
    'com.samsung.android.messaging': 'SMS',     // Samsung Messages
  };

  /// Retorna true si el paquete es una app bancaria monitoreada
  static bool isBankApp(String packageName) => bankPackages.containsKey(packageName);

  /// Intenta parsear el texto de una notificación bancaria
  /// Retorna null si no se pudo extraer datos útiles
  static ParsedBankNotification? parse(String packageName, String title, String text) {
    final appName = bankPackages[packageName] ?? packageName;
    final fullText = '$title $text';
    final lower = fullText.toLowerCase();

    // Intentar cada parser en orden
    final parsers = [
      _parseYape,
      _parseBcp,
      _parseInterbank,
      _parseBbva,
      _parseScotiabank,
      _parseGenericBank,
    ];

    for (final parser in parsers) {
      final result = parser(lower, fullText, appName);
      if (result != null) return result;
    }

    return null;
  }

  // ─── Parsers por banco ─────────────────────────────────────

  static ParsedBankNotification? _parseYape(String lower, String raw, String app) {
    if (!lower.contains('yape') && app != 'Yape') return null;

    final amount = _extractAmount(raw);
    if (amount == null) return null;

    final isIncome = lower.contains('recibiste') ||
        lower.contains('te envió') ||
        lower.contains('te envio') ||
        lower.contains('depósito') ||
        lower.contains('deposito');

    // Extraer nombre de la persona
    String description = 'Yape';
    final namePatterns = [
      RegExp(r'(?:de|a)\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*)', caseSensitive: true),
    ];
    for (final pattern in namePatterns) {
      final match = pattern.firstMatch(raw);
      if (match != null) {
        description = '${isIncome ? "Yape de" : "Yape a"} ${match.group(1)}';
        break;
      }
    }

    return ParsedBankNotification(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      description: description,
      sourceApp: 'Yape',
      rawText: raw,
      detectedAt: DateTime.now(),
    );
  }

  static ParsedBankNotification? _parseBcp(String lower, String raw, String app) {
    if (!lower.contains('bcp') && app != 'BCP') return null;

    final amount = _extractAmount(raw);
    if (amount == null) return null;

    final isIncome = lower.contains('recibiste') ||
        lower.contains('abono') ||
        lower.contains('transferencia recibida') ||
        lower.contains('depósito') ||
        lower.contains('deposito');

    String description = 'BCP';
    // Extraer comercio: "en COMERCIO XYZ"
    final comercio = RegExp(r'en\s+(.+?)(?:\s+con|\s+TC|\s+TD|\.|$)', caseSensitive: false).firstMatch(raw);
    if (comercio != null) {
      description = 'BCP - ${comercio.group(1)!.trim()}';
    }

    return ParsedBankNotification(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      description: description,
      sourceApp: 'BCP',
      rawText: raw,
      detectedAt: DateTime.now(),
    );
  }

  static ParsedBankNotification? _parseInterbank(String lower, String raw, String app) {
    if (!lower.contains('interbank') && !lower.contains('ibk') && app != 'Interbank') return null;

    final amount = _extractAmount(raw);
    if (amount == null) return null;

    final isIncome = lower.contains('recibiste') ||
        lower.contains('abono') ||
        lower.contains('deposito');

    String description = 'Interbank';
    final comercio = RegExp(r'en\s+(.+?)(?:\s+con|\.|$)', caseSensitive: false).firstMatch(raw);
    if (comercio != null) {
      description = 'Interbank - ${comercio.group(1)!.trim()}';
    }

    return ParsedBankNotification(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      description: description,
      sourceApp: 'Interbank',
      rawText: raw,
      detectedAt: DateTime.now(),
    );
  }

  static ParsedBankNotification? _parseBbva(String lower, String raw, String app) {
    if (!lower.contains('bbva') && app != 'BBVA') return null;

    final amount = _extractAmount(raw);
    if (amount == null) return null;

    final isIncome = lower.contains('recibiste') ||
        lower.contains('abono') ||
        lower.contains('deposito');

    String description = 'BBVA';
    final comercio = RegExp(r'en\s+(.+?)(?:\s+con|\.|$)', caseSensitive: false).firstMatch(raw);
    if (comercio != null) {
      description = 'BBVA - ${comercio.group(1)!.trim()}';
    }

    return ParsedBankNotification(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      description: description,
      sourceApp: 'BBVA',
      rawText: raw,
      detectedAt: DateTime.now(),
    );
  }

  static ParsedBankNotification? _parseScotiabank(String lower, String raw, String app) {
    if (!lower.contains('scotiabank') && app != 'Scotiabank') return null;

    final amount = _extractAmount(raw);
    if (amount == null) return null;

    final isIncome = lower.contains('recibiste') ||
        lower.contains('abono') ||
        lower.contains('deposito');

    return ParsedBankNotification(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      description: 'Scotiabank',
      sourceApp: 'Scotiabank',
      rawText: raw,
      detectedAt: DateTime.now(),
    );
  }

  /// Parser genérico para SMS bancarios no reconocidos
  static ParsedBankNotification? _parseGenericBank(String lower, String raw, String app) {
    // Solo para SMS que parezcan bancarios
    final hasBankKeywords = lower.contains('consumo') ||
        lower.contains('compra') ||
        lower.contains('transferencia') ||
        lower.contains('operacion') ||
        lower.contains('retiro') ||
        lower.contains('deposito') ||
        lower.contains('pago');

    if (!hasBankKeywords) return null;

    final amount = _extractAmount(raw);
    if (amount == null) return null;

    final isIncome = lower.contains('deposito') ||
        lower.contains('abono') ||
        lower.contains('recibiste');

    return ParsedBankNotification(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      description: 'Transaccion bancaria',
      sourceApp: app,
      rawText: raw,
      detectedAt: DateTime.now(),
    );
  }

  // ─── Utilidades ────────────────────────────────────────────

  /// Extrae monto de texto con patrones peruanos
  static double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'S/\.?\s*(\d[\d,]*\.?\d*)', caseSensitive: false),
      RegExp(r'(\d[\d,]*\.\d{2})\s*(?:soles|PEN)', caseSensitive: false),
      RegExp(r'(?:por|de|monto)\s*:?\s*S?/?\.?\s*(\d[\d,]*\.?\d*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final value = double.tryParse(raw);
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }
}
