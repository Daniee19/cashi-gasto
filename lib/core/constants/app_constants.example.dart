/// Constantes generales de la aplicación
///
/// INSTRUCCIONES:
/// 1. Copia este archivo y renómbralo a 'app_constants.dart'
/// 2. Reemplaza los valores con tus credenciales reales
/// 3. NO subas app_constants.dart a git (ya está en .gitignore)
///
abstract final class AppConstants {
  // App Info
  static const String appName = 'Cashi Gasto';
  static const String appVersion = '1.0.0';

  // Supabase - Obtén estos valores de tu proyecto en supabase.com
  // Dashboard -> Settings -> API
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'tu-anon-key-aqui';

  // Limits
  static const int maxFreeChatMessages = 10;
  static const int maxFreePdfsPerDay = 3;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);
}
