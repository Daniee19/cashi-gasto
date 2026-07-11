import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../services/ocr_service.dart';
import '../../providers/category_provider.dart';
import '../../widgets/category_icon.dart';

/// Resultado confirmado por el usuario desde el sheet OCR
class OcrConfirmedData {
  final double amount;
  final TransactionType type;
  final Category? category;
  final String? note;

  const OcrConfirmedData({
    required this.amount,
    required this.type,
    this.category,
    this.note,
  });
}

/// Bottom sheet que muestra los resultados del escaneo OCR
class OcrResultSheet extends ConsumerStatefulWidget {
  final File imageFile;
  final OcrResult? precomputedResult; // para PDFs ya procesados

  const OcrResultSheet({super.key, required this.imageFile, this.precomputedResult});

  @override
  ConsumerState<OcrResultSheet> createState() => _OcrResultSheetState();
}

class _OcrResultSheetState extends ConsumerState<OcrResultSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _ocrService = OcrService();

  OcrResult? _result;
  bool _isProcessing = true;
  String? _error;
  TransactionType _type = TransactionType.expense;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.precomputedResult != null) {
      _applyResult(widget.precomputedResult!);
    } else {
      _processImage();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _applyResult(OcrResult result) {
    final categoriesState = ref.read(categoryNotifierProvider);
    final categories = categoriesState.valueOrNull ?? [];

    setState(() {
      _result = result;
      _isProcessing = false;
      _type = result.type;
      if (result.amount != null) {
        _amountController.text = result.amount!.toStringAsFixed(2);
      }
      if (result.note != null) {
        _noteController.text = result.note!;
      }
      if (result.suggestedCategoryId != null) {
        _selectedCategory = categories
            .where((c) => c.id == result.suggestedCategoryId)
            .firstOrNull;
      }
    });
  }

  Future<void> _processImage() async {
    try {
      final categoriesState = ref.read(categoryNotifierProvider);
      final categories = categoriesState.valueOrNull ?? [];

      final result = await _ocrService.processImage(widget.imageFile, categories);
      if (!mounted) return;
      _applyResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _error = 'No se pudo procesar la imagen: $e';
      });
    }
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto valido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      OcrConfirmedData(
        amount: amount,
        type: _type,
        category: _selectedCategory,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      ),
    );
  }

  void _showCategoryPicker() {
    final categoryType = _type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Consumer(
          builder: (context, ref, _) {
            final categoriesAsync = ref.watch(categoriesByTypeProvider(categoryType));
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Cambiar categoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (categories) => ListView.builder(
                      controller: scrollController,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return ListTile(
                          leading: CategoryIcon(category: cat, size: 40),
                          title: Text(cat.name),
                          trailing: _selectedCategory?.id == cat.id
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isProcessing
          ? _buildProcessing()
          : _error != null
              ? _buildError()
              : _buildResults(theme),
    );
  }

  Widget _buildProcessing() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text('Analizando documento...', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('Detectando monto y categoria', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final hasData = _result!.amount != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.document_scanner, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Documento escaneado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      hasData ? 'Datos detectados correctamente' : 'No se detectaron montos claros',
                      style: TextStyle(fontSize: 13, color: hasData ? AppColors.success : AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Preview de imagen (miniatura)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.file(widget.imageFile, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          const SizedBox(height: 20),

          // Tipo de transaccion
          Row(
            children: [
              Expanded(
                child: _OcrTypeChip(
                  label: 'Gasto',
                  icon: Icons.arrow_upward,
                  color: AppColors.expense,
                  selected: _type == TransactionType.expense,
                  onTap: () => setState(() => _type = TransactionType.expense),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OcrTypeChip(
                  label: 'Ingreso',
                  icon: Icons.arrow_downward,
                  color: AppColors.income,
                  selected: _type == TransactionType.income,
                  onTap: () => setState(() => _type = TransactionType.income),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monto
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Monto detectado',
              prefixText: '\$ ',
              prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: (_type == TransactionType.expense ? AppColors.expense : AppColors.income).withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Categoria sugerida
          InkWell(
            onTap: _showCategoryPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (_selectedCategory != null)
                    CategoryIcon(category: _selectedCategory!, size: 36, borderRadius: 10)
                  else
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Categoria', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          _selectedCategory?.name ?? 'Sin categoria - toca para elegir',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _selectedCategory != null ? null : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nota
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Nota',
              hintText: 'Descripcion del documento',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          // Texto raw (colapsable)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Ver texto detectado', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            leading: const Icon(Icons.text_snippet_outlined, size: 18, color: AppColors.textMuted),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!.rawText.isEmpty ? '(no se detectó texto)' : _result!.rawText,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Usar datos'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OcrTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _OcrTypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.textMuted.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? color : AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}
