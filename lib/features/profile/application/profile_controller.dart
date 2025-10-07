import 'package:flutter_riverpod/legacy.dart';
import '../data/profile_repository.dart';
import 'dart:io';

class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final int guestHouseCount;
  final int totalBookings;
  final int upcomingBookings;
  final int pastBookings;

  ProfileLoaded({
    this.guestHouseCount = 0,
    this.totalBookings = 0,
    this.upcomingBookings = 0,
    this.pastBookings = 0,
  });
}

class ProfileUpdated extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  ProfileController(this._repository) : super(ProfileLoading()) {
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _repository.session?.user;
      if (user == null) {
        state = ProfileError('No user logged in');
        return;
      }
      final isOwner = user.userMetadata?['role'] == 'guest_house_owner';
      if (isOwner) {
        final guestHouseCount = await _repository.getGuestHouseCount(user.id);
        state = ProfileLoaded(guestHouseCount: guestHouseCount);
      } else {
        state = ProfileLoaded();
      }
    } catch (e) {
      state = ProfileError('Failed to load profile data: $e');
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    File? avatarFile,
  }) async {
    try {
      state = ProfileLoading();
      await _repository.updateUserProfile(
        userId: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarFile: avatarFile,
      );
      state = ProfileUpdated();
      await _loadProfileData(); // Refresh data
    } catch (e) {
      state = ProfileError('Failed to update profile: $e');
    }
  }

  Future<void> sendPasswordResetEmail() async {
    try {
      await _repository.sendPasswordResetEmail();
    } catch (e) {
      state = ProfileError('Failed to send password reset email: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _repository.deleteAccount();
      state = ProfileUpdated();
    } catch (e) {
      state = ProfileError('Failed to delete account: $e');
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final repo = ref.watch(profileRepositoryProvider);
      return ProfileController(repo);
    });
