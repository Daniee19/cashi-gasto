import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';

/// Heatmap financiero tipo calendario
class FinancialHeatmap extends StatefulWidget {
  final List<DailyAmount> data;
  final ReportPeriod period;
  final bool showTooltip;
  final bool animate;

  const FinancialHeatmap({
    super.key,
    required this.data,
    required this.period,
    this.showTooltip = true,
    this.animate = true,
  });

  @override
  State<FinancialHeatmap> createState() => _FinancialHeatmapState();
}

class _FinancialHeatmapState extends State<FinancialHeatmap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  DailyAmount? _selectedDay;
  int? _selectedMonth; // Para vista anual
  double _selectedMonthIncome = 0;
  double _selectedMonthExpense = 0;
  int _selectedMonthTransactions = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
            // Leyenda de intensidad
            _buildLegend(),
            const SizedBox(height: 16),
            // Tooltip del día o mes seleccionado
            if (_selectedDay != null || _selectedMonth != null) ...[
              _buildSelectedInfo(),
              const SizedBox(height: 12),
            ],
            // Heatmap
            Expanded(
              child: _buildHeatmap(),
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
        const Text(
          'Menos',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = index / 4;
          return Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getIntensityColor(intensity),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 8),
        const Text(
          'Mas',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedInfo() {
    // Si hay un mes seleccionado (vista anual), mostrar resumen del mes
    if (_selectedMonth != null) {
      return _buildMonthSummary();
    }

    // Si hay un día seleccionado
    final day = _selectedDay!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(day.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (day.income > 0) ...[
                      _MiniStat(
                        icon: Icons.arrow_upward,
                        color: AppColors.income,
                        value: '\$${day.income.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (day.expense > 0) ...[
                      _MiniStat(
                        icon: Icons.arrow_downward,
                        color: AppColors.expense,
                        value: '\$${day.expense.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 16),
                    ],
                    _MiniStat(
                      icon: Icons.receipt_long,
                      color: AppColors.textMuted,
                      value: '${day.transactionCount} movimientos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _selectedDay = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummary() {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  months[_selectedMonth! - 1],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_selectedMonthIncome > 0) ...[
                      _MiniStat(
                        icon: Icons.arrow_upward,
                        color: AppColors.income,
                        value: '\$${_selectedMonthIncome.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (_selectedMonthExpense > 0) ...[
                      _MiniStat(
                        icon: Icons.arrow_downward,
                        color: AppColors.expense,
                        value: '\$${_selectedMonthExpense.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 16),
                    ],
                    _MiniStat(
                      icon: Icons.receipt_long,
                      color: AppColors.textMuted,
                      value: '$_selectedMonthTransactions movimientos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _selectedMonth = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    switch (widget.period) {
      case ReportPeriod.week:
        return _buildWeekView();
      case ReportPeriod.month:
        return _buildMonthView();
      case ReportPeriod.year:
        return _buildYearView();
    }
  }

  Widget _buildWeekView() {
    const days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final maxExpense = _calculateMaxExpense();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widget.data.asMap().entries.map((entry) {
        final day = entry.value;
        final dayOfWeek = day.date.weekday - 1;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  days[dayOfWeek],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _HeatmapCell(
                  day: day,
                  maxExpense: maxExpense,
                  animationValue: _animation.value,
                  isSelected: _selectedDay?.date == day.date,
                  size: 50,
                  onTap: () => setState(() {
                    _selectedDay = _selectedDay?.date == day.date ? null : day;
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${day.date.day}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthView() {
    final maxExpense = _calculateMaxExpense();
    final firstDay = widget.data.isNotEmpty ? widget.data.first.date : DateTime.now();
    final startWeekday = DateTime(firstDay.year, firstDay.month, 1).weekday;

    // Crear grid de días
    final List<DailyAmount?> gridDays = [];

    // Días vacíos antes del inicio del mes
    for (int i = 1; i < startWeekday; i++) {
      gridDays.add(null);
    }

    // Días del mes
    for (final day in widget.data) {
      gridDays.add(day);
    }

    return Column(
      children: [
        // Encabezados de días
        Row(
          children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Grid de días
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: gridDays.length,
            itemBuilder: (context, index) {
              final day = gridDays[index];
              if (day == null) {
                return const SizedBox.shrink();
              }
              return _HeatmapCell(
                day: day,
                maxExpense: maxExpense,
                animationValue: _animation.value,
                isSelected: _selectedDay?.date == day.date,
                showLabel: true,
                onTap: () => setState(() {
                  _selectedDay = _selectedDay?.date == day.date ? null : day;
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYearView() {
    final maxExpense = _calculateMaxExpense();

    // Agrupar por mes
    final Map<int, List<DailyAmount>> monthlyData = {};
    for (final day in widget.data) {
      final month = day.date.month;
      monthlyData.putIfAbsent(month, () => []).add(day);
    }

    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final days = monthlyData[month] ?? [];
        final totalExpense = days.fold(0.0, (sum, d) => sum + d.expense);
        final intensity = maxExpense > 0 ? totalExpense / maxExpense : 0.0;

        return GestureDetector(
          onTap: () {
            // Calcular totales del mes
            if (days.isNotEmpty) {
              final totalIncome = days.fold(0.0, (sum, d) => sum + d.income);
              final totalExpenseMonth = days.fold(0.0, (sum, d) => sum + d.expense);
              final totalTransactions = days.fold(0, (sum, d) => sum + d.transactionCount);

              setState(() {
                if (_selectedMonth == month) {
                  _selectedMonth = null;
                } else {
                  _selectedMonth = month;
                  _selectedMonthIncome = totalIncome;
                  _selectedMonthExpense = totalExpenseMonth;
                  _selectedMonthTransactions = totalTransactions;
                  _selectedDay = null; // Limpiar selección de día
                }
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _getIntensityColor(intensity * _animation.value),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedMonth == month
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    months[index],
                    style: TextStyle(
                      color: intensity > 0.5 ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (totalExpense > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${_formatAmount(totalExpense)}',
                      style: TextStyle(
                        color: intensity > 0.5
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateMaxExpense() {
    if (widget.data.isEmpty) return 1;
    return widget.data.map((d) => d.expense).reduce((a, b) => a > b ? a : b);
  }

  Color _getIntensityColor(double intensity) {
    if (intensity <= 0) return Colors.grey.withValues(alpha: 0.1);

    // Gradiente de verde claro a rojo
    if (intensity < 0.25) {
      return Color.lerp(
        Colors.green.withValues(alpha: 0.2),
        Colors.green.withValues(alpha: 0.5),
        intensity / 0.25,
      )!;
    } else if (intensity < 0.5) {
      return Color.lerp(
        Colors.green.withValues(alpha: 0.5),
        Colors.yellow.withValues(alpha: 0.6),
        (intensity - 0.25) / 0.25,
      )!;
    } else if (intensity < 0.75) {
      return Color.lerp(
        Colors.orange.withValues(alpha: 0.6),
        Colors.deepOrange.withValues(alpha: 0.7),
        (intensity - 0.5) / 0.25,
      )!;
    } else {
      return Color.lerp(
        Colors.deepOrange.withValues(alpha: 0.7),
        AppColors.expense.withValues(alpha: 0.9),
        (intensity - 0.75) / 0.25,
      )!;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    const weekdays = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
    return '${weekdays[date.weekday - 1].substring(0, 1).toUpperCase()}${weekdays[date.weekday - 1].substring(1)}, ${date.day} de ${months[date.month - 1]}';
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _HeatmapCell extends StatelessWidget {
  final DailyAmount day;
  final double maxExpense;
  final double animationValue;
  final bool isSelected;
  final bool showLabel;
  final double? size;
  final VoidCallback? onTap;

  const _HeatmapCell({
    required this.day,
    required this.maxExpense,
    required this.animationValue,
    this.isSelected = false,
    this.showLabel = false,
    this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final intensity = day.intensityFor(maxExpense) * animationValue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getColor(intensity),
          borderRadius: BorderRadius.circular(size != null ? 8 : 4),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: showLabel
            ? Center(
                child: Text(
                  '${day.date.day}',
                  style: TextStyle(
                    color: intensity > 0.5 ? Colors.white : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Color _getColor(double intensity) {
    if (intensity <= 0) return Colors.grey.withValues(alpha: 0.1);

    if (intensity < 0.25) {
      return Colors.green.withValues(alpha: 0.3 + intensity);
    } else if (intensity < 0.5) {
      return Colors.yellow.withValues(alpha: 0.5 + intensity * 0.5);
    } else if (intensity < 0.75) {
      return Colors.orange.withValues(alpha: 0.6 + intensity * 0.3);
    } else {
      return AppColors.expense.withValues(alpha: 0.7 + intensity * 0.3);
    }
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
