/// Constantes generales de la aplicación
abstract final class AppConstants {
  // App Info
  static const String appName = 'Cashi Gasto';
  static const String appVersion = '1.0.0';

  // Supabase
  static const String supabaseUrl = 'https://jgcsdfsargxmlxrvuakn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnY3NkZnNhcmd4bWx4cnZ1YWtuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1OTg3NTksImV4cCI6MjA4OTE3NDc1OX0.ujJ5orzimIpTBxS13ZQI-OMQVjgvr_6KRfh8HutANJM';

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
