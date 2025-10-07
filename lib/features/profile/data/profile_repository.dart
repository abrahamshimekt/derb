import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  Session? get session => _client.auth.currentSession;

  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    File? avatarFile,
  }) async {
    String? avatarUrl;
    if (avatarFile != null) {
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('avatars').upload(fileName, avatarFile);
      avatarUrl = _client.storage.from('avatars').getPublicUrl(fileName);
    }

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      ),
    );
  }

  Future<int> getGuestHouseCount(String ownerId) async {
    final response = await _client
        .from('guest_houses')
        .select()
        .eq('owner_id', ownerId)
        .count();
    return response.count;
  }

  Future<void> sendPasswordResetEmail() async {
    final email = _client.auth.currentUser?.email;
    if (email != null) {
      await _client.auth.resetPasswordForEmail(email);
    }
  }

  Future<void> deleteAccount() async {
    await _client.rpc(
      'delete_user',
      params: {'user_id': _client.auth.currentUser?.id},
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});
