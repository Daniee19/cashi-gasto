import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para persistir la selección de fondo del usuario
class FundPreferencesService {
  static const String _selectedFundKey = 'selected_fund_id';

  /// Obtiene el ID del fondo seleccionado guardado localmente
  Future<String?> getSelectedFundId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedFundKey);
  }

  /// Guarda el ID del fondo seleccionado localmente
  Future<void> setSelectedFundId(String? fundId) async {
    final prefs = await SharedPreferences.getInstance();
    if (fundId == null) {
      await prefs.remove(_selectedFundKey);
    } else {
      await prefs.setString(_selectedFundKey, fundId);
    }
  }

  /// Limpia la selección de fondo guardada
  Future<void> clearSelectedFund() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedFundKey);
  }
}
