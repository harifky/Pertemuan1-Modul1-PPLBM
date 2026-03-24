import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan dan mengambil informasi user yang sedang login
/// Digunakan untuk RBAC dan ownership validation
class UserContextService {
  static const String _keyUserId = 'current_user_id';
  static const String _keyUsername = 'current_username';
  static const String _keyUserRole = 'current_user_role';
  static const String _keyTeamId = 'current_team_id';

  /// Menyimpan informasi user saat login
  static Future<void> setUserContext({
    required String userId,
    required String username,
    required String role,
    String teamId = 'default_team',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyTeamId, teamId);
  }

  /// Mengambil User ID yang sedang login
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) ?? 'unknown_user';
  }

  /// Mengambil Username yang sedang login
  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? 'guest';
  }

  /// Mengambil Role user yang sedang login
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'Anggota';
  }

  /// Mengambil Team ID user yang sedang login
  static Future<String> getTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTeamId) ?? 'default_team';
  }

  /// Menghapus semua informasi user (logout)
  static Future<void> clearUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyTeamId);
  }

  /// Helper untuk mengecek apakah user adalah owner dari sebuah data
  static Future<bool> isOwner(String authorId) async {
    final currentUserId = await getUserId();
    return currentUserId == authorId;
  }
}
