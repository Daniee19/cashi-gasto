import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Obtiene todas las categorías (default + del usuario)
  Future<List<Category>> getCategories() async {
    // Las categorías default tienen user_id = NULL
    // Las del usuario tienen su user_id
    try {
      final response = await _client
          .from('categories')
          .select()
          .or('user_id.is.null,user_id.eq.${_userId ?? ''}')
          .order('name');

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener categorias: $e');
      rethrow;
    }
  }

  /// Obtiene categorías filtradas por tipo
  /// Filtra en el cliente porque la columna 'type' puede no existir en algunas DBs
  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final allCategories = await getCategories();
    // Filtrar por tipo si la categoría tiene type definido
    return allCategories.where((c) => c.type == type).toList();
  }

  /// Crea una nueva categoría personalizada
  Future<Category> addCategory({
    required String name,
    required CategoryType type,
    String? description,
    String? icon,
    String? color,
  }) async {
    if (_userId == null) {
      print('ERROR: Usuario no autenticado');
      throw Exception('Usuario no autenticado');
    }

    final data = {
      'user_id': _userId,
      'name': name,
      'type': type.name,
      'description': description,
      'icon': icon,
      'color': color,
      'is_default': false,
    };

    print('DEBUG CategoryRepository: Insertando categoria con data=$data');

    try {
      final response = await _client
          .from('categories')
          .insert(data)
          .select()
          .single();

      print('DEBUG CategoryRepository: Categoria creada exitosamente');
      return Category.fromJson(response);
    } catch (e) {
      print('ERROR CategoryRepository: $e');
      rethrow;
    }
  }

  /// Elimina una categoría personalizada
  Future<void> deleteCategory(String id) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('categories')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }
}
