import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';

/// Gráfico de dona animado para mostrar ahorro vs gastos
class SavingsGaugeChart extends StatefulWidget {
  final SavingsIndicator data;
  final bool animate;
  final double size;

  const SavingsGaugeChart({
    super.key,
    required this.data,
    this.animate = true,
    this.size = 220,
  });

  @override
  State<SavingsGaugeChart> createState() => _SavingsGaugeChartState();
}

class _SavingsGaugeChartState extends State<SavingsGaugeChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SavingsGaugeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data && widget.animate) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isPositive = data.amountSaved >= 0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            // Gráfico de dona
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dona animada
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _DonutPainter(
                      expensePercent: _getExpensePercent(),
                      savingsPercent: _getSavingsPercent(),
                      animationValue: _animation.value,
                    ),
                  ),
                  // Centro con información
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? AppColors.income : AppColors.expense,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(data.amountSaved.abs() * _animation.value).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? AppColors.income : AppColors.expense,
                        ),
                      ),
                      Text(
                        isPositive ? 'ahorrado' : 'deficit',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Leyenda con montos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: AppColors.income,
                  label: 'Ingresos',
                  amount: data.totalIncome * _animation.value,
                  percent: 100,
                ),
                const SizedBox(width: 32),
                _LegendItem(
                  color: AppColors.expense,
                  label: 'Gastos',
                  amount: data.totalExpense * _animation.value,
                  percent: _getExpensePercent(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  double _getExpensePercent() {
    if (widget.data.totalIncome <= 0) return 0;
    return ((widget.data.totalExpense / widget.data.totalIncome) * 100).clamp(0.0, 100.0);
  }

  double _getSavingsPercent() {
    return (100.0 - _getExpensePercent()).clamp(0.0, 100.0);
  }
}

class _DonutPainter extends CustomPainter {
  final double expensePercent;
  final double savingsPercent;
  final double animationValue;

  _DonutPainter({
    required this.expensePercent,
    required this.savingsPercent,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = 28.0;

    // Sombra suave
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, shadowPaint);

    // Fondo gris
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2; // Empezar desde arriba

    // Arco de ahorro (verde) - dibujado primero
    if (savingsPercent > 0) {
      final savingsAngle = (savingsPercent / 100) * 2 * math.pi * animationValue;

      final savingsPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: savingsAngle,
          colors: [
            AppColors.income,
            AppColors.income.withValues(alpha: 0.7),
          ],
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, savingsAngle, false, savingsPaint);
    }

    // Arco de gastos (rojo) - dibujado después
    if (expensePercent > 0) {
      final savingsAngle = (savingsPercent / 100) * 2 * math.pi * animationValue;
      final expenseAngle = (expensePercent / 100) * 2 * math.pi * animationValue;

      final expensePaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: expenseAngle,
          colors: [
            AppColors.expense.withValues(alpha: 0.8),
            AppColors.expense,
          ],
          transform: GradientRotation(startAngle + savingsAngle),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle + savingsAngle, expenseAngle, false, expensePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.expensePercent != expensePercent;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;
  final double percent;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
