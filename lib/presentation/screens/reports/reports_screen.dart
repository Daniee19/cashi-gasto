import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category.dart';
import '../../../data/models/fund.dart';
import '../../../data/models/report_models.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../../services/pdf_export_service.dart';
import '../../providers/reports_provider.dart';
import '../../providers/fund_provider.dart';
import '../../providers/selected_fund_provider.dart';
import '../../widgets/charts/charts.dart';
import '../../widgets/cashito_mascot.dart';
import '../../widgets/category_icon.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  double _getHeatmapHeight(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.week:
        return 220;
      case ReportPeriod.month:
        return 380;
      case ReportPeriod.year:
        return 320;
    }
  }

  Future<void> _exportToPdf(BuildContext context, WidgetRef ref) async {
    final summaryAsync = ref.read(reportSummaryProvider);
    final breakdownAsync = ref.read(categoryBreakdownProvider);
    final topCategoriesAsync = ref.read(topCategoriesProvider);

    // Check if all data is loaded
    final summary = summaryAsync.valueOrNull;
    final breakdown = breakdownAsync.valueOrNull;
    final topCategories = topCategoriesAsync.valueOrNull;

    if (summary == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espera a que carguen los datos')),
        );
      }
      return;
    }

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final pdfService = PdfExportService();
      await pdfService.generateAndShareReport(
        summary: summary,
        categoryBreakdown: breakdown ?? [],
        topCategories: topCategories ?? [],
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading indicator and show error
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  Widget _buildFundSelector(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Fund>> fundsAsync,
    String? selectedFundId,
  ) {
    return fundsAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
      data: (funds) {
        if (funds.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedFundId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              hint: const Text('Todos los fondos'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Todos los fondos'),
                    ],
                  ),
                ),
                ...funds.map((fund) => DropdownMenuItem<String?>(
                  value: fund.id,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fund.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              onChanged: (value) {
                ref.read(selectedFundIdProvider.notifier).setSelectedFund(value);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedReportPeriodProvider);
    final selectedMovementType = ref.watch(selectedMovementTypeProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final topCategoriesAsync = ref.watch(topCategoriesProvider);
    // Providers avanzados
    final cashFlowAsync = ref.watch(cashFlowProvider);
    final spendingComparisonAsync = ref.watch(spendingComparisonProvider);
    final dailyAmountsAsync = ref.watch(dailyAmountsProvider);
    // Fondos
    final fundsAsync = ref.watch(fundNotifierProvider);
    final selectedFundId = ref.watch(selectedFundIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportToPdf(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportSummaryProvider);
          ref.invalidate(categoryBreakdownProvider);
          ref.invalidate(topCategoriesProvider);
          ref.invalidate(cashFlowProvider);
          ref.invalidate(spendingComparisonProvider);
          ref.invalidate(dailyAmountsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fund selector
              _buildFundSelector(context, ref, fundsAsync, selectedFundId),
              const SizedBox(height: 12),

              // Period selector
              _PeriodSelector(
                selected: selectedPeriod,
                onChanged: (period) {
                  ref.read(selectedReportPeriodProvider.notifier).state = period;
                },
              ),
              const SizedBox(height: 12),

              // Movement type selector
              _MovementTypeSelector(
                selected: selectedMovementType,
                onChanged: (type) {
                  ref.read(selectedMovementTypeProvider.notifier).state = type;
                },
              ),
              const SizedBox(height: 20),

              // Summary card
              summaryAsync.when(
                loading: () => const _LoadingCard(height: 180),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (summary) => _SummaryCard(summary: summary),
              ),
              const SizedBox(height: 20),

              // Category breakdown
              Text(
                selectedMovementType == MovementType.income
                    ? 'Ingresos por categoria'
                    : selectedMovementType == MovementType.expense
                        ? 'Gastos por categoria'
                        : 'Movimientos por categoria',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              breakdownAsync.when(
                loading: () => const _LoadingCard(height: 300),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (breakdown) => breakdown.isEmpty
                    ? _EmptyCard(
                        message: selectedMovementType == MovementType.income
                            ? 'No hay ingresos en este periodo'
                            : 'No hay gastos en este periodo',
                      )
                    : _CategoryPieChart(breakdown: breakdown),
              ),
              const SizedBox(height: 20),

              // Top categories bar chart
              Text(
                selectedMovementType == MovementType.income
                    ? 'Top categorias de ingresos'
                    : 'Top categorias de gastos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              topCategoriesAsync.when(
                loading: () => const _LoadingCard(height: 250),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (categories) => categories.isEmpty
                    ? const _EmptyCard(message: 'No hay datos suficientes')
                    : _TopCategoriesBarChart(
                        categories: categories,
                        isIncome: selectedMovementType == MovementType.income,
                      ),
              ),
              const SizedBox(height: 24),

              // ============ REPORTES AVANZADOS ============

              // Flujo de caja
              Text(
                'Flujo de caja',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Evolucion de tu saldo acumulado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              cashFlowAsync.when(
                loading: () => const _LoadingCard(height: 280),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (cashFlow) => cashFlow.isEmpty
                    ? const _EmptyCard(message: 'No hay datos para mostrar')
                    : Container(
                        height: 280,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CashFlowAreaChart(
                          data: cashFlow,
                          movementType: selectedMovementType,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Comparacion con periodo anterior
              Text(
                'Tendencia de ${selectedMovementType == MovementType.income ? 'ingresos' : 'gastos'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Comparacion con ${selectedPeriod == ReportPeriod.week ? 'la semana' : selectedPeriod == ReportPeriod.month ? 'el mes' : 'el ano'} anterior',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              spendingComparisonAsync.when(
                loading: () => const _LoadingCard(height: 180),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (comparison) => _SpendingComparisonCard(
                  comparison: comparison,
                  movementType: selectedMovementType,
                ),
              ),
              const SizedBox(height: 24),

              // Heatmap de actividad
              Text(
                'Mapa de actividad',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedMovementType == MovementType.income
                    ? 'Intensidad de ingresos por dia'
                    : selectedMovementType == MovementType.expense
                        ? 'Intensidad de gastos por dia'
                        : 'Intensidad de movimientos por dia',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              dailyAmountsAsync.when(
                loading: () => const _LoadingCard(height: 320),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (dailyAmounts) => dailyAmounts.isEmpty
                    ? const _EmptyCard(message: 'No hay datos para mostrar')
                    : Container(
                        height: _getHeatmapHeight(selectedPeriod),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: FinancialHeatmap(
                          data: dailyAmounts,
                          period: selectedPeriod,
                          movementType: selectedMovementType,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ReportPeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MovementTypeSelector extends StatelessWidget {
  final MovementType selected;
  final ValueChanged<MovementType> onChanged;

  const _MovementTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: MovementType.values.map((type) {
          final isSelected = type == selected;
          Color bgColor;
          Color textColor;

          if (isSelected) {
            switch (type) {
              case MovementType.income:
                bgColor = AppColors.income;
                break;
              case MovementType.expense:
                bgColor = AppColors.expense;
                break;
              case MovementType.both:
                bgColor = AppColors.primary;
                break;
            }
            textColor = Colors.white;
          } else {
            bgColor = Colors.transparent;
            textColor = Colors.grey[700]!;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  type.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ReportSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: 'S/ ');
    final isPositive = summary.balance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [Colors.red, Colors.red.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance del periodo',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(summary.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.arrow_upward,
                  label: 'Ingresos',
                  amount: currencyFormat.format(summary.totalIncome),
                  color: Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.arrow_downward,
                  label: 'Gastos',
                  amount: currencyFormat.format(summary.totalExpense),
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (summary.totalIncome > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Tasa de ahorro: ${summary.savingsRate.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  final List<CategoryBreakdown> breakdown;

  const _CategoryPieChart({required this.breakdown});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: 'S/ ');
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: widget.breakdown.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isTouched = index == touchedIndex;
                  final color = colors[index % colors.length];

                  return PieChartSectionData(
                    color: color,
                    value: item.amount,
                    title: isTouched ? '${item.percentage.toStringAsFixed(1)}%' : '',
                    radius: isTouched ? 60 : 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...widget.breakdown.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.categoryName,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    currencyFormat.format(item.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (widget.breakdown.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${widget.breakdown.length - 5} categorias mas',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopCategoriesBarChart extends StatelessWidget {
  final List<CategoryBreakdown> categories;
  final bool isIncome;

  const _TopCategoriesBarChart({
    required this.categories,
    this.isIncome = false,
  });

  /// Crea una instancia temporal de Category para usar con CategoryIcon
  Category _createTempCategory(CategoryBreakdown breakdown) {
    return Category(
      id: breakdown.categoryId,
      name: breakdown.categoryName,
      type: isIncome ? CategoryType.income : CategoryType.expense,
      icon: breakdown.categoryIcon,
      color: breakdown.categoryColor,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: 'S/ ');
    final maxAmount = categories.fold<double>(0, (max, c) => c.amount > max ? c.amount : max);
    final barColor = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryBreakdown = entry.value;
          final percentage = maxAmount > 0 ? categoryBreakdown.amount / maxAmount : 0.0;
          final tempCategory = _createTempCategory(categoryBreakdown);

          return Padding(
            padding: EdgeInsets.only(bottom: index < categories.length - 1 ? 16 : 0),
            child: Row(
              children: [
                // Icon
                CategoryIcon(category: tempCategory, size: 40),
                const SizedBox(width: 12),
                // Name and bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              categoryBreakdown.categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            currencyFormat.format(categoryBreakdown.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress bar
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${categoryBreakdown.percentage.toStringAsFixed(1)}% del total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CashitoMascot(mood: CashitoMood.statsLow, size: 80),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SpendingComparisonCard extends StatelessWidget {
  final SpendingComparison comparison;
  final MovementType movementType;

  const _SpendingComparisonCard({
    required this.comparison,
    required this.movementType,
  });

  /// Crea una instancia temporal de Category para usar con CategoryIcon
  Category _createTempCategory(CategoryBreakdown breakdown, bool isIncome) {
    return Category(
      id: breakdown.categoryId,
      name: breakdown.categoryName,
      type: isIncome ? CategoryType.income : CategoryType.expense,
      icon: breakdown.categoryIcon,
      color: breakdown.categoryColor,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: 'S/ ');
    final isIncome = movementType == MovementType.income;
    final primaryColor = isIncome ? AppColors.income : AppColors.expense;

    // For expenses, an increase is bad; for income, an increase is good
    final isPositiveChange = isIncome ? comparison.isIncrease : !comparison.isIncrease;
    final changeColor = isPositiveChange ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current period amount
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIncome ? 'Total ingresos' : 'Total gastos',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(comparison.currentPeriodAmount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Comparison with previous period
          Row(
            children: [
              Icon(
                comparison.isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                color: changeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${comparison.percentageChange.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: changeColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'vs ${comparison.previousPeriodLabel}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comparison.isIncrease
                ? (isIncome
                    ? 'Tus ingresos aumentaron ${currencyFormat.format(comparison.difference.abs())}'
                    : 'Gastaste ${currencyFormat.format(comparison.difference.abs())} mas')
                : (isIncome
                    ? 'Tus ingresos disminuyeron ${currencyFormat.format(comparison.difference.abs())}'
                    : 'Ahorraste ${currencyFormat.format(comparison.difference.abs())}'),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),

          // Top category (if available)
          if (comparison.topCategory != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                CategoryIcon(
                  category: _createTempCategory(comparison.topCategory!, isIncome),
                  size: 36,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncome ? 'Mayor fuente de ingreso' : 'Mayor gasto',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        comparison.topCategory!.categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(comparison.topCategory!.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
