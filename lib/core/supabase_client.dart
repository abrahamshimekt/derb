import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  static Future<void> init(String url,String anonKey) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}


