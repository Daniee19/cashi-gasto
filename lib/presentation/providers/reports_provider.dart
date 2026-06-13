import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

/// Selected report period
enum ReportPeriod {
  week,
  month,
  year;

  String get displayName {
    switch (this) {
      case ReportPeriod.week:
        return 'Esta semana';
      case ReportPeriod.month:
        return 'Este mes';
      case ReportPeriod.year:
        return 'Este ano';
    }
  }

  ({DateTime start, DateTime end}) getDateRange() {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return (
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.month:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportPeriod.year:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }
}

final selectedReportPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.month;
});

/// Report summary provider
final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final dateRange = period.getDateRange();

  return repository.getReportSummary(
    startDate: dateRange.start,
    endDate: dateRange.end,
  );
});

/// Category breakdown provider
final categoryBreakdownProvider = FutureProvider<List<CategoryBreakdown>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final dateRange = period.getDateRange();

  return repository.getCategoryBreakdown(
    startDate: dateRange.start,
    endDate: dateRange.end,
  );
});

/// Monthly trends provider
final monthlyTrendsProvider = FutureProvider<List<MonthlyTrend>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.getMonthlyTrends(months: 6);
});

/// Report data combined
class ReportData {
  final ReportSummary summary;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<MonthlyTrend> monthlyTrends;

  const ReportData({
    required this.summary,
    required this.categoryBreakdown,
    required this.monthlyTrends,
  });
}

/// Combined report data provider for convenience
final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final summary = await ref.watch(reportSummaryProvider.future);
  final breakdown = await ref.watch(categoryBreakdownProvider.future);
  final trends = await ref.watch(monthlyTrendsProvider.future);

  return ReportData(
    summary: summary,
    categoryBreakdown: breakdown,
    monthlyTrends: trends,
  );
});
