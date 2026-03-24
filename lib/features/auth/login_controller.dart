import 'package:logbook_app_060/services/user_context_service.dart';

class LoginController {
  // Database sederhana (Hardcoded) untuk 2 tim x 2 user.
  // Semua password demo: 123
  final Map<String, String> _users = {
    "harifky": "123",
    "sasarai": "123",
    "ridhoputro": "123",
    "salmarifah": "123",
  };

  // Mapping user ke role untuk RBAC
  final Map<String, String> _userRoles = {
    "harifky": "Ketua",
    "sasarai": "Anggota",
    "ridhoputro": "Ketua",
    "salmarifah": "Anggota",
  };

  // Mapping user ke team
  final Map<String, String> _userTeams = {
    "harifky": "team_alpha",
    "sasarai": "team_alpha",
    "ridhoputro": "team_beta",
    "salmarifah": "team_beta",
  };

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  // Juga menyimpan user context saat login berhasil
  Future<bool> login(String username, String password) async {
    if (_users[username] == password) {
      // Simpan user context untuk RBAC
      await UserContextService.setUserContext(
        userId: username,
        username: username,
        role: _userRoles[username] ?? 'Anggota',
        teamId: _userTeams[username] ?? 'default_team',
      );
      return true;
    }
    return false;
  }

  // Fungsi logout
  Future<void> logout() async {
    await UserContextService.clearUserContext();
  }
}
