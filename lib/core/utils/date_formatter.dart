import 'package:intl/intl.dart';

/// Utilidades para formatear fechas
abstract final class DateFormatter {
  static final _dayMonth = DateFormat('d MMM', 'es_ES');
  static final _dayMonthYear = DateFormat('d MMM yyyy', 'es_ES');
  static final _fullDate = DateFormat('EEEE, d MMMM yyyy', 'es_ES');
  static final _monthYear = DateFormat('MMMM yyyy', 'es_ES');
  static final _time = DateFormat('HH:mm', 'es_ES');

  /// Formato corto: "15 Mar"
  static String shortDate(DateTime date) {
    return _dayMonth.format(date);
  }

  /// Formato con año: "15 Mar 2024"
  static String mediumDate(DateTime date) {
    return _dayMonthYear.format(date);
  }

  /// Formato completo: "Viernes, 15 Marzo 2024"
  static String fullDate(DateTime date) {
    return _fullDate.format(date);
  }

  /// Formato mes y año: "Marzo 2024"
  static String monthYear(DateTime date) {
    return _monthYear.format(date);
  }

  /// Formato hora: "14:30"
  static String time(DateTime date) {
    return _time.format(date);
  }

  /// Formato relativo: "Hoy", "Ayer", "Hace 3 días"
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'Hace $difference días';
    return shortDate(date);
  }
}
