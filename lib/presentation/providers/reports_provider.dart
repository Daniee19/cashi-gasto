import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reports_repository.dart';
import '../../data/models/report_models.dart';
import 'selected_fund_provider.dart';

// Re-exportar modelos para conveniencia
export '../../data/models/report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

final selectedReportPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.month;
});

/// Report summary provider
final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final fundId = ref.watch(selectedFundIdProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final dateRange = period.getDateRange();

  return repository.getReportSummary(
    startDate: dateRange.start,
    endDate: dateRange.end,
    fundId: fundId,
    movementType: movementType,
  );
});

/// Category breakdown provider
final categoryBreakdownProvider = FutureProvider<List<CategoryBreakdown>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final fundId = ref.watch(selectedFundIdProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final dateRange = period.getDateRange();

  return repository.getCategoryBreakdown(
    startDate: dateRange.start,
    endDate: dateRange.end,
    fundId: fundId,
    movementType: movementType,
  );
});

/// Top categories provider (for bar chart - replaces monthly trends)
final topCategoriesProvider = FutureProvider<List<CategoryBreakdown>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final fundId = ref.watch(selectedFundIdProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final dateRange = period.getDateRange();

  final breakdown = await repository.getCategoryBreakdown(
    startDate: dateRange.start,
    endDate: dateRange.end,
    fundId: fundId,
    movementType: movementType == MovementType.both ? MovementType.expense : movementType,
  );

  // Return top 5 categories
  return breakdown.take(5).toList();
});

/// Report data combined
class ReportData {
  final ReportSummary summary;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<CategoryBreakdown> topCategories;

  const ReportData({
    required this.summary,
    required this.categoryBreakdown,
    required this.topCategories,
  });
}

/// Combined report data provider for convenience
final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final summary = await ref.watch(reportSummaryProvider.future);
  final breakdown = await ref.watch(categoryBreakdownProvider.future);
  final topCategories = await ref.watch(topCategoriesProvider.future);

  return ReportData(
    summary: summary,
    categoryBreakdown: breakdown,
    topCategories: topCategories,
  );
});

// ============================================================
// PROVIDERS PARA REPORTES AVANZADOS
// ============================================================

/// Tipo de movimiento seleccionado (ingresos, gastos, ambos)
final selectedMovementTypeProvider = StateProvider<MovementType>((ref) {
  return MovementType.expense;
});

/// Provider para datos de reportes avanzados
final advancedReportDataProvider = FutureProvider<AdvancedReportData>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final fundId = ref.watch(selectedFundIdProvider);

  return repository.getAdvancedReportData(
    period: period,
    movementType: movementType,
    targetSavingsRate: 20,
    fundId: fundId,
  );
});

/// Provider para tendencias según período
final trendsByPeriodProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final fundId = ref.watch(selectedFundIdProvider);

  return repository.getTrendsByPeriod(period: period, fundId: fundId);
});

/// Provider para flujo de caja
final cashFlowProvider = FutureProvider<List<CashFlowPoint>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final fundId = ref.watch(selectedFundIdProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final dateRange = period.getDateRange();

  return repository.getCashFlow(
    startDate: dateRange.start,
    endDate: dateRange.end,
    fundId: fundId,
    movementType: movementType,
  );
});

/// Provider para montos diarios (heatmap)
final dailyAmountsProvider = FutureProvider<List<DailyAmount>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final fundId = ref.watch(selectedFundIdProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final dateRange = period.getDateRange();

  return repository.getDailyAmounts(
    startDate: dateRange.start,
    endDate: dateRange.end,
    fundId: fundId,
    movementType: movementType,
  );
});

/// Provider para indicador de ahorro
final savingsIndicatorProvider = FutureProvider<SavingsIndicator>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final fundId = ref.watch(selectedFundIdProvider);
  final dateRange = period.getDateRange();

  return repository.getSavingsIndicator(
    startDate: dateRange.start,
    endDate: dateRange.end,
    targetSavingsRate: 20,
    fundId: fundId,
  );
});

/// Provider para desglose de categorías extendido
final categoryBreakdownExtendedProvider = FutureProvider<List<CategoryBreakdownExtended>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final fundId = ref.watch(selectedFundIdProvider);
  final dateRange = period.getDateRange();

  return repository.getCategoryBreakdownExtended(
    startDate: dateRange.start,
    endDate: dateRange.end,
    movementType: movementType,
    fundId: fundId,
  );
});

/// Provider para comparacion de gastos entre periodos
final spendingComparisonProvider = FutureProvider<SpendingComparison>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);
  final movementType = ref.watch(selectedMovementTypeProvider);
  final fundId = ref.watch(selectedFundIdProvider);

  return repository.getSpendingComparison(
    period: period,
    fundId: fundId,
    movementType: movementType,
  );
});
