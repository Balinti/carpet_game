import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile.dart';

/// Where user profiles live. A Firestore implementation
/// (e.g. `users/{uid}` = profile.toJson()) can be added later.
abstract class ProfileStore {
  Future<void> save(UserProfile profile);

  /// Profile for [uid], or null if none was saved.
  Future<UserProfile?> load(String uid);
}

/// Device-local store (shared_preferences).
class LocalProfileStore implements ProfileStore {
  const LocalProfileStore();

  static String _key(String uid) => 'onboarding.profile.$uid';

  @override
  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(profile.uid), jsonEncode(profile.toJson()));
  }

  @override
  Future<UserProfile?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
