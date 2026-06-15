import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/category.dart';
import '../../core/constants/app_colors.dart';

/// Mapeo de nombres de categorías a archivos de imagen locales
const _categoryImageMap = {
  // Gastos
  'alimentacion': 'category-alimentacion.png',
  'transporte': 'category-transporte.png',
  'entretenimiento': 'category-entretenimiento.png',
  'compras': 'category-compras.png',
  'salud': 'category-salud.png',
  'educacion': 'category-educacion.png',
  'servicios': 'category-pagar-servicio.png',
  'otros': 'category-otros-gastos.png',
  // Ingresos
  'salario': 'category-salario.png',
  'inversiones': 'category-inversion.png',
  'regalo': 'category-regalo.png',
  'otros ingresos': 'category-otros-ingresos.png',
};

/// Widget that displays a category's visual representation.
/// Shows the category image if available, otherwise falls back to icon/emoji.
class CategoryIcon extends StatelessWidget {
  final Category category;
  final double size;
  final Color? backgroundColor;
  final double borderRadius;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
    this.backgroundColor,
    this.borderRadius = 10,
  });

  /// Obtiene el path de la imagen local para esta categoría
  String? get _localImagePath {
    final normalizedName = category.name.toLowerCase().trim();
    final fileName = _categoryImageMap[normalizedName];
    if (fileName != null) {
      return 'assets/categories/$fileName';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (category.type == CategoryType.expense
            ? AppColors.expense.withValues(alpha: 0.1)
            : AppColors.income.withValues(alpha: 0.1));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Primero: imagen personalizada (imageUrl)
    if (category.hasImage) {
      return _buildImage();
    }
    // Segundo: imagen local por nombre de categoría
    final localPath = _localImagePath;
    if (localPath != null) {
      return _buildLocalImage(localPath);
    }
    // Tercero: fallback a emoji
    return _buildIconFallback();
  }

  Widget _buildLocalImage(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildIconFallback(),
    );
  }

  Widget _buildImage() {
    final imageUrl = category.imageUrl!;

    // Check if it's a local asset (starts with 'asset:')
    if (imageUrl.startsWith('asset:')) {
      final assetPath = 'assets/${imageUrl.substring(6)}';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildIconFallback(),
      );
    }

    // Otherwise, it's a network image
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildIconFallback(),
      errorWidget: (context, url, error) => _buildIconFallback(),
    );
  }

  Widget _buildIconFallback() {
    final emoji = _getEmoji(category.icon, category.type == CategoryType.expense);
    return Center(
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }

  /// Converts icon names to emojis
  String _getEmoji(String? iconName, bool isExpense) {
    const iconToEmoji = {
      'restaurant': '\u{1F354}',
      'directions_car': '\u{1F697}',
      'movie': '\u{1F3AC}',
      'shopping_bag': '\u{1F6CD}',
      'medical_services': '\u{1F3E5}',
      'school': '\u{1F4DA}',
      'receipt': '\u{1F9FE}',
      'more_horiz': '\u{1F4E6}',
      'payments': '\u{1F4B5}',
      'trending_up': '\u{1F4C8}',
      'card_giftcard': '\u{1F381}',
      'home': '\u{1F3E0}',
      'pets': '\u{1F43E}',
      'fitness_center': '\u{1F4AA}',
      'flight': '\u{2708}',
      'phone': '\u{1F4F1}',
      'wifi': '\u{1F4F6}',
      'water_drop': '\u{1F4A7}',
      'bolt': '\u{26A1}',
      'sports_esports': '\u{1F3AE}',
      'local_cafe': '\u{2615}',
      'checkroom': '\u{1F454}',
      'phone_android': '\u{1F4F1}',
      'savings': '\u{1F3E6}',
      'work': '\u{1F4BC}',
      'attach_money': '\u{1F4B0}',
      'account_balance': '\u{1F3DB}',
      'redeem': '\u{1F381}',
      'business_center': '\u{1F4BC}',
    };

    if (iconName == null) return isExpense ? '\u{1F4B8}' : '\u{1F4B0}';
    // Check if it's already an emoji
    if (iconName.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
      return iconName;
    }
    return iconToEmoji[iconName] ?? (isExpense ? '\u{1F4B8}' : '\u{1F4B0}');
  }
}

/// Compact version of CategoryIcon for lists
class CategoryIconSmall extends StatelessWidget {
  final Category category;

  const CategoryIconSmall({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return CategoryIcon(
      category: category,
      size: 36,
      borderRadius: 8,
    );
  }
}

/// Large version of CategoryIcon for detail views
class CategoryIconLarge extends StatelessWidget {
  final Category category;

  const CategoryIconLarge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return CategoryIcon(
      category: category,
      size: 64,
      borderRadius: 16,
    );
  }
}
