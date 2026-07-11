import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';

class OcrResult {
  final double? amount;
  final TransactionType type;
  final String? suggestedCategoryId;
  final String? note;
  final String rawText;
  final File? previewImage; // primera página renderizada (para PDFs)

  const OcrResult({
    this.amount,
    this.type = TransactionType.expense,
    this.suggestedCategoryId,
    this.note,
    required this.rawText,
    this.previewImage,
  });
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> processImage(File imageFile, List<Category> categories) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text;
    final lower = text.toLowerCase();

    return OcrResult(
      amount: _extractAmount(text),
      type: _detectType(lower),
      suggestedCategoryId: _matchCategory(lower, categories),
      note: _extractNote(text),
      rawText: text,
    );
  }

  /// Procesa un PDF: renderiza cada página, OCR cada una, combina resultados
  Future<OcrResult> processPdf(String pdfPath, List<Category> categories) async {
    final document = await PdfDocument.openFile(pdfPath);
    final pageCount = document.pagesCount;
    final tempDir = await getTemporaryDirectory();
    final allTexts = <String>[];
    File? preview;

    // ponytail: OCR máx 5 páginas, suficiente para cualquier recibo/factura
    final pagesToProcess = pageCount > 5 ? 5 : pageCount;

    for (int i = 1; i <= pagesToProcess; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      if (pageImage != null) {
        final tempFile = File('${tempDir.path}/ocr_pdf_page_$i.png');
        await tempFile.writeAsBytes(pageImage.bytes);

        if (i == 1) preview = tempFile;

        final inputImage = InputImage.fromFile(tempFile);
        final recognized = await _recognizer.processImage(inputImage);
        allTexts.add(recognized.text);
      }

      await page.close();
    }

    await document.close();

    final combinedText = allTexts.join('\n');
    final lower = combinedText.toLowerCase();

    return OcrResult(
      amount: _extractAmount(combinedText),
      type: _detectType(lower),
      suggestedCategoryId: _matchCategory(lower, categories),
      note: _extractNote(combinedText),
      rawText: combinedText,
      previewImage: preview,
    );
  }

  /// Extrae el monto más grande del texto (asume que es el total)
  double? _extractAmount(String text) {
    // ponytail: busca patrones de monto comunes en recibos peruanos/latinos
    final patterns = [
      RegExp(r'total\s*:?\s*S?/?\.?\s*(\d[\d,]*\.?\d*)', caseSensitive: false),
      RegExp(r'importe\s*:?\s*S?/?\.?\s*(\d[\d,]*\.?\d*)', caseSensitive: false),
      RegExp(r'monto\s*:?\s*S?/?\.?\s*(\d[\d,]*\.?\d*)', caseSensitive: false),
      RegExp(r'S/\.?\s*(\d[\d,]*\.?\d*)'),
      RegExp(r'\$\s*(\d[\d,]*\.?\d*)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final value = double.tryParse(raw);
        if (value != null && value > 0) return value;
      }
    }

    // Fallback: el número más grande encontrado
    final allNumbers = RegExp(r'(\d+\.?\d{0,2})')
        .allMatches(text)
        .map((m) => double.tryParse(m.group(1)!) ?? 0)
        .where((n) => n > 0.5) // ignorar centavos sueltos
        .toList();

    if (allNumbers.isEmpty) return null;
    allNumbers.sort();
    return allNumbers.last;
  }

  TransactionType _detectType(String lower) {
    const incomeKeywords = [
      'deposito', 'depósito', 'abono', 'ingreso', 'pago recibido',
      'transferencia recibida', 'salario', 'sueldo', 'honorarios',
      'venta', 'cobro',
    ];
    for (final kw in incomeKeywords) {
      if (lower.contains(kw)) return TransactionType.income;
    }
    return TransactionType.expense;
  }

  /// Matchea keywords del texto con nombres de categorías existentes
  String? _matchCategory(String lower, List<Category> categories) {
    // Mapeo de keywords a nombres de categorías comunes
    const keywordMap = <String, List<String>>{
      'alimentacion': ['supermercado', 'mercado', 'restaurant', 'comida', 'cafe', 'panaderia', 'bodega', 'minimarket', 'grifo'],
      'transporte': ['taxi', 'uber', 'bus', 'gasolina', 'combustible', 'estacionamiento', 'peaje'],
      'salud': ['farmacia', 'clinica', 'hospital', 'doctor', 'medicina', 'laboratorio', 'botica'],
      'entretenimiento': ['cine', 'teatro', 'netflix', 'spotify', 'juego', 'diversión'],
      'compras': ['tienda', 'store', 'mall', 'plaza', 'ripley', 'saga', 'falabella', 'oechsle'],
      'servicios': ['luz', 'agua', 'internet', 'telefono', 'celular', 'cable', 'gas', 'recibo'],
      'educacion': ['universidad', 'colegio', 'curso', 'libro', 'academia', 'instituto'],
      'salario': ['sueldo', 'salario', 'nomina', 'honorarios', 'remuneracion'],
    };

    // Buscar keyword en el texto
    String? matchedCategoryName;
    for (final entry in keywordMap.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          matchedCategoryName = entry.key;
          break;
        }
      }
      if (matchedCategoryName != null) break;
    }

    if (matchedCategoryName == null) return null;

    // Buscar la categoría por nombre (case-insensitive)
    for (final cat in categories) {
      if (cat.name.toLowerCase().contains(matchedCategoryName) ||
          matchedCategoryName.contains(cat.name.toLowerCase())) {
        return cat.id;
      }
    }
    return null;
  }

  /// Extrae una nota útil: nombre del establecimiento (primera línea no numérica)
  String? _extractNote(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    for (final line in lines.take(3)) {
      final trimmed = line.trim();
      // Saltar líneas que son solo números o fechas
      if (RegExp(r'^\d[\d\s/\-:.,]*$').hasMatch(trimmed)) continue;
      if (trimmed.length < 3 || trimmed.length > 80) continue;
      return trimmed;
    }
    return null;
  }

  void dispose() {
    _recognizer.close();
  }
}
