/// Configuracion de Supabase
/// Las credenciales se cargan desde .env (no commitear a git)
class SupabaseConfig {
  SupabaseConfig._();

  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String receiptsBucket = 'receipts';
}
