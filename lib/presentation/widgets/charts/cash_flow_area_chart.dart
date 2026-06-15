import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';

/// Gráfico de área para flujo de caja acumulado
class CashFlowAreaChart extends StatefulWidget {
  final List<CashFlowPoint> data;
  final MovementType movementType;
  final bool showTooltip;
  final bool animate;

  const CashFlowAreaChart({
    super.key,
    required this.data,
    this.movementType = MovementType.both,
    this.showTooltip = true,
    this.animate = true,
  });

  @override
  State<CashFlowAreaChart> createState() => _CashFlowAreaChartState();
}

class _CashFlowAreaChartState extends State<CashFlowAreaChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
            // Indicador de estado actual
            _buildCurrentBalanceIndicator(),
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

  Widget _buildCurrentBalanceIndicator() {
    final lastPoint = widget.data.isNotEmpty ? widget.data.last : null;
    if (lastPoint == null) return const SizedBox.shrink();

    final value = _getValueForPoint(lastPoint);
    final isPositive = value >= 0;
    final color = _getColorForMovementType();
    final label = _getLabelForMovementType();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            'S/ ${value.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  double _getValueForPoint(CashFlowPoint point) {
    switch (widget.movementType) {
      case MovementType.income:
        return point.income;
      case MovementType.expense:
        return point.expense;
      case MovementType.both:
        return point.cumulativeBalance;
    }
  }

  double _getCumulativeValueForIndex(int index) {
    double cumulative = 0;
    for (int i = 0; i <= index; i++) {
      final point = widget.data[i];
      switch (widget.movementType) {
        case MovementType.income:
          cumulative += point.income;
          break;
        case MovementType.expense:
          cumulative += point.expense;
          break;
        case MovementType.both:
          cumulative = point.cumulativeBalance;
          break;
      }
    }
    return cumulative;
  }

  Color _getColorForMovementType() {
    switch (widget.movementType) {
      case MovementType.income:
        return AppColors.income;
      case MovementType.expense:
        return AppColors.expense;
      case MovementType.both:
        return AppColors.primary;
    }
  }

  String _getLabelForMovementType() {
    switch (widget.movementType) {
      case MovementType.income:
        return 'Total ingresos';
      case MovementType.expense:
        return 'Total gastos';
      case MovementType.both:
        return 'Saldo actual';
    }
  }

  LineChartData _buildChartData() {
    final minY = _calculateMinY();
    final maxY = _calculateMaxY();
    final range = maxY - minY;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: range > 0 ? range / 4 : 1,
        getDrawingHorizontalLine: (value) {
          // Línea del cero más prominente
          if (value == 0) {
            return FlLine(
              color: AppColors.textMuted,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          }
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
            reservedSize: 35,
            interval: _calculateXInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.data.length) {
                return const SizedBox.shrink();
              }
              // Only show labels for points with activity
              final point = widget.data[index];
              if (point.dailyChange == 0 && index != 0 && index != widget.data.length - 1) {
                return const SizedBox.shrink();
              }
              final date = widget.data[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: range > 0 ? range / 4 : 1,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatAmount(value),
                style: TextStyle(
                  color: value >= 0 ? AppColors.income : AppColors.expense,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
      minY: minY - (range * 0.1),
      maxY: maxY + (range * 0.1),
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
          getTooltipColor: (spot) => Colors.white,
          tooltipRoundedRadius: 12,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              final point = widget.data[index];
              final cumulative = _getCumulativeValueForIndex(index);
              final color = _getColorForMovementType();

              // Format date
              final date = point.date;
              final dateStr = '${date.day}/${date.month}/${date.year}';

              String details;
              switch (widget.movementType) {
                case MovementType.income:
                  details = 'Fecha: $dateStr\n'
                      'Ingreso del dia: S/ ${point.income.toStringAsFixed(0)}\n'
                      'Total acumulado: S/ ${cumulative.toStringAsFixed(0)}';
                  break;
                case MovementType.expense:
                  details = 'Fecha: $dateStr\n'
                      'Gasto del dia: S/ ${point.expense.toStringAsFixed(0)}\n'
                      'Total acumulado: S/ ${cumulative.toStringAsFixed(0)}';
                  break;
                case MovementType.both:
                  details = 'Fecha: $dateStr\n'
                      'Saldo: S/ ${point.cumulativeBalance.toStringAsFixed(0)}\n'
                      'Cambio: ${point.dailyChange >= 0 ? '+' : ''}S/ ${point.dailyChange.toStringAsFixed(0)}';
                  break;
              }

              return LineTooltipItem(
                details,
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: widget.data.asMap().entries.map((entry) {
            final value = _getCumulativeValueForIndex(entry.key);
            // Aplicar animación desde la línea base (0)
            final animatedValue = value * _animation.value;
            return FlSpot(entry.key.toDouble(), animatedValue);
          }).toList(),
          isCurved: true,
          curveSmoothness: 0.2,
          gradient: LinearGradient(
            colors: _getLineGradientColors(),
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final color = _getColorForMovementType();
              return FlDotCirclePainter(
                radius: _touchedIndex == index ? 6 : 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _getColorForMovementType().withValues(alpha: 0.3),
                _getColorForMovementType().withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 0,
            color: AppColors.textMuted.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  List<Color> _getLineGradientColors() {
    final color = _getColorForMovementType();
    return [color, color];
  }

  double _calculateMinY() {
    if (widget.data.isEmpty) return 0;
    final values = List.generate(
      widget.data.length,
      (i) => _getCumulativeValueForIndex(i),
    );
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  double _calculateMaxY() {
    if (widget.data.isEmpty) return 1;
    final values = List.generate(
      widget.data.length,
      (i) => _getCumulativeValueForIndex(i),
    );
    if (values.isEmpty) return 1;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal : 1;
  }

  double _calculateXInterval() {
    final length = widget.data.length;
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 31) return 5;
    return 10;
  }

  String _formatAmount(double amount) {
    final prefix = amount >= 0 ? '' : '-';
    final absAmount = amount.abs();
    if (absAmount >= 1000000) {
      return '$prefix${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000) {
      return '$prefix${(absAmount / 1000).toStringAsFixed(1)}K';
    }
    return '$prefix${absAmount.toStringAsFixed(0)}';
  }
}
