import 'package:intl/intl.dart';

/// Utilidades para formatear moneda
abstract final class CurrencyFormatter {
  static final _penFormatter = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 0,
  );

  /// Formatea un monto como moneda peruana
  /// Ejemplo: 1234.56 -> "S/ 1,234.56"
  static String format(double amount) {
    return _penFormatter.format(amount);
  }

  /// Formatea un monto de forma compacta
  /// Ejemplo: 1234567 -> "S/ 1.2M"
  static String formatCompact(double amount) {
    return _compactFormatter.format(amount);
  }

  /// Formatea un monto con signo
  /// Ejemplo: -1234.56 -> "- S/ 1,234.56"
  static String formatWithSign(double amount) {
    final sign = amount >= 0 ? '' : '- ';
    return '$sign${_penFormatter.format(amount.abs())}';
  }
}
