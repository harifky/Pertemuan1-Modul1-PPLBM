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
    // ✅ NORMALISASI INPUT: Hapus spasi di awal/akhir
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    // ✅ Gunakan variabel yang sudah dinormalisasi untuk lookup
    if (_users[normalizedUsername] == normalizedPassword) {
      await UserContextService.setUserContext(
        userId: normalizedUsername, // ✅ Simpan data bersih
        username: normalizedUsername,
        role: _userRoles[normalizedUsername] ?? 'Anggota',
        teamId: _userTeams[normalizedUsername] ?? 'default_team',
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
