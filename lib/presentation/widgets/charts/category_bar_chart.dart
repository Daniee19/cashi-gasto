import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';

/// Gráfico de barras horizontales para gastos por categoría
class CategoryBarChart extends StatefulWidget {
  final List<CategoryBreakdownExtended> data;
  final int maxItems;
  final bool showPercentage;
  final bool animate;

  const CategoryBarChart({
    super.key,
    required this.data,
    this.maxItems = 8,
    this.showPercentage = true,
    this.animate = true,
  });

  @override
  State<CategoryBarChart> createState() => _CategoryBarChartState();
}

class _CategoryBarChartState extends State<CategoryBarChart>
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

    final displayData = widget.data.take(widget.maxItems).toList();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _calculateMaxY(displayData),
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (event, response) {
                setState(() {
                  if (response?.spot != null) {
                    _touchedIndex = response!.spot!.touchedBarGroupIndex;
                  } else {
                    _touchedIndex = null;
                  }
                });
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.white,
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(12),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = displayData[groupIndex];
                  return BarTooltipItem(
                    '${item.categoryName}\n',
                    const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '\$${item.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: _getCategoryColor(groupIndex),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: ' (${item.percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 100,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= displayData.length) {
                      return const SizedBox.shrink();
                    }
                    final item = displayData[index];
                    final isSelected = _touchedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.categoryIcon != null)
                            Text(
                              item.categoryIcon!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.categoryName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatAmount(value),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
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
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: false,
              drawVerticalLine: true,
              verticalInterval: _calculateMaxY(displayData) / 4,
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.withValues(alpha: 0.1),
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: _buildBarGroups(displayData),
          ),
          swapAnimationDuration: const Duration(milliseconds: 250),
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<CategoryBreakdownExtended> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = _touchedIndex == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.amount * _animation.value,
            color: _getCategoryColor(index),
            width: isSelected ? 18 : 14,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calculateMaxY(data),
              color: Colors.grey.withValues(alpha: 0.05),
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getCategoryColor(int index) {
    final item = widget.data[index];
    if (item.categoryColor != null) {
      try {
        final colorStr = item.categoryColor!.replaceFirst('#', '');
        return Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {}
    }
    return AppColors.categoryColors[index % AppColors.categoryColors.length];
  }

  double _calculateMaxY(List<CategoryBreakdownExtended> data) {
    if (data.isEmpty) return 100;
    final max = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return max * 1.15; // 15% margen
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Lista detallada de categorías con barras de progreso
class CategoryBreakdownList extends StatelessWidget {
  final List<CategoryBreakdownExtended> data;
  final int maxItems;
  final VoidCallback? onShowMore;

  const CategoryBreakdownList({
    super.key,
    required this.data,
    this.maxItems = 5,
    this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Sin datos para mostrar'),
      );
    }

    final displayData = data.take(maxItems).toList();
    final hasMore = data.length > maxItems;

    return Column(
      children: [
        ...displayData.asMap().entries.map((entry) {
          return _CategoryItem(
            item: entry.value,
            color: _getCategoryColor(entry.key, entry.value),
          );
        }),
        if (hasMore && onShowMore != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onShowMore,
            child: Text(
              'Ver ${data.length - maxItems} categorias mas',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }

  Color _getCategoryColor(int index, CategoryBreakdownExtended item) {
    if (item.categoryColor != null) {
      try {
        final colorStr = item.categoryColor!.replaceFirst('#', '');
        return Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {}
    }
    return AppColors.categoryColors[index % AppColors.categoryColors.length];
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryBreakdownExtended item;
  final Color color;

  const _CategoryItem({
    required this.item,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              if (item.categoryIcon != null) ...[
                Text(item.categoryIcon!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  item.categoryName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percentage / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
