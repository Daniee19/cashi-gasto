import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';

/// Gráfico de líneas comparando ingresos vs gastos
class IncomeExpenseLineChart extends StatefulWidget {
  final List<TrendPoint> data;
  final MovementType movementType;
  final bool showTooltip;
  final bool animate;

  const IncomeExpenseLineChart({
    super.key,
    required this.data,
    this.movementType = MovementType.both,
    this.showTooltip = true,
    this.animate = true,
  });

  @override
  State<IncomeExpenseLineChart> createState() => _IncomeExpenseLineChartState();
}

class _IncomeExpenseLineChartState extends State<IncomeExpenseLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text('Sin datos para mostrar'),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            // Leyenda
            _buildLegend(),
            const SizedBox(height: 16),
            // Gráfico
            Expanded(
              child: LineChart(
                _buildChartData(),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.movementType != MovementType.expense) ...[
          _LegendItem(
            color: AppColors.income,
            label: 'Ingresos',
          ),
          const SizedBox(width: 24),
        ],
        if (widget.movementType != MovementType.income) ...[
          _LegendItem(
            color: AppColors.expense,
            label: 'Gastos',
          ),
        ],
      ],
    );
  }

  LineChartData _buildChartData() {
    final maxY = _calculateMaxY();
    final animatedMaxY = maxY * _animation.value;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.data.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.data[index].label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: _touchedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: maxY > 0 ? maxY / 4 : 1,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatAmount(value),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: 0,
      maxY: animatedMaxY > 0 ? animatedMaxY : 1,
      lineTouchData: LineTouchData(
        enabled: widget.showTooltip,
        touchCallback: (event, response) {
          setState(() {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              _touchedIndex = response.lineBarSpots!.first.x.toInt();
            } else {
              _touchedIndex = null;
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.white,
          tooltipRoundedRadius: 12,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isIncome = spot.barIndex == 0 &&
                  widget.movementType != MovementType.expense;
              return LineTooltipItem(
                '\$${spot.y.toStringAsFixed(0)}',
                TextStyle(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: _buildLineBarsData(),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> bars = [];

    // Línea de ingresos
    if (widget.movementType != MovementType.expense) {
      bars.add(
        LineChartBarData(
          spots: widget.data.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.income * _animation.value,
            );
          }).toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppColors.income,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: _touchedIndex == index ? 6 : 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: AppColors.income,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.income.withValues(alpha: 0.3),
                AppColors.income.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    // Línea de gastos
    if (widget.movementType != MovementType.income) {
      bars.add(
        LineChartBarData(
          spots: widget.data.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.expense * _animation.value,
            );
          }).toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppColors.expense,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: _touchedIndex == index ? 6 : 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: AppColors.expense,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.expense.withValues(alpha: 0.3),
                AppColors.expense.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    return bars;
  }

  double _calculateMaxY() {
    double max = 0;
    for (final point in widget.data) {
      if (widget.movementType != MovementType.expense && point.income > max) {
        max = point.income;
      }
      if (widget.movementType != MovementType.income && point.expense > max) {
        max = point.expense;
      }
    }
    return max * 1.2; // 20% de margen
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
