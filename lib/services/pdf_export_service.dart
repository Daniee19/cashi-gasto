import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/repositories/reports_repository.dart';
import '../data/models/report_models.dart';

class PdfExportService {
  /// Generate and share a PDF report
  Future<void> generateAndShareReport({
    required ReportSummary summary,
    required List<CategoryBreakdown> categoryBreakdown,
    required List<CategoryBreakdown> topCategories,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text(
              'Reporte Financiero',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#5F32FA'),
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              '${dateFormat.format(summary.startDate)} - ${dateFormat.format(summary.endDate)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 24),

          // Summary section
          _buildSectionTitle('Resumen General'),
          pw.SizedBox(height: 12),
          _buildSummaryTable(summary, currencyFormat),
          pw.SizedBox(height: 24),

          // Category breakdown section
          if (categoryBreakdown.isNotEmpty) ...[
            _buildSectionTitle('Gastos por Categoria'),
            pw.SizedBox(height: 12),
            _buildCategoryTable(categoryBreakdown, currencyFormat),
            pw.SizedBox(height: 24),
          ],

          // Top categories section
          if (topCategories.isNotEmpty) ...[
            _buildSectionTitle('Top 5 Categorias'),
            pw.SizedBox(height: 12),
            _buildTopCategoriesTable(topCategories, currencyFormat),
          ],
        ],
      ),
    );

    // Share/Print the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'reporte_financiero_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Cashi Gasto',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#5F32FA'),
            ),
          ),
          pw.Text(
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado por Cashi Gasto',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.Text(
            'Pagina ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#5F32FA'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryTable(ReportSummary summary, NumberFormat currencyFormat) {
    final isPositive = summary.balance >= 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow('Ingresos totales', currencyFormat.format(summary.totalIncome), PdfColors.green700),
          pw.Divider(color: PdfColors.grey200),
          _buildSummaryRow('Gastos totales', currencyFormat.format(summary.totalExpense), PdfColors.red700),
          pw.Divider(color: PdfColors.grey200),
          _buildSummaryRow(
            'Balance',
            currencyFormat.format(summary.balance),
            isPositive ? PdfColors.green700 : PdfColors.red700,
            isBold: true,
          ),
          if (summary.totalIncome > 0) ...[
            pw.Divider(color: PdfColors.grey200),
            _buildSummaryRow(
              'Tasa de ahorro',
              '${summary.savingsRate.toStringAsFixed(1)}%',
              PdfColors.blue700,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, PdfColor valueColor, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryTable(List<CategoryBreakdown> breakdown, NumberFormat currencyFormat) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableHeader('Categoria'),
            _buildTableHeader('Monto'),
            _buildTableHeader('%'),
          ],
        ),
        // Data rows
        ...breakdown.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.categoryName),
            _buildTableCell(currencyFormat.format(item.amount)),
            _buildTableCell('${item.percentage.toStringAsFixed(1)}%'),
          ],
        )),
        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Total', isBold: true),
            _buildTableCell(
              currencyFormat.format(breakdown.fold(0.0, (sum, item) => sum + item.amount)),
              isBold: true,
            ),
            _buildTableCell('100%', isBold: true),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTopCategoriesTable(List<CategoryBreakdown> categories, NumberFormat currencyFormat) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Categoria'),
            _buildTableHeader('Monto'),
            _buildTableHeader('%'),
          ],
        ),
        // Data rows
        ...categories.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('$index'),
              _buildTableCell(item.categoryName),
              _buildTableCell(currencyFormat.format(item.amount)),
              _buildTableCell('${item.percentage.toStringAsFixed(1)}%'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
